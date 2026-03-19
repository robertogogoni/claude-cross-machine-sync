#!/bin/bash
# Omarchy Auto-Sync Daemon
# Watches for changes in ~/.config/ and Claude Code knowledge, auto-syncs to/from repo
#
# Usage:
#   ./omarchy-sync-daemon.sh          # Run in foreground
#   ./omarchy-sync-daemon.sh --bg     # Run in background
#   ./omarchy-sync-daemon.sh --stop   # Stop background daemon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.config"
CLAUDE_DIR="$HOME/.claude"
HOSTNAME=$(hostname)
PID_FILE="/tmp/omarchy-sync-daemon.pid"
LOG_FILE="$HOME/.local/state/omarchy-sync.log"
STATUS_FILE="$HOME/.local/state/omarchy-sync-status.json"
DEBOUNCE_SECONDS=3

# Colors (for terminal output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Desktop config directories
DESKTOP_WATCH_DIRS=(
    "$CONFIG_DIR/hypr"
    "$CONFIG_DIR/waybar"
    "$CONFIG_DIR/alacritty"
    "$CONFIG_DIR/kitty"
    "$CONFIG_DIR/ghostty"
    "$CONFIG_DIR/walker"
    "$CONFIG_DIR/mako"
)

# Claude Code knowledge directories
CLAUDE_WATCH_DIRS=(
    "$CLAUDE_DIR/agents"
    "$CLAUDE_DIR/commands"
    "$CLAUDE_DIR/skills"
)

# Claude memory directories (project-scoped)
CLAUDE_MEMORY_DIRS=()
for proj_dir in "$CLAUDE_DIR"/projects/*/memory; do
    [ -d "$proj_dir" ] && CLAUDE_MEMORY_DIRS+=("$proj_dir")
done

# Combined watch list
WATCH_DIRS=("${DESKTOP_WATCH_DIRS[@]}" "${CLAUDE_WATCH_DIRS[@]}" "${CLAUDE_MEMORY_DIRS[@]}")

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
    if [ -t 1 ]; then  # If running in terminal
        echo -e "${GREEN}$msg${NC}"
    fi
}

log_warn() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo "$msg" >> "$LOG_FILE"
    if [ -t 1 ]; then
        echo -e "${YELLOW}$msg${NC}"
    fi
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo "$msg" >> "$LOG_FILE"
    if [ -t 1 ]; then
        echo -e "${RED}$msg${NC}" >&2
    fi
}

# Check for inotifywait
check_dependencies() {
    if ! command -v inotifywait &> /dev/null; then
        log_error "inotifywait not found. Install with: sudo pacman -S inotify-tools"
        exit 1
    fi
    if ! command -v git &> /dev/null; then
        log_error "git not found"
        exit 1
    fi
}

# Stop existing daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping daemon (PID: $pid)..."
            kill "$pid"
            rm -f "$PID_FILE"
            log "Daemon stopped"
        else
            log_warn "PID file exists but process not running"
            rm -f "$PID_FILE"
        fi
    else
        log "No daemon running"
    fi
}

# Determine sync category from changed path
get_sync_category() {
    local path="$1"
    case "$path" in
        */.claude/projects/*/memory/*)  echo "claude-memory" ;;
        */.claude/agents/*)             echo "claude-agents" ;;
        */.claude/commands/*)           echo "claude-commands" ;;
        */.claude/skills/*)             echo "claude-skills" ;;
        */.config/*)                    echo "desktop-config" ;;
        *)                              echo "unknown" ;;
    esac
}

# Sync Claude Code knowledge to repo
sync_claude_to_repo() {
    local category="$1"
    local changed_dir="$2"
    local machine_dir="$REPO_DIR/machines/$(resolve_machine_name)/memory"
    local universal_dir="$REPO_DIR/universal/claude"
    local changed=false

    case "$category" in
        claude-memory)
            # Memory files go to machine-specific directory
            mkdir -p "$machine_dir"
            for f in "$CLAUDE_DIR"/projects/*/memory/*.md; do
                [ -f "$f" ] || continue
                local basename=$(basename "$f")
                [ "$basename" = "MEMORY.md" ] && continue  # Skip index
                if ! diff -q "$f" "$machine_dir/$basename" &>/dev/null 2>&1; then
                    cp "$f" "$machine_dir/$basename"
                    changed=true
                    log "  Memory synced: $basename"
                fi
            done
            # Also sync MEMORY.md index
            for idx in "$CLAUDE_DIR"/projects/*/memory/MEMORY.md; do
                [ -f "$idx" ] || continue
                if ! diff -q "$idx" "$machine_dir/MEMORY.md" &>/dev/null 2>&1; then
                    cp "$idx" "$machine_dir/MEMORY.md"
                    changed=true
                    log "  Memory index synced"
                fi
            done
            ;;
        claude-agents|claude-commands|claude-skills)
            # Agents/commands/skills go to universal
            local src_type="${category#claude-}"
            local src_dir="$CLAUDE_DIR/$src_type"
            local dst_dir="$universal_dir/$src_type"
            mkdir -p "$dst_dir"
            for f in "$src_dir"/*.md "$src_dir"/*/SKILL.md; do
                [ -f "$f" ] || continue
                local relpath="${f#$src_dir/}"
                mkdir -p "$dst_dir/$(dirname "$relpath")"
                if ! diff -q "$f" "$dst_dir/$relpath" &>/dev/null 2>&1; then
                    cp "$f" "$dst_dir/$relpath"
                    changed=true
                    log "  $src_type synced: $relpath"
                fi
            done
            ;;
    esac

    echo "$changed"
}

