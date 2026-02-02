#!/bin/bash
# Bootstrap script for Machine Sync on Linux
#
# Sets up a new Linux machine to join the sync ecosystem:
# 1. Pre-flight validation
# 2. Detects machine hardware
# 3. Registers in machines/registry.yaml
# 4. Creates machine-specific directory
# 5. Installs sync daemon (systemd)
# 6. Deploys configs
#
# Usage:
#   ./bootstrap.sh                   # Normal run
#   ./bootstrap.sh --dry-run         # Preview without changes
#   ./bootstrap.sh --machine-name my-laptop
#   ./bootstrap.sh --skip-daemon
#   ./bootstrap.sh --rollback        # Undo last bootstrap

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

# Colors (export for lib scripts)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export NC='\033[0m'

step() { echo -e "\n${CYAN}[>] $1${NC}"; }
success() { echo -e "    ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "    ${YELLOW}[!]${NC} $1"; }
error() { echo -e "    ${RED}[X]${NC} $1"; exit 1; }
info() { echo -e "    ${NC}$1"; }

# Dry-run helper
dry_run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "    ${MAGENTA}[DRY-RUN]${NC} Would: $1"
        return 0
    fi
    return 1
}

# Source library modules
if [[ -f "$SCRIPT_DIR/lib/validator.sh" ]]; then
    source "$SCRIPT_DIR/lib/validator.sh"
fi
if [[ -f "$SCRIPT_DIR/lib/rollback.sh" ]]; then
    source "$SCRIPT_DIR/lib/rollback.sh"
fi

# Parse arguments
MACHINE_NAME=""
SKIP_DAEMON=false
DRY_RUN=false
DO_ROLLBACK=false
SKIP_PREFLIGHT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --machine-name)
            MACHINE_NAME="$2"
            shift 2
            ;;
        --skip-daemon)
            SKIP_DAEMON=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --rollback)
            DO_ROLLBACK=true
            shift
            ;;
        --skip-preflight)
            SKIP_PREFLIGHT=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --machine-name NAME    Set machine ID (default: derived from hostname)"
            echo "  --skip-daemon          Don't install systemd service"
            echo "  --dry-run              Preview changes without executing"
            echo "  --rollback             Undo the last bootstrap operation"
            echo "  --skip-preflight       Skip pre-flight validation checks"
            echo "  --help                 Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
done

# Handle rollback request
if [[ "$DO_ROLLBACK" == "true" ]]; then
    if type -t rollback_snapshot &>/dev/null; then
        rollback_snapshot "" "$REPO_DIR"
        exit $?
    else
        echo -e "${RED}Rollback module not available${NC}"
        exit 1
    fi
fi

# Banner
echo -e "${MAGENTA}"
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║       Machine Sync Bootstrap - Linux                      ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}  ⚠  DRY-RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Step 0: Pre-flight Validation
if [[ "$SKIP_PREFLIGHT" != "true" ]]; then
    if type -t validate_preflight &>/dev/null; then
        # Capture exit code without triggering set -e
        set +e
        validate_preflight "$REPO_DIR"
        validation_result=$?
        set -e

        if [[ $validation_result -eq 1 ]]; then
            echo ""
            echo -e "${RED}Pre-flight validation failed. Fix issues above or use --skip-preflight${NC}"
            exit 1
        elif [[ $validation_result -eq 2 ]]; then
            echo ""
            echo -e "${YELLOW}Proceeding with warnings...${NC}"
        fi
    else
        # Fallback minimal validation
        step "Basic validation..."
        command -v git &>/dev/null || { echo -e "${RED}git not installed${NC}"; exit 1; }
        success "git available"
    fi
fi

# Create snapshot for rollback (skip in dry-run)
if [[ "$DRY_RUN" != "true" ]] && type -t create_snapshot &>/dev/null; then
    create_snapshot "bootstrap" "$REPO_DIR"
fi

# Step 1: Detect Hardware
step "Detecting hardware..."

HOSTNAME=$(hostname)

# Try to get hardware info
VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
CHASSIS=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "0")

# Map chassis type
case "$CHASSIS" in
    9|10|14) CHASSIS_TYPE="laptop" ;;
    3|4|5|6|7) CHASSIS_TYPE="desktop" ;;
    *) CHASSIS_TYPE="unknown" ;;
esac

CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)

# GPU detection
GPU=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | sed 's/.*: //' || echo "Unknown")

# Memory
MEM_GB=$(free -g | awk '/^Mem:/{print $2}')

