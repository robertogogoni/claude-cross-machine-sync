#!/bin/bash
# Omarchy Cross-Machine Sync - One-Command Setup
# Run this after cloning the repo on a new machine
#
# Usage:
#   ./setup.sh              # Interactive setup
#   ./setup.sh --auto       # Non-interactive (uses defaults)
#   ./setup.sh --uninstall  # Remove everything

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOSTNAME=$(hostname)
CONFIG_DIR="$HOME/.config"
SYSTEMD_USER_DIR="$CONFIG_DIR/systemd/user"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_banner() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}Omarchy Cross-Machine Sync Setup${NC}                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Machine: ${GREEN}$HOSTNAME${NC}                                        ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}►${NC} ${BOLD}$1${NC}"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$AUTO_MODE" == "true" ]]; then
        return 0
    fi

    local yn
    if [[ "$default" == "y" ]]; then
        read -p "  $prompt [Y/n]: " yn
        yn="${yn:-y}"
    else
        read -p "  $prompt [y/N]: " yn
        yn="${yn:-n}"
    fi

    [[ "$yn" =~ ^[Yy] ]]
}

# ============================================================================
# CHECK DEPENDENCIES
# ============================================================================

check_dependencies() {
    print_step "Checking dependencies..."

    local missing=()

    # Required
    if ! command -v git &> /dev/null; then
        missing+=("git")
    else
        print_success "git $(git --version | cut -d' ' -f3)"
    fi

    if ! command -v inotifywait &> /dev/null; then
        missing+=("inotify-tools")
    else
        print_success "inotifywait (inotify-tools)"
    fi

    # Optional but recommended
    if ! command -v hyprctl &> /dev/null; then
        print_warning "hyprctl not found (Hyprland not running?)"
    else
        print_success "hyprctl (Hyprland)"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        print_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo -e "  Install with:"

        # Detect package manager
        if command -v pacman &> /dev/null; then
            echo -e "    ${CYAN}sudo pacman -S ${missing[*]}${NC}"
        elif command -v apt &> /dev/null; then
            echo -e "    ${CYAN}sudo apt install ${missing[*]}${NC}"
        elif command -v dnf &> /dev/null; then
            echo -e "    ${CYAN}sudo dnf install ${missing[*]}${NC}"
        else
            echo -e "    ${CYAN}Use your package manager to install: ${missing[*]}${NC}"
        fi
        echo ""
        exit 1
    fi

    echo ""
}

# ============================================================================
# MACHINE SETUP
# ============================================================================

