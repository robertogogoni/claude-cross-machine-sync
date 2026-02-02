#!/bin/bash
# Machine Sync Daemon for Linux
# Watches for file changes and auto-syncs to git
#
# Usage:
#   ./sync-daemon.sh              Run in foreground
#   ./sync-daemon.sh --bg         Run in background
#   ./sync-daemon.sh --stop       Stop daemon
#   ./sync-daemon.sh --status     Check status
#   ./sync-daemon.sh --install    Install systemd service
#   ./sync-daemon.sh --flush-queue Flush offline commit queue
#   ./sync-daemon.sh --dry-run    Preview changes without executing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOSTNAME=$(hostname)
LOG_FILE="$HOME/.local/state/machine-sync/sync.log"
PID_FILE="$HOME/.local/state/machine-sync/daemon.pid"
LOCK_FILE="$HOME/.local/state/machine-sync/daemon.lock"
OFFLINE_QUEUE_DIR="$HOME/.local/state/machine-sync/offline-queue"
DEBOUNCE_SECONDS=3
PULL_INTERVAL=300  # 5 minutes

# Retry configuration
RETRY_COUNT=3
RETRY_DELAYS=(5 15 60)  # Exponential backoff in seconds

# Colors (export for lib scripts)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Mode flags
DRY_RUN=false
SKIP_PREFLIGHT=false

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$OFFLINE_QUEUE_DIR"

# Source library modules
LIB_DIR="$REPO_DIR/lib"
if [[ -f "$LIB_DIR/validator.sh" ]]; then
    source "$LIB_DIR/validator.sh"
fi

# Logging
log() {
    local level="${2:-INFO}"
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $1"
    echo "$msg" >> "$LOG_FILE"
    if [ -t 1 ]; then
        case "$level" in
            ERROR) echo -e "${RED}$msg${NC}" ;;
            WARN)  echo -e "${YELLOW}$msg${NC}" ;;
            *)     echo -e "${CYAN}$msg${NC}" ;;
        esac
    fi
}