# OS
OS_NAME=$(grep -E "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
DESKTOP=${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}

success "Hostname: $HOSTNAME"
success "Model: $VENDOR $MODEL"
success "CPU: $CPU ($CPU_CORES cores)"
success "GPU: $GPU"
success "Memory: ${MEM_GB}GB"
success "OS: $OS_NAME"
success "Desktop: $DESKTOP"

# Generate machine ID (with sanitization)
if [ -z "$MACHINE_NAME" ]; then
    MACHINE_NAME=$(echo "$HOSTNAME" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '-' | sed 's/-$//')
fi

# Sanitize machine name for security
if type -t sanitize_path &>/dev/null; then
    MACHINE_NAME=$(sanitize_path "$MACHINE_NAME")
fi

info "Machine ID: $MACHINE_NAME"

# Step 2: Check/Create Machine Entry
step "Checking machine registry..."

REGISTRY_PATH="$REPO_DIR/machines/registry.yaml"
MACHINE_DIR="$REPO_DIR/machines/$MACHINE_NAME"

# Check if already registered
if grep -q "^  $MACHINE_NAME:" "$REGISTRY_PATH" 2>/dev/null; then
    success "Machine '$MACHINE_NAME' already registered"
else
    info "Adding machine to registry..."

    # Create machine entry
    MACHINE_ENTRY="
  $MACHINE_NAME:
    hostname: $HOSTNAME
    platform: linux
    os: $OS_NAME
    desktop: $DESKTOP
    hardware:
      vendor: $VENDOR
      model: $MODEL
      type: $CHASSIS_TYPE
      cpu: $CPU
      gpu: $GPU
    status: active
    primary_user: $USER
    config_paths:
      home: \"$HOME\"
      claude: \"$HOME/.claude\"
      sync_repo: \"$REPO_DIR\"
      hypr: \"$HOME/.config/hypr\""

    if dry_run "Add entry to $REGISTRY_PATH for $MACHINE_NAME"; then
        echo "$MACHINE_ENTRY" | head -10
        info "... (truncated)"
    else
        # Insert before platforms: section
        sed -i "/^platforms:/i\\$MACHINE_ENTRY" "$REGISTRY_PATH"

        # Add to platforms.linux.machines list
        sed -i "/linux:/,/machines:/{/machines:/a\\      - $MACHINE_NAME
}" "$REGISTRY_PATH"
    fi

    success "Machine registered"
fi

# Step 3: Create Machine Directory
step "Setting up machine directory..."

if dry_run "Create $MACHINE_DIR/claude and $MACHINE_DIR/hypr"; then
    :  # No-op in dry-run
else
    mkdir -p "$MACHINE_DIR/claude" "$MACHINE_DIR/hypr"
fi

# Create machine.yaml
MACHINE_YAML_CONTENT="# Machine: $MODEL
# Auto-generated by bootstrap.sh on $(date +%Y-%m-%d)

machine:
  name: $MODEL
  hostname: $HOSTNAME
  id: $MACHINE_NAME
  type: $CHASSIS_TYPE

hardware:
  vendor: $VENDOR
  model: $MODEL
  chassis: $CHASSIS_TYPE

  cpu:
    model: $CPU
    cores: $CPU_CORES
    architecture: $(uname -m)

  gpu:
    model: $GPU

  memory:
    total: ${MEM_GB}GB

os:
  name: $OS_NAME
  desktop: $DESKTOP
  shell: $SHELL

software:
  claude_code: $(claude --version 2>/dev/null | head -1 || echo 'not installed')
  git: $(git --version 2>/dev/null || echo 'not installed')

sync_config:
  daemon_type: systemd
  service_name: machine-sync
  sync_interval_minutes: 5

last_updated: $(date +%Y-%m-%d)"

if dry_run "Create $MACHINE_DIR/machine.yaml"; then
    echo "$MACHINE_YAML_CONTENT" | head -5
    info "... (truncated)"
else
    echo "$MACHINE_YAML_CONTENT" > "$MACHINE_DIR/machine.yaml"
fi

# Skip the heredoc version since we handle it above
: << 'SKIP_ORIGINAL_MACHINE_YAML'
cat > "$MACHINE_DIR/machine.yaml" << EOF
# Machine: $MODEL
# Auto-generated by bootstrap.sh on $(date +%Y-%m-%d)

machine:
  name: $MODEL
  hostname: $HOSTNAME
  id: $MACHINE_NAME
  type: $CHASSIS_TYPE

hardware:
  vendor: $VENDOR
  model: $MODEL
  chassis: $CHASSIS_TYPE

  cpu:
    model: $CPU
    cores: $CPU_CORES
    architecture: $(uname -m)

  gpu:
    model: $GPU

  memory:
    total: ${MEM_GB}GB

os:
  name: $OS_NAME
  desktop: $DESKTOP
  shell: $SHELL

software:
  claude_code: $(claude --version 2>/dev/null | head -1 || echo "not installed")
  git: $(git --version 2>/dev/null || echo "not installed")

sync_config:
  daemon_type: systemd
  service_name: machine-sync
  sync_interval_minutes: 5