setup_machine_config() {
    print_step "Setting up machine-specific configuration..."

    local machine_dir="$SCRIPT_DIR/machines/$HOSTNAME"

    if [ -d "$machine_dir" ]; then
        print_success "Machine config exists: $machine_dir"
        return 0
    fi

    print_info "Creating new machine config for '$HOSTNAME'"
    mkdir -p "$machine_dir/hypr"

    # Create machine.yaml template
    cat > "$machine_dir/machine.yaml" << EOF
# Machine: $HOSTNAME
# Created: $(date '+%Y-%m-%d %H:%M:%S')

machine:
  name: $HOSTNAME
  hostname: $HOSTNAME
  id: $HOSTNAME

hardware:
  # Fill in your hardware details
  vendor: Unknown
  model: Unknown
  chassis: laptop  # laptop, desktop, server

  cpu:
    model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    cores: $(nproc)
    architecture: $(uname -m)

  memory:
    total: $(free -h | awk '/^Mem:/ {print $2}')

  display:
    internal:
      # Run: hyprctl monitors
      port: eDP-1
      resolution: auto
      scale: 1.0

os:
  distro: $(grep "^NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
  kernel: $(uname -r)
  desktop: Hyprland

last_updated: $(date '+%Y-%m-%d')
EOF
    print_success "Created machine.yaml"

    # Check if system configs exist to copy
    if [ -f "$CONFIG_DIR/hypr/monitors.conf" ]; then
        cp "$CONFIG_DIR/hypr/monitors.conf" "$machine_dir/hypr/"
        print_success "Copied monitors.conf from system"
    else
        # Create template
        cat > "$machine_dir/hypr/monitors.conf" << 'EOF'
# Monitor configuration for this machine
# Run 'hyprctl monitors' to see available monitors
# Format: monitor = name, resolution, position, scale

monitor = ,preferred,auto,1.0
EOF
        print_info "Created monitors.conf template (edit with your display settings)"
    fi

    if [ -f "$CONFIG_DIR/hypr/input.conf" ]; then
        cp "$CONFIG_DIR/hypr/input.conf" "$machine_dir/hypr/"
        print_success "Copied input.conf from system"
    else
        cat > "$machine_dir/hypr/input.conf" << 'EOF'
# Input configuration for this machine

input {
    kb_layout = us
    follow_mouse = 1

    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}
EOF
        print_info "Created input.conf template (edit with your input settings)"
    fi

    if [ -f "$CONFIG_DIR/hypr/looknfeel.conf" ]; then
        cp "$CONFIG_DIR/hypr/looknfeel.conf" "$machine_dir/hypr/"
        print_success "Copied looknfeel.conf from system"
    fi

    # Create machine-specific bindings if there are hardware-specific keys
    cat > "$machine_dir/hypr/bindings.conf" << 'EOF'
# Machine-specific keybindings
# Add hardware-specific keys here (keyboard backlight, special Fn keys, etc.)

# Example for laptop keyboard backlight:
# bindeld = , XF86KbdBrightnessDown, Keyboard backlight down, exec, brightnessctl -d *kbd_backlight set 5%-
# bindeld = , XF86KbdBrightnessUp, Keyboard backlight up, exec, brightnessctl -d *kbd_backlight set 5%+
EOF
    print_success "Created bindings.conf template"

    echo ""
    print_warning "Review and customize: $machine_dir/"
    echo ""
}

# ============================================================================
# SYSTEMD SERVICE
# ============================================================================

setup_systemd_service() {
    print_step "Setting up systemd user service..."

    mkdir -p "$SYSTEMD_USER_DIR"

    # Create service file
    cat > "$SYSTEMD_USER_DIR/omarchy-sync.service" << EOF
[Unit]
Description=Omarchy Config Auto-Sync Daemon
Documentation=https://github.com/robertogogoni/claude-cross-machine-sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/omarchy-sync-daemon.sh
ExecStop=/bin/kill -TERM \$MAINPID
Restart=on-failure
RestartSec=10

Environment=HOME=$HOME
Environment=PATH=/usr/local/bin:/usr/bin:/bin

StandardOutput=append:$HOME/.local/state/omarchy-sync.log
StandardError=append:$HOME/.local/state/omarchy-sync.log

[Install]
WantedBy=default.target
EOF
    print_success "Created systemd service file"

    # Reload systemd
    systemctl --user daemon-reload
    print_success "Reloaded systemd daemon"

    # Enable service
    if confirm "Enable omarchy-sync to start on login?"; then
        systemctl --user enable omarchy-sync
        print_success "Enabled omarchy-sync service"
    fi

    # Start service
    if confirm "Start omarchy-sync now?"; then
        systemctl --user start omarchy-sync
        print_success "Started omarchy-sync service"

        sleep 2
        if systemctl --user is-active --quiet omarchy-sync; then
            print_success "Service is running"
        else
            print_warning "Service may have failed to start. Check logs:"
            echo -e "    ${CYAN}journalctl --user -u omarchy-sync -f${NC}"
        fi
    fi

    echo ""
}

# ============================================================================
# DEPLOY CONFIGS
# ============================================================================

deploy_configs() {
    print_step "Deploying configurations..."

    if confirm "Deploy universal configs to system?"; then
        "$SCRIPT_DIR/deploy.sh"
        print_success "Configs deployed"

        # Reload Hyprland if running
        if pgrep -x Hyprland > /dev/null; then
            if confirm "Reload Hyprland to apply changes?"; then
                hyprctl reload
                print_success "Hyprland reloaded"
            fi
        fi
    else
        print_info "Skipped deployment. Run manually: ./deploy.sh"
    fi

    echo ""
}

# ============================================================================
# SYNC EXISTING CONFIGS
# ============================================================================

sync_existing_configs() {
    print_step "Syncing existing system configs to repo..."

    if confirm "Sync your current configs to the repo? (recommended for new machines)"; then
        "$SCRIPT_DIR/sync-to-repo.sh"

        # Check if there are changes to commit
        cd "$REPO_DIR"
        if ! git diff --quiet omarchy/; then
            echo ""
            print_info "Changes detected in configs"

            if confirm "Commit and push these changes?"; then
                git add omarchy/
                git commit -m "Add machine config for $HOSTNAME

Auto-generated by setup.sh

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
                print_success "Changes committed"

                if confirm "Push to remote?"; then
                    git push
                    print_success "Pushed to remote"
                fi
            fi
        else
            print_success "No changes to commit"
        fi
    fi

    echo ""
}

# ============================================================================
# COPY CLAUDE SETTINGS
# ============================================================================

setup_claude_settings() {
    print_step "Setting up Claude Code configuration..."

    local claude_dir="$HOME/.claude"
    mkdir -p "$claude_dir/skills"

    # Copy settings
    if [ -f "$REPO_DIR/.claude/settings.json" ]; then
        if [ -f "$claude_dir/settings.json" ]; then
            if confirm "Overwrite existing Claude settings?"; then
                cp "$REPO_DIR/.claude/settings.json" "$claude_dir/"
                print_success "Copied Claude settings"
            else
                print_info "Kept existing settings"
            fi
        else
            cp "$REPO_DIR/.claude/settings.json" "$claude_dir/"
            print_success "Copied Claude settings"
        fi
    fi

    # Copy skills
    if [ -d "$REPO_DIR/skills" ]; then
        if confirm "Copy Claude Code skills?"; then
            cp -r "$REPO_DIR/skills/"* "$claude_dir/skills/" 2>/dev/null || true
            print_success "Copied Claude Code skills"
        fi
    fi

    echo ""
}

# ============================================================================
# UNINSTALL
# ============================================================================

uninstall() {
    print_banner
    print_step "Uninstalling omarchy-sync..."

    # Stop and disable service
    if systemctl --user is-active --quiet omarchy-sync 2>/dev/null; then
        systemctl --user stop omarchy-sync
        print_success "Stopped service"
    fi

    if systemctl --user is-enabled --quiet omarchy-sync 2>/dev/null; then
        systemctl --user disable omarchy-sync
        print_success "Disabled service"
    fi

    # Remove service file
    if [ -f "$SYSTEMD_USER_DIR/omarchy-sync.service" ]; then
        rm "$SYSTEMD_USER_DIR/omarchy-sync.service"
        systemctl --user daemon-reload
        print_success "Removed service file"
    fi

    # Remove log file
    if [ -f "$HOME/.local/state/omarchy-sync.log" ]; then
        if confirm "Remove log file?"; then
            rm "$HOME/.local/state/omarchy-sync.log"
            print_success "Removed log file"
        fi
    fi

    echo ""
    print_success "Uninstall complete"
    print_info "The repo and configs remain in place. Delete manually if needed."
    echo ""
}

# ============================================================================
# PRINT SUMMARY
# ============================================================================

print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Setup Complete!${NC}                                          ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Quick Reference:${NC}"
    echo ""
    echo -e "  ${CYAN}Check sync status:${NC}"
    echo -e "    systemctl --user status omarchy-sync"
    echo ""
    echo -e "  ${CYAN}View live logs:${NC}"
    echo -e "    tail -f ~/.local/state/omarchy-sync.log"
    echo ""
    echo -e "  ${CYAN}Manual sync (system → repo):${NC}"
    echo -e "    $SCRIPT_DIR/sync-to-repo.sh --commit --push"
    echo ""
    echo -e "  ${CYAN}Manual deploy (repo → system):${NC}"
    echo -e "    $SCRIPT_DIR/deploy.sh"
    echo ""
    echo -e "  ${CYAN}Machine config location:${NC}"
    echo -e "    $SCRIPT_DIR/machines/$HOSTNAME/"
    echo ""
    echo -e "${BOLD}What happens now:${NC}"
    echo -e "  • Changes to ~/.config/hypr, waybar, etc. auto-sync to git"
    echo -e "  • Changes from other machines are pulled every 5 minutes"
    echo -e "  • Hyprland auto-reloads when configs change"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    AUTO_MODE="false"

    case "${1:-}" in
        --auto|-a)
            AUTO_MODE="true"
            ;;
        --uninstall|-u)
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "Omarchy Cross-Machine Sync Setup"
            echo ""
            echo "Usage:"
            echo "  $0              Interactive setup"
            echo "  $0 --auto       Non-interactive (uses defaults)"
            echo "  $0 --uninstall  Remove omarchy-sync service"
            echo "  $0 --help       Show this help"
            echo ""
            exit 0
            ;;
    esac

    print_banner

    check_dependencies
    setup_machine_config
    setup_claude_settings
    setup_systemd_service
    sync_existing_configs
    deploy_configs

    print_summary
}

main "$@"
