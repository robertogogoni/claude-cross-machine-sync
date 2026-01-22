#!/bin/bash
# Omarchy Reverse Sync: System → Repository
# Syncs changes from ~/.config/ back to the repo with automatic categorization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME=$(hostname)
CONFIG_DIR="$HOME/.config"
MACHINE_DIR="$SCRIPT_DIR/machines/$HOSTNAME"
UNIVERSAL_DIR="$SCRIPT_DIR/universal"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Omarchy Sync: System → Repository        ║${NC}"
echo -e "${BLUE}║   Machine: ${GREEN}$HOSTNAME${BLUE}                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"

# Ensure machine directory exists
mkdir -p "$MACHINE_DIR/hypr"

# ============================================================================
# AUTO-CATEGORIZATION FUNCTIONS
# ============================================================================

# Check if a Hyprland config file contains machine-specific content
is_machine_specific() {
    local file="$1"

    # Machine-specific patterns (hardware-dependent)
    local machine_patterns=(
        "^monitor\s*="           # Monitor configuration
        "^device\s*{"            # Device-specific settings
        "touchpad\s*{"           # Touchpad settings
        "XF86Kbd"                # Keyboard backlight (MacBook)
        "XF86Launch"             # Special function keys
        "XF86Audio"              # Audio keys (sometimes hardware-specific)
        "eDP-1"                  # Internal display port
        "HDMI-A-"                # External display port
        "DP-[0-9]"               # DisplayPort
        "apple-inc\."            # Apple hardware
        "sensitivity\s*="        # Input sensitivity
        "accel_profile"          # Acceleration profile
        "scroll_factor"          # Scroll factor
        "Intel HD"               # Intel GPU references
        "NVIDIA"                 # NVIDIA GPU references
        "AMD"                    # AMD GPU references
        "blur\s*{"               # Blur settings (GPU-dependent)
        "shadow\s*{"             # Shadow settings (GPU-dependent)
        "vfr\s*="                # Variable frame rate
        "vrr\s*="                # Variable refresh rate
    )

    for pattern in "${machine_patterns[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            return 0  # Is machine-specific
        fi
    done

    return 1  # Is universal
}

# Categorize and sync a file
sync_file() {
    local src="$1"
    local rel_path="$2"  # Relative path within config type (e.g., "hypr/bindings.conf")
    local config_type="$3"  # hypr, waybar, etc.

    if [ ! -f "$src" ]; then
        return
    fi

    local dest_dir
    local category

    # Determine category based on content analysis
    if is_machine_specific "$src"; then
        dest_dir="$MACHINE_DIR"
        category="${YELLOW}machine-specific${NC}"
    else
        dest_dir="$UNIVERSAL_DIR"
        category="${CYAN}universal${NC}"
    fi

    local dest="$dest_dir/$rel_path"
    mkdir -p "$(dirname "$dest")"

    # Check if file changed
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo -e "  ${GREEN}✓${NC} $rel_path (unchanged)"
    else
        cp "$src" "$dest"
        echo -e "  ${GREEN}✓${NC} $rel_path → $category"
    fi
}

# Force sync to specific location (for known categorization)
sync_to_machine() {
    local src="$1"
    local rel_path="$2"

    if [ ! -f "$src" ]; then
        return
    fi

    local dest="$MACHINE_DIR/$rel_path"
    mkdir -p "$(dirname "$dest")"

    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo -e "  ${GREEN}✓${NC} $rel_path (unchanged) ${YELLOW}[machine]${NC}"
    else
        cp "$src" "$dest"
        echo -e "  ${GREEN}✓${NC} $rel_path → ${YELLOW}machine-specific${NC}"
    fi
}

sync_to_universal() {
    local src="$1"
    local rel_path="$2"

    if [ ! -f "$src" ]; then
        return
    fi

    local dest="$UNIVERSAL_DIR/$rel_path"
    mkdir -p "$(dirname "$dest")"

    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo -e "  ${GREEN}✓${NC} $rel_path (unchanged) ${CYAN}[universal]${NC}"
    else
        cp "$src" "$dest"
        echo -e "  ${GREEN}✓${NC} $rel_path → ${CYAN}universal${NC}"
    fi
}

# ============================================================================
# SYNC HYPRLAND CONFIGS
# ============================================================================

echo ""
echo -e "${GREEN}► Syncing Hyprland configs...${NC}"