# Dependencies check (now uses validator if available)
check_deps() {
    if [[ "$SKIP_PREFLIGHT" == "true" ]]; then
        log "Skipping pre-flight validation"
        return 0
    fi

    if type -t validate_quick &>/dev/null; then
        if ! validate_quick "$REPO_DIR"; then
            log "Quick validation failed" "ERROR"
            exit 1
        fi
        return 0
    fi

    # Fallback to basic check
    local missing=()
    command -v inotifywait &>/dev/null || missing+=("inotify-tools")
    command -v git &>/dev/null || missing+=("git")

    if [ ${#missing[@]} -gt 0 ]; then
        log "Missing dependencies: ${missing[*]}" "ERROR"
        log "Install with: sudo pacman -S ${missing[*]}"
        exit 1
    fi
}

#######################################
# Check network connectivity
#######################################
is_online() {
    timeout 3 bash -c "echo >/dev/tcp/github.com/443" 2>/dev/null
}

#######################################
# Queue a commit for later (offline mode)
# Arguments:
#   $1 - Commit message
#   $2 - Files (newline separated)
#######################################
queue_offline_commit() {
    local message="$1"
    local files="$2"
    local queue_file="$OFFLINE_QUEUE_DIR/$(date +%Y%m%d-%H%M%S).commit"

    cat > "$queue_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$HOSTNAME",
    "message": $(echo "$message" | jq -Rs .),
    "files": $(echo "$files" | jq -Rs .)
}
EOF

    log "Queued commit for later: $queue_file" "WARN"
}

#######################################
# Flush offline commit queue
#######################################
flush_offline_queue() {
    local queue_files
    queue_files=$(find "$OFFLINE_QUEUE_DIR" -name "*.commit" -type f 2>/dev/null | sort)

    if [[ -z "$queue_files" ]]; then
        log "No queued commits to flush"
        return 0
    fi

    if ! is_online; then
        log "Still offline, cannot flush queue" "WARN"
        return 1
    fi

    log "Flushing offline queue..."

    cd "$REPO_DIR"
    local flushed=0

    for queue_file in $queue_files; do
        log "Processing: $(basename "$queue_file")"

        # The changes should already be committed locally
        # We just need to push
        if git_push_with_retry; then
            rm -f "$queue_file"
            ((flushed++))
        else
            log "Could not flush $queue_file, will retry later" "WARN"
            break
        fi
    done

    log "Flushed $flushed queued commit(s)"
}

#######################################
# Git push with exponential backoff retry
#######################################
git_push_with_retry() {
    local attempt=1

    while [ $attempt -le $RETRY_COUNT ]; do
        if git push 2>&1; then
            return 0
        fi

        if [ $attempt -lt $RETRY_COUNT ]; then
            local delay=${RETRY_DELAYS[$attempt-1]:-60}
            log "Push failed, retrying in ${delay}s (attempt $attempt/$RETRY_COUNT)" "WARN"
            sleep "$delay"
        fi

        ((attempt++))
    done

    log "Push failed after $RETRY_COUNT attempts" "ERROR"
    return 1
}

# Categorization logic
get_commit_scope() {
    local files="$1"
    local scopes=""

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        if [[ "$file" =~ ^machines/([^/]+)/ ]]; then
            scopes+="[machine:${BASH_REMATCH[1]}]"
        elif [[ "$file" =~ ^platform/windows/ ]]; then
            scopes+="[windows]"
        elif [[ "$file" =~ ^platform/linux/ ]]; then
            scopes+="[linux]"
        elif [[ "$file" =~ ^universal/ ]]; then
            scopes+="[universal]"
        elif [[ "$file" =~ \.ps1$|powershell|windows ]]; then
            scopes+="[windows]"
        elif [[ "$file" =~ \.sh$|bash|linux|hypr ]]; then
            scopes+="[linux]"
        else
            scopes+="[universal]"
        fi
    done <<< "$files"

    # Deduplicate
    echo "$scopes" | grep -oP '\[[^\]]+\]' | sort -u | tr -d '\n'
}

# Git sync
git_sync() {
    local push="${1:-false}"

    cd "$REPO_DIR"

    # Check for changes
    local status
    status=$(git status --porcelain 2>&1)
    if [ -z "$status" ]; then
        log "No changes to sync"
        return
    fi

    # Get changed files
    local files
    files=$(git status --porcelain | sed 's/^...//')

    # Determine scope
    local scope
    scope=$(get_commit_scope "$files")

    # Stage and commit
    git add -A

    local file_count
    file_count=$(echo "$files" | wc -l)

    local commit_msg="${scope} Auto-sync from $HOSTNAME

Changed files:
$(echo "$files" | sed 's/^/- /')

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

    git commit -m "$commit_msg" 2>&1 || true

    log "Committed: $scope ($file_count files)"

    if [ "$push" = "true" ]; then
        if ! is_online; then
            log "Offline - queuing commit for later" "WARN"
            queue_offline_commit "$commit_msg" "$files"
            return
        fi

        if git_push_with_retry; then
            log "Pushed to remote"
            # Flush any queued commits while we're online
            flush_offline_queue 2>/dev/null || true
        else
            log "Push failed after retries - queuing for later" "WARN"
            queue_offline_commit "$commit_msg" "$files"
        fi
    fi
}

# Git pull with conflict resolution
git_pull() {
    cd "$REPO_DIR"

    if ! is_online; then
        log "Offline - skipping pull"
        return 1
    fi

    git fetch origin 2>/dev/null || return 1

    local local_head remote_head branch
    local_head=$(git rev-parse HEAD)
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
    remote_head=$(git rev-parse "origin/$branch" 2>/dev/null || return 1)

    if [ "$local_head" = "$remote_head" ]; then
        return 1  # No changes
    fi

    log "Pulling changes from remote..."

    # Try normal rebase first
    if git pull --rebase 2>&1; then
        log "Pull successful"
        return 0
    fi

    log "Pull failed, attempting conflict resolution..." "WARN"

    # Check if we're in a conflicted state
    if git diff --name-only --diff-filter=U | grep -q .; then
        resolve_conflicts
        return $?
    else
        # Pull failed for other reasons
        log "Pull failed (not a conflict)" "ERROR"
        return 1
    fi
}

#######################################
# Resolve merge conflicts using tiered strategy
# Tier 1: Auto-resolve (ours for machine-specific, theirs for universal)
# Tier 2: Stash and retry
# Tier 3: Create conflict branch
#######################################
resolve_conflicts() {
    local conflicted_files
    conflicted_files=$(git diff --name-only --diff-filter=U)

    log "Resolving conflicts in: $(echo "$conflicted_files" | wc -l) file(s)"

    local auto_resolved=0
    local manual_required=0

    for file in $conflicted_files; do
        if [[ "$file" =~ ^machines/$HOSTNAME/ ]] || [[ "$file" =~ ^machines/$(echo "$HOSTNAME" | tr '[:upper:]' '[:lower:]')/ ]]; then
            # Machine-specific: keep ours
            git checkout --ours "$file" 2>/dev/null && git add "$file"
            log "  Auto-resolved (ours): $file"
            ((auto_resolved++))
        elif [[ "$file" =~ ^universal/ ]]; then
            # Universal: accept theirs
            git checkout --theirs "$file" 2>/dev/null && git add "$file"
            log "  Auto-resolved (theirs): $file"
            ((auto_resolved++))
        else
            # Unknown: need manual resolution
            ((manual_required++))
        fi
    done

    if [ $manual_required -eq 0 ]; then
        # All conflicts auto-resolved, continue rebase
        git rebase --continue 2>/dev/null || git commit --no-edit 2>/dev/null || true
        log "All conflicts auto-resolved ($auto_resolved files)"
        return 0
    fi

    # Tier 2: Stash local changes and try again
    log "Manual conflicts remain, trying stash strategy..." "WARN"
    git rebase --abort 2>/dev/null || true

    local stash_result
    stash_result=$(git stash push -m "machine-sync-conflict-$(date +%s)" 2>&1)

    if echo "$stash_result" | grep -q "No local changes"; then
        # Nothing to stash, create conflict branch
        create_conflict_branch
        return 1
    fi

    # Try pull again
    if git pull --rebase 2>&1; then
        # Apply stash
        if git stash pop 2>&1; then
            log "Stash strategy successful"
            return 0
        else
            log "Stash pop failed, conflicts in stash" "WARN"
            # Restore stash for manual handling
            git checkout --theirs . 2>/dev/null || true
            git stash drop 2>/dev/null || true
        fi
    fi

    # Tier 3: Create conflict branch
    create_conflict_branch
    return 1
}

#######################################
# Create a conflict branch for manual resolution
#######################################
create_conflict_branch() {
    local branch="conflict-$HOSTNAME-$(date +%Y%m%d-%H%M%S)"

    log "Creating conflict branch: $branch" "WARN"

    git rebase --abort 2>/dev/null || true
    git checkout -b "$branch" 2>/dev/null || true

    log "MANUAL ACTION REQUIRED:" "ERROR"
    log "  1. Review conflicts in branch: $branch"
    log "  2. Resolve and commit"
    log "  3. Merge back or delete branch"
    log "  4. Restart sync daemon"

    # Write conflict notification file
    local notify_file="$HOME/.local/state/machine-sync/conflict-pending"
    echo "$branch" > "$notify_file"
}

# Watch directories
get_watch_dirs() {
    local dirs=()
    dirs+=("$REPO_DIR/machines")
    dirs+=("$REPO_DIR/platform")
    dirs+=("$REPO_DIR/universal")
    dirs+=("$REPO_DIR/docs")
    dirs+=("$REPO_DIR/learnings")

    # Only return existing directories
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] && echo "$dir"
    done
}