# Resolve machine name from registry
resolve_machine_name() {
    local reg="$REPO_DIR/machines/registry.yaml"
    if [ -f "$reg" ]; then
        local current_machine="" found=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+):$ ]]; then
                current_machine="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ hostname:[[:space:]]*(.+) ]]; then
                local reg_hostname="${BASH_REMATCH[1]}"
                if [[ "$reg_hostname" == "$HOSTNAME" ]] || [[ "$reg_hostname" == "${HOSTNAME%%.*}" ]]; then
                    found="$current_machine"; break
                fi
            fi
        done < "$reg"
        [ -n "$found" ] && echo "$found" && return
    fi
    echo "$HOSTNAME"
}

# Write status file for tray applet + signal waybar
write_status() {
    local event="$1"
    local detail="$2"
    local status="${3:-ok}"
    mkdir -p "$(dirname "$STATUS_FILE")"
    cat > "$STATUS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "event": "$event",
  "detail": "$detail",
  "status": "$status",
  "hostname": "$HOSTNAME",
  "machine": "$(resolve_machine_name)",
  "pid": $$
}
EOF
    # Signal waybar to refresh sync-status module instantly
    pkill -RTMIN+11 waybar 2>/dev/null || true
}

# Sync system changes to repo
sync_system_to_repo() {
    local trigger_dir="${1:-}"
    local category=$(get_sync_category "$trigger_dir")
    local claude_changed=false

    # Sync Claude knowledge if triggered by Claude directories
    if [[ "$category" == claude-* ]]; then
        log "Syncing Claude $category → repo..."
        claude_changed=$(sync_claude_to_repo "$category" "$trigger_dir")
    fi

    # Sync desktop configs via existing omarchy sync script
    if [[ "$category" == "desktop-config" ]] || [[ -z "$trigger_dir" ]]; then
        log "Syncing desktop config → repo..."
        cd "$SCRIPT_DIR"
        ./sync-to-repo.sh --commit --push 2>&1 | while read line; do
            log "  $line"
        done
    fi

    # Commit Claude changes if any
    if [[ "$claude_changed" == "true" ]]; then
        cd "$REPO_DIR"
        git add machines/*/memory/ universal/claude/ 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            local msg="[auto-sync] Claude knowledge from $HOSTNAME ($(resolve_machine_name))"
            git commit -m "$msg" 2>&1 | while read line; do log "  $line"; done
            git push origin master 2>&1 | while read line; do log "  $line"; done
            log "Claude knowledge pushed"
            write_status "sync" "$category" "ok"
        fi
    fi

    log "Sync complete"
    write_status "idle" "watching" "ok"
}

# Pull repo changes and deploy
sync_repo_to_system() {
    log "Checking for repo updates..."
    write_status "checking" "pulling from remote" "ok"

    cd "$REPO_DIR"

    # Fetch and check for changes
    git fetch origin 2>/dev/null

    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null)

    if [ "$LOCAL" != "$REMOTE" ]; then
        log "New changes detected, pulling..."
        git pull --rebase 2>&1 | while read line; do
            log "  $line"
        done

        log "Deploying changes..."
        cd "$SCRIPT_DIR"
        ./deploy.sh 2>&1 | while read line; do
            log "  $line"
        done

        # Reload Hyprland if running
        if pgrep -x Hyprland > /dev/null; then
            log "Reloading Hyprland..."
            hyprctl reload 2>/dev/null || true
        fi

        log "Deploy complete"
        write_status "deployed" "changes from remote" "ok"
    else
        write_status "idle" "watching" "ok"
    fi
}

# Main watch loop
watch_loop() {
    log "Starting omarchy sync daemon for $HOSTNAME"
    write_status "started" "initializing" "ok"
    log "Watching directories:"
    for dir in "${WATCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            log "  - $dir"
        fi
    done

    # Build watch directory list (only existing dirs)
    local watch_args=()
    for dir in "${WATCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            watch_args+=("$dir")
        fi
    done

    if [ ${#watch_args[@]} -eq 0 ]; then
        log_error "No directories to watch!"
        write_status "error" "no directories to watch" "error"
        exit 1
    fi

    local last_sync=0
    write_status "idle" "watching ${#watch_args[@]} dirs" "ok"

    # Watch for file changes
    inotifywait -m -r -e modify,create,delete,move \
        --exclude '\.backup\.' \
        --exclude '\.bak' \
        --exclude '\.swp' \
        --exclude '~$' \
        "${watch_args[@]}" 2>/dev/null | while read -r directory event filename; do

        # Skip temporary/backup files
        if [[ "$filename" == *.backup.* ]] || [[ "$filename" == *.bak* ]] || [[ "$filename" == *~ ]]; then
            continue
        fi

        local now=$(date +%s)

        # Debounce: only sync if enough time has passed
        if (( now - last_sync >= DEBOUNCE_SECONDS )); then
            log "Change detected: $directory$filename ($event)"
            last_sync=$now
            write_status "change" "$directory$filename" "syncing"

            # Wait a moment for any batch changes to complete
            sleep 1

            # Sync to repo (pass the trigger directory for categorization)
            sync_system_to_repo "$directory"
        fi
    done
}

# Periodic repo check (for changes from other machines)
repo_check_loop() {
    while true; do
        sleep 300  # Check every 5 minutes
        sync_repo_to_system
    done
}

# Main
main() {
    case "${1:-}" in
        --stop|-s)
            stop_daemon
            exit 0
            ;;
        --bg|--background|-b)
            check_dependencies
            stop_daemon  # Stop any existing instance

            log "Starting daemon in background..."
            nohup "$0" >> "$LOG_FILE" 2>&1 &
            echo $! > "$PID_FILE"
            echo -e "${GREEN}Daemon started (PID: $(cat "$PID_FILE"))${NC}"
            echo -e "${BLUE}Log file: $LOG_FILE${NC}"
            echo -e "${YELLOW}Stop with: $0 --stop${NC}"
            exit 0
            ;;
        --status)
            if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
                echo -e "${GREEN}Daemon running (PID: $(cat "$PID_FILE"))${NC}"
                echo -e "${BLUE}Log file: $LOG_FILE${NC}"
                echo -e "${YELLOW}Last 10 log entries:${NC}"
                tail -10 "$LOG_FILE" 2>/dev/null || echo "No logs yet"
            else
                echo -e "${YELLOW}Daemon not running${NC}"
            fi
            exit 0
            ;;
        --help|-h)
            echo "Omarchy Auto-Sync Daemon"
            echo ""
            echo "Usage:"
            echo "  $0              Run in foreground"
            echo "  $0 --bg         Run in background"
            echo "  $0 --stop       Stop background daemon"
            echo "  $0 --status     Check daemon status"
            echo ""
            echo "What it does:"
            echo "  - Watches ~/.config/hypr, waybar, terminals for desktop changes"
            echo "  - Watches ~/.claude/ for memory, agents, commands, skills changes"
            echo "  - Auto-syncs everything to git repo with smart categorization"
            echo "  - Periodically checks for repo updates from other machines"
            echo "  - Auto-deploys incoming changes"
            echo "  - Writes status to $STATUS_FILE for tray applet"
            exit 0
            ;;
        "")
            # Run in foreground
            check_dependencies

            # Start repo check in background
            repo_check_loop &
            REPO_CHECK_PID=$!
            trap "kill $REPO_CHECK_PID 2>/dev/null; exit" EXIT INT TERM

            # Initial sync
            sync_repo_to_system
            write_status "started" "watching ${#WATCH_DIRS[@]} directories" "ok"

            # Start watching
            watch_loop
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