# Always machine-specific (hardware-dependent)
sync_to_machine "$CONFIG_DIR/hypr/monitors.conf" "hypr/monitors.conf"
sync_to_machine "$CONFIG_DIR/hypr/input.conf" "hypr/input.conf"
sync_to_machine "$CONFIG_DIR/hypr/looknfeel.conf" "hypr/looknfeel.conf"

# Always universal (workflow/preference)
sync_to_universal "$CONFIG_DIR/hypr/envs.conf" "hypr/envs.conf"
sync_to_universal "$CONFIG_DIR/hypr/workspace-window-rules.conf" "hypr/workspace-window-rules.conf"
sync_to_universal "$CONFIG_DIR/hypr/apps.conf" "hypr/apps.conf"

# Sync apps directory (always universal)
if [ -d "$CONFIG_DIR/hypr/apps" ]; then
    for file in "$CONFIG_DIR/hypr/apps"/*.conf; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            sync_to_universal "$file" "hypr/apps/$filename"
        fi
    done
fi

# Bindings: analyze content to split if needed
# For now, sync full bindings and let user/Claude manage the split
if [ -f "$CONFIG_DIR/hypr/bindings.conf" ]; then
    # Check if it's the combined file (sources other files)
    if grep -q "bindings-universal.conf" "$CONFIG_DIR/hypr/bindings.conf"; then
        echo -e "  ${BLUE}ℹ${NC} hypr/bindings.conf is combined (skipping - sync sources instead)"
        sync_to_universal "$CONFIG_DIR/hypr/bindings-universal.conf" "hypr/bindings.conf"
        sync_to_machine "$CONFIG_DIR/hypr/bindings-machine.conf" "hypr/bindings.conf"
    else
        # It's a monolithic file - analyze and sync appropriately
        sync_file "$CONFIG_DIR/hypr/bindings.conf" "hypr/bindings.conf" "hypr"
    fi
fi

# ============================================================================
# SYNC WAYBAR
# ============================================================================

echo ""
echo -e "${GREEN}► Syncing Waybar configs...${NC}"

sync_to_universal "$CONFIG_DIR/waybar/config.jsonc" "waybar/config.jsonc"
sync_to_universal "$CONFIG_DIR/waybar/style.css" "waybar/style.css"

# ============================================================================
# SYNC TERMINALS
# ============================================================================

echo ""
echo -e "${GREEN}► Syncing Terminal configs...${NC}"

sync_to_universal "$CONFIG_DIR/alacritty/alacritty.toml" "terminals/alacritty.toml"
sync_to_universal "$CONFIG_DIR/kitty/kitty.conf" "terminals/kitty.conf"
sync_to_universal "$CONFIG_DIR/ghostty/config" "terminals/ghostty.conf"

# ============================================================================
# SYNC WALKER
# ============================================================================

echo ""
echo -e "${GREEN}► Syncing Walker config...${NC}"

sync_to_universal "$CONFIG_DIR/walker/config.toml" "walker/config.toml"

# ============================================================================
# GIT STATUS
# ============================================================================

echo ""
echo -e "${GREEN}► Checking for changes...${NC}"

cd "$SCRIPT_DIR/.."
if git diff --quiet omarchy/; then
    echo -e "  ${GREEN}✓${NC} No changes to commit"
else
    echo ""
    echo -e "${YELLOW}Changed files:${NC}"
    git diff --name-only omarchy/ | sed 's/^/  /'
    echo ""

    # Ask to commit (or auto-commit if --commit flag)
    if [[ "$1" == "--commit" ]] || [[ "$1" == "-c" ]]; then
        git add omarchy/
        git commit -m "Sync omarchy configs from $HOSTNAME

Auto-synced by sync-to-repo.sh

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
        echo -e "${GREEN}✓ Changes committed${NC}"

        if [[ "$2" == "--push" ]] || [[ "$1" == "--push" ]]; then
            git push
            echo -e "${GREEN}✓ Pushed to remote${NC}"
        fi
    else
        echo -e "${YELLOW}To commit: ${BLUE}./sync-to-repo.sh --commit${NC}"
        echo -e "${YELLOW}To commit & push: ${BLUE}./sync-to-repo.sh --commit --push${NC}"
    fi
fi

echo ""
echo -e "${GREEN}► Sync complete!${NC}"
