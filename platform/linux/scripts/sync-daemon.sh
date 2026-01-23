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

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOSTNAME=$(hostname)
LOG_FILE="$HOME/.local/state/machine-sync/sync.log"
PID_FILE="$HOME/.local/state/machine-sync/daemon.pid"
LOCK_FILE="$HOME/.local/state/machine-sync/daemon.lock"
DEBOUNCE_SECONDS=3
PULL_INTERVAL=300  # 5 minutes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")"

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

# Dependencies check
check_deps() {
    local missing=()
    command -v inotifywait &>/dev/null || missing+=("inotify-tools")
    command -v git &>/dev/null || missing+=("git")

    if [ ${#missing[@]} -gt 0 ]; then
        log "Missing dependencies: ${missing[*]}" "ERROR"
        log "Install with: sudo pacman -S ${missing[*]}"
        exit 1
    fi
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

    git commit -m "${scope} Auto-sync from $HOSTNAME

Changed files:
$(echo "$files" | sed 's/^/- /')

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" 2>&1 || true

    log "Committed: $scope ($file_count files)"

    if [ "$push" = "true" ]; then
        if git push 2>&1; then
            log "Pushed to remote"
        else
            log "Push failed" "WARN"
        fi
    fi
}

# Git pull
git_pull() {
    cd "$REPO_DIR"

    git fetch origin 2>/dev/null

    local local_head remote_head
    local_head=$(git rev-parse HEAD)
    remote_head=$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null)

    if [ "$local_head" != "$remote_head" ]; then
        log "Pulling changes from remote..."
        if git pull --rebase 2>&1; then
            log "Pull successful"
            return 0
        else
            log "Pull failed" "WARN"
        fi
    fi
    return 1
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
    --help|-h)
        echo "Machine Sync Daemon"
        echo ""
        echo "Usage:"
        echo "  $0              Run in foreground"
        echo "  $0 --bg         Run in background"
        echo "  $0 --stop       Stop daemon"
        echo "  $0 --status     Check status"
        echo "  $0 --install    Install systemd service"
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