# Main watch loop
watch_loop() {
    log "Machine Sync Daemon starting on $HOSTNAME"

    # Check for existing instance
    if [ -f "$LOCK_FILE" ]; then
        local existing_pid
        existing_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$existing_pid" 2>/dev/null; then
            log "Daemon already running (PID: $existing_pid)" "WARN"
            exit 1
        fi
    fi

    # Create lock file
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"; exit' EXIT INT TERM

    # Initial pull
    git_pull || true

    # Build watch list
    local watch_dirs
    watch_dirs=$(get_watch_dirs)

    if [ -z "$watch_dirs" ]; then
        log "No directories to watch!" "ERROR"
        exit 1
    fi

    log "Watching directories:"
    echo "$watch_dirs" | while read -r dir; do
        log "  - $dir"
    done

    # Start periodic pull in background
    (
        while true; do
            sleep $PULL_INTERVAL
            git_pull && log "Pulled updates, deploying..." || true
        done
    ) &
    local pull_pid=$!
    trap "kill $pull_pid 2>/dev/null; rm -f '$LOCK_FILE'; exit" EXIT INT TERM

    local last_sync=0

    # Watch for changes
    echo "$watch_dirs" | xargs inotifywait -m -r \
        -e modify,create,delete,move \
        --exclude '\.git|\.swp|~$|\.lock' \
        2>/dev/null | while read -r directory event filename; do

        # Skip temporary files
        [[ "$filename" == *.swp ]] && continue
        [[ "$filename" == *~ ]] && continue
        [[ "$filename" == .git* ]] && continue

        local now
        now=$(date +%s)

        # Debounce
        if (( now - last_sync >= DEBOUNCE_SECONDS )); then
            log "Change detected: $event - $directory$filename"
            last_sync=$now

            # Wait for batch changes
            sleep 1

            # Sync
            git_sync true
        fi
    done
}

