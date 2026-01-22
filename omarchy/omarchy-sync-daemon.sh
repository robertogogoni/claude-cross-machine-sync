#!/bin/bash
# Omarchy Auto-Sync Daemon
# Watches for changes in ~/.config/ and auto-syncs to/from repo
#
# Usage:
#   ./omarchy-sync-daemon.sh          # Run in foreground
#   ./omarchy-sync-daemon.sh --bg     # Run in background
#   ./omarchy-sync-daemon.sh --stop   # Stop background daemon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.config"
HOSTNAME=$(hostname)
PID_FILE="/tmp/omarchy-sync-daemon.pid"
LOG_FILE="$HOME/.local/state/omarchy-sync.log"
DEBOUNCE_SECONDS=3

# Colors (for terminal output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories to watch
WATCH_DIRS=(
    "$CONFIG_DIR/hypr"
    "$CONFIG_DIR/waybar"
    "$CONFIG_DIR/alacritty"
    "$CONFIG_DIR/kitty"
    "$CONFIG_DIR/ghostty"
    "$CONFIG_DIR/walker"
    "$CONFIG_DIR/mako"
)

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

# Sync system changes to repo
sync_system_to_repo() {
    log "Syncing system → repo..."

    cd "$SCRIPT_DIR"
    ./sync-to-repo.sh --commit --push 2>&1 | while read line; do
        log "  $line"
    done

    log "Sync complete"
}

# Pull repo changes and deploy
sync_repo_to_system() {
    log "Checking for repo updates..."

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
    fi
}

# Main watch loop
watch_loop() {
    log "Starting omarchy sync daemon for $HOSTNAME"
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
        exit 1
    fi

    local last_sync=0

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

            # Wait a moment for any batch changes to complete
            sleep 1

            # Sync to repo
            sync_system_to_repo
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
            echo "  - Watches ~/.config/hypr, waybar, terminals for changes"
            echo "  - Auto-syncs changes to git repo with categorization"
            echo "  - Periodically checks for repo updates from other machines"
            echo "  - Auto-deploys incoming changes"
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
