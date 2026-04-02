#!/bin/bash
# Claude Cross-Machine Sync — One-line Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/install.sh | bash
#
# What it does:
#   1. Checks prerequisites (git, jq, inotifywait)
#   2. Clones the repo to ~/claude-cross-machine-sync
#   3. Generates machine-info.json for this machine
#   4. Runs bootstrap.sh (registers machine, installs daemon)
#   5. Starts the sync daemon

set -euo pipefail

REPO="robertogogoni/claude-cross-machine-sync"
CLONE_DIR="$HOME/claude-cross-machine-sync"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()    { echo -e "\n${CYAN}[>]${NC} ${BOLD}$1${NC}"; }
success() { echo -e "    ${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "    ${YELLOW}[!]${NC} $1"; }
fail()    { echo -e "    ${RED}[X]${NC} $1"; exit 1; }

echo ""
echo -e "${BOLD}${CYAN}Claude Cross-Machine Sync${NC} ${BOLD}Installer${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Prerequisites ────────────────────────────────────────────────────────────

step "Checking prerequisites..."

for cmd in git jq curl; do
    if command -v "$cmd" &>/dev/null; then
        success "$cmd found"
    else
        fail "$cmd is required but not installed"
    fi
done

# Optional: inotifywait (needed for file watching daemon)
if command -v inotifywait &>/dev/null; then
    success "inotifywait found (live sync enabled)"
else
    warn "inotifywait not found (install inotify-tools for live sync)"
    warn "  Arch: sudo pacman -S inotify-tools"
    warn "  Debian/Ubuntu: sudo apt install inotify-tools"
fi

# Optional: Claude Code
if command -v claude &>/dev/null; then
    success "Claude Code found ($(claude --version 2>/dev/null | head -1))"
else
    warn "Claude Code not found (install from https://claude.ai/code)"
fi

# ── Clone or update ──────────────────────────────────────────────────────────

step "Setting up repository..."

if [ -d "$CLONE_DIR/.git" ]; then
    success "Repository already exists at $CLONE_DIR"
    cd "$CLONE_DIR"

    # Pull latest
    if git pull --ff-only origin master 2>/dev/null; then
        success "Updated to latest"
    else
        warn "Could not fast-forward, using existing state"
    fi
else
    git clone "https://github.com/${REPO}.git" "$CLONE_DIR" 2>/dev/null
    success "Cloned to $CLONE_DIR"
    cd "$CLONE_DIR"
fi

# ── Generate machine identity ────────────────────────────────────────────────

step "Detecting this machine..."

GEN_SCRIPT="$CLONE_DIR/scripts/generate-machine-info.sh"
if [ -x "$GEN_SCRIPT" ]; then
    result=$("$GEN_SCRIPT" --auto 2>/dev/null || echo "failed")
    if [ "$result" = "regenerated" ]; then
        success "Generated machine-info.json"
    elif [ "$result" = "current" ]; then
        success "machine-info.json is current"
    else
        # First time, force write
        "$GEN_SCRIPT" --write 2>/dev/null
        success "Created machine-info.json"
    fi

    machine_name=$(jq -r '.machineName // "unknown"' .claude/machine-info.json 2>/dev/null)
    hostname_val=$(jq -r '.system.hostname // "unknown"' .claude/machine-info.json 2>/dev/null)
    success "Machine: $machine_name ($hostname_val)"
else
    warn "generate-machine-info.sh not found, skipping"
fi

# ── Run bootstrap ────────────────────────────────────────────────────────────

step "Running bootstrap..."

if [ -x "$CLONE_DIR/bootstrap.sh" ]; then
    # Run bootstrap in non-interactive mode
    "$CLONE_DIR/bootstrap.sh" --skip-daemon 2>&1 | while IFS= read -r line; do
        echo "    $line"
    done
    success "Bootstrap complete"
else
    warn "bootstrap.sh not found, doing manual setup"

    # Minimal manual setup
    mkdir -p "$HOME/.claude" 2>/dev/null
    if [ -f "$CLONE_DIR/.claude/settings.json" ]; then
        cp "$CLONE_DIR/.claude/settings.json" "$HOME/.claude/settings.json" 2>/dev/null
        success "Copied Claude settings"
    fi
fi

# ── Install systemd service ──────────────────────────────────────────────────

step "Setting up sync daemon..."

SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/omarchy-sync.service"

mkdir -p "$SERVICE_DIR" 2>/dev/null

if [ ! -f "$SERVICE_FILE" ]; then
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Claude Cross-Machine Sync Daemon
Documentation=https://github.com/${REPO}
After=network-online.target

[Service]
Type=simple
ExecStart=$CLONE_DIR/omarchy/omarchy-sync-daemon.sh
Restart=on-failure
RestartSec=30
Environment=HOME=$HOME

[Install]
WantedBy=default.target
EOF
    success "Created systemd service"
else
    success "Systemd service already exists"
fi

# Enable and start
systemctl --user daemon-reload 2>/dev/null
systemctl --user enable omarchy-sync.service 2>/dev/null
success "Service enabled"

if systemctl --user is-active --quiet omarchy-sync.service 2>/dev/null; then
    success "Daemon already running"
else
    systemctl --user start omarchy-sync.service 2>/dev/null && success "Daemon started" || warn "Could not start daemon (may need inotifywait)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Repo:    ${BOLD}$CLONE_DIR${NC}"
echo -e "  Daemon:  ${BOLD}systemctl --user status omarchy-sync${NC}"
echo -e "  Logs:    ${BOLD}~/.local/state/omarchy-sync.log${NC}"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "    1. Check daemon: ${BOLD}systemctl --user status omarchy-sync${NC}"
echo -e "    2. View logs:    ${BOLD}tail -f ~/.local/state/omarchy-sync.log${NC}"
echo -e "    3. Test sync:    ${BOLD}cd $CLONE_DIR && git log --oneline -5${NC}"
echo ""