# Daemon control
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping daemon (PID: $pid)..."
            kill "$pid"
            rm -f "$PID_FILE" "$LOCK_FILE"
            log "Daemon stopped"
        else
            log "PID file exists but process not running" "WARN"
            rm -f "$PID_FILE" "$LOCK_FILE"
        fi
    else
        log "No daemon running"
    fi
}

show_status() {
    echo -e "${CYAN}Machine Sync Daemon Status${NC}"
    echo "========================="

    # Check systemd service
    if systemctl --user is-active machine-sync.service &>/dev/null; then
        echo -e "Service: ${GREEN}Running${NC}"
    else
        echo -e "Service: ${YELLOW}Not running${NC}"
    fi

    # Check lock file
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "Daemon: ${GREEN}Running (PID: $pid)${NC}"
        else
            echo -e "Daemon: ${YELLOW}Stale lock file${NC}"
        fi
    else
        echo -e "Daemon: ${YELLOW}Not running${NC}"
    fi

    # Recent logs
    echo ""
    echo -e "${CYAN}Recent log entries:${NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -10 "$LOG_FILE"
    else
        echo "No logs yet"
    fi
}

install_systemd() {
    local service_dir="$HOME/.config/systemd/user"
    mkdir -p "$service_dir"

    # Service file
    cat > "$service_dir/machine-sync.service" << EOF
[Unit]
Description=Machine Sync Daemon
After=network-online.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/sync-daemon.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    # Timer file
    cat > "$service_dir/machine-sync.timer" << EOF
[Unit]
Description=Machine Sync Timer (pull every 5 min)

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable machine-sync.service
    systemctl --user start machine-sync.service

    echo -e "${GREEN}Systemd service installed and started${NC}"
    echo "Check status: systemctl --user status machine-sync"
}

# Main
case "${1:-}" in
    --stop|-s)
        stop_daemon
        ;;
    --status)
        show_status
        # Also show queue status
        queue_count=$(find "$OFFLINE_QUEUE_DIR" -name "*.commit" -type f 2>/dev/null | wc -l)
        if [ "$queue_count" -gt 0 ]; then
            echo -e "\n${YELLOW}Offline queue: $queue_count pending commit(s)${NC}"
        fi
        # Check for pending conflicts
        if [ -f "$HOME/.local/state/machine-sync/conflict-pending" ]; then
            conflict_branch=$(cat "$HOME/.local/state/machine-sync/conflict-pending")
            echo -e "\n${RED}CONFLICT PENDING: Branch $conflict_branch needs manual resolution${NC}"
        fi
        ;;
    --install)
        check_deps
        install_systemd
        ;;
    --bg|--background)
        check_deps
        stop_daemon
        log "Starting daemon in background..."
        nohup "$0" >> "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo -e "${GREEN}Daemon started (PID: $(cat "$PID_FILE"))${NC}"
        echo -e "${CYAN}Log file: $LOG_FILE${NC}"
        ;;
    --flush-queue)
        flush_offline_queue
        ;;
    --dry-run)
        DRY_RUN=true
        echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
        check_deps
        echo ""
        echo "Would watch directories:"
        get_watch_dirs | while read -r dir; do
            echo "  - $dir"
        done
        echo ""
        echo "Configuration:"
        echo "  Debounce: ${DEBOUNCE_SECONDS}s"
        echo "  Pull interval: ${PULL_INTERVAL}s"
        echo "  Retry count: $RETRY_COUNT"
        echo "  Retry delays: ${RETRY_DELAYS[*]}s"
        ;;
    --skip-preflight)
        SKIP_PREFLIGHT=true
        shift
        # Re-run with remaining args
        exec "$0" "$@"
        ;;
    --help|-h)
        echo "Machine Sync Daemon"
        echo ""
        echo "Usage:"
        echo "  $0              Run in foreground"
        echo "  $0 --bg         Run in background"
        echo "  $0 --stop       Stop daemon"
        echo "  $0 --status     Check status"
        echo "  $0 --install    Install systemd service"
        echo "  $0 --flush-queue Flush offline commit queue"
        echo "  $0 --dry-run    Preview configuration"
        echo "  $0 --skip-preflight  Skip validation checks"
        ;;
    "")
        check_deps
        watch_loop
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage"
        exit 1
        ;;
esac