last_updated: $(date +%Y-%m-%d)
EOF
SKIP_ORIGINAL_MACHINE_YAML

success "Created machine.yaml"

# Step 4: Install Sync Daemon
if [ "$SKIP_DAEMON" = false ]; then
    step "Installing sync daemon..."

    DAEMON_SCRIPT="$REPO_DIR/platform/linux/scripts/sync-daemon.sh"
    if [ -f "$DAEMON_SCRIPT" ]; then
        if dry_run "Install systemd service from $DAEMON_SCRIPT"; then
            :
        else
            chmod +x "$DAEMON_SCRIPT"
            "$DAEMON_SCRIPT" --install
        fi
        success "Sync daemon installed"
    else
        warn "Daemon script not found at $DAEMON_SCRIPT"
    fi
fi

# Step 5: Deploy Configs
step "Deploying configurations..."

# Copy universal Claude settings
UNIVERSAL_SETTINGS="$REPO_DIR/universal/claude/settings.json"
CLAUDE_DIR="$HOME/.claude"

if dry_run "Create $CLAUDE_DIR directory"; then
    :
else
    mkdir -p "$CLAUDE_DIR"
fi

if [ -f "$UNIVERSAL_SETTINGS" ]; then
    if dry_run "Copy $UNIVERSAL_SETTINGS -> $CLAUDE_DIR/settings.json"; then
        :
    else
        cp "$UNIVERSAL_SETTINGS" "$CLAUDE_DIR/settings.json"
    fi
    success "Deployed Claude settings"
fi

# Copy machine-specific settings if exists
MACHINE_SETTINGS="$MACHINE_DIR/claude/settings.local.json"
if [ -f "$MACHINE_SETTINGS" ]; then
    if dry_run "Copy $MACHINE_SETTINGS -> $CLAUDE_DIR/settings.local.json"; then
        :
    else
        cp "$MACHINE_SETTINGS" "$CLAUDE_DIR/settings.local.json"
    fi
    success "Deployed machine-specific settings"
fi

# Deploy omarchy configs if this is a Linux+Hyprland machine
if [ -d "$HOME/.config/hypr" ] && [ -d "$REPO_DIR/platform/linux/omarchy" ]; then
    info "Hyprland detected, deploying omarchy configs..."

    # Deploy universal omarchy
    if [ -d "$REPO_DIR/platform/linux/omarchy/hypr" ]; then
        if dry_run "Copy omarchy hypr configs to ~/.config/hypr/"; then
            :
        else
            cp -r "$REPO_DIR/platform/linux/omarchy/hypr/"* "$HOME/.config/hypr/" 2>/dev/null || true
        fi
        success "Deployed universal Hyprland configs"
    fi

    # Deploy machine-specific
    if [ -d "$MACHINE_DIR/hypr" ]; then
        if dry_run "Copy machine-specific hypr configs"; then
            :
        else
            cp -r "$MACHINE_DIR/hypr/"* "$HOME/.config/hypr/" 2>/dev/null || true
        fi
        success "Deployed machine-specific Hyprland configs"
    fi
fi

# Step 6: Commit and Push
step "Committing registration..."

if [[ "$DRY_RUN" == "true" ]]; then
    dry_run "git add machines/"
    dry_run "git commit -m '[machine:$MACHINE_NAME] Register new machine: $HOSTNAME'"
    dry_run "git push"
else
    cd "$REPO_DIR"
    git add machines/
    if git diff --cached --quiet; then
        info "No changes to commit"
    else
        git commit -m "[machine:$MACHINE_NAME] Register new machine: $HOSTNAME

Hardware: $VENDOR $MODEL
OS: $OS_NAME
Desktop: $DESKTOP
User: $USER

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

        if git push 2>/dev/null; then
            success "Registration pushed to remote"
        else
            warn "Could not push (check network/auth)"
        fi
    fi

    # Commit snapshot on success
    if type -t commit_snapshot &>/dev/null; then
        commit_snapshot
    fi
fi

# Done
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║              Dry Run Complete - No Changes Made           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "  To apply these changes, run without --dry-run:"
    echo "  ${CYAN}./bootstrap.sh${NC}"
    echo ""
else
    echo -e "${GREEN}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                  Bootstrap Complete!                      ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo "  Machine: $MACHINE_NAME"
    echo "  Config:  $MACHINE_DIR"
    echo "  Daemon:  $(if $SKIP_DAEMON; then echo 'Skipped'; else echo 'Installed'; fi)"
    echo ""
    echo -e "  ${CYAN}Sync will happen automatically every 5 minutes.${NC}"
    echo -e "  ${CYAN}Manual sync: ./platform/linux/scripts/sync-daemon.sh --status${NC}"
    echo ""
    echo -e "  ${YELLOW}To rollback: ./bootstrap.sh --rollback${NC}"
    echo ""
fi
