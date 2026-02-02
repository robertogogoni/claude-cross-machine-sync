#!/bin/bash
# Rollback Mechanism for Machine Sync
# Creates snapshots before operations and restores on failure
#
# Usage:
#   source lib/rollback.sh
#   create_snapshot "bootstrap"      # Before operation
#   ... do work ...
#   commit_snapshot                   # On success
#   # OR
#   rollback_snapshot                 # On failure
#
# Snapshots stored at:
#   ~/.local/state/machine-sync/snapshots/<timestamp>/

set -e

# Configuration
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$HOME/.local/state/machine-sync/snapshots}"
SNAPSHOT_RETENTION_DAYS="${SNAPSHOT_RETENTION_DAYS:-30}"

# Current snapshot (set by create_snapshot)
CURRENT_SNAPSHOT=""
CURRENT_SNAPSHOT_PATH=""

# Colors
: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

#######################################
# Create a snapshot before an operation
# Arguments:
#   $1 - Operation type (bootstrap|sync|deploy)
#   $2 - Repository path (optional)
# Globals:
#   CURRENT_SNAPSHOT - Set to snapshot ID
#   CURRENT_SNAPSHOT_PATH - Set to snapshot directory
#######################################
create_snapshot() {
    local operation="${1:-unknown}"
    local repo_path="${2:-.}"

    # Generate timestamp-based ID
    CURRENT_SNAPSHOT=$(date +%Y-%m-%dT%H:%M:%S)
    CURRENT_SNAPSHOT_PATH="$SNAPSHOT_DIR/$CURRENT_SNAPSHOT"

    mkdir -p "$CURRENT_SNAPSHOT_PATH"

    echo -e "${CYAN}Creating snapshot: $CURRENT_SNAPSHOT${NC}"

    # Create manifest
    local manifest="$CURRENT_SNAPSHOT_PATH/manifest.json"
    cat > "$manifest" << EOF
{
    "snapshot_id": "$CURRENT_SNAPSHOT",
    "operation": "$operation",
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$USER",
    "repo_path": "$(realpath "$repo_path")",
    "files": [],
    "status": "pending"
}
EOF

    # Backup key files
    local files_backed_up=()

    # Registry
    local registry="$repo_path/machines/registry.yaml"
    if [[ -f "$registry" ]]; then
        cp "$registry" "$CURRENT_SNAPSHOT_PATH/registry.yaml.bak"
        files_backed_up+=("machines/registry.yaml")
    fi

    # User Claude settings
    local claude_settings="$HOME/.claude/settings.json"
    if [[ -f "$claude_settings" ]]; then
        cp "$claude_settings" "$CURRENT_SNAPSHOT_PATH/settings.json.bak"
        files_backed_up+=("~/.claude/settings.json")
    fi

    # User Claude local settings
    local claude_local="$HOME/.claude/settings.local.json"
    if [[ -f "$claude_local" ]]; then
        cp "$claude_local" "$CURRENT_SNAPSHOT_PATH/settings.local.json.bak"
        files_backed_up+=("~/.claude/settings.local.json")
    fi

    # Systemd service if exists
    local systemd_service="$HOME/.config/systemd/user/machine-sync.service"
    if [[ -f "$systemd_service" ]]; then
        cp "$systemd_service" "$CURRENT_SNAPSHOT_PATH/machine-sync.service.bak"
        files_backed_up+=("~/.config/systemd/user/machine-sync.service")
    fi

    # Git state
    if [[ -d "$repo_path/.git" ]]; then
        local git_head
        git_head=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null || echo "none")
        echo "$git_head" > "$CURRENT_SNAPSHOT_PATH/git-head.txt"
        files_backed_up+=(".git/HEAD")
    fi

    # Update manifest with backed up files
    local files_json
    files_json=$(printf '%s\n' "${files_backed_up[@]}" | jq -R . | jq -s .)
    local tmp_manifest
    tmp_manifest=$(jq --argjson files "$files_json" '.files = $files' "$manifest")
    echo "$tmp_manifest" > "$manifest"

    echo -e "  ${GREEN}✓${NC} Backed up ${#files_backed_up[@]} files"

    # Clean old snapshots
    cleanup_old_snapshots
}

#######################################
# Mark snapshot as committed (successful operation)
#######################################
commit_snapshot() {
    if [[ -z "$CURRENT_SNAPSHOT_PATH" ]] || [[ ! -d "$CURRENT_SNAPSHOT_PATH" ]]; then
        echo -e "${YELLOW}No active snapshot to commit${NC}"
        return 1
    fi

    local manifest="$CURRENT_SNAPSHOT_PATH/manifest.json"

    # Update status
    local tmp
    tmp=$(jq '.status = "committed"' "$manifest")
    echo "$tmp" > "$manifest"

    echo -e "${GREEN}✓ Snapshot committed: $CURRENT_SNAPSHOT${NC}"

    # Clear current
    CURRENT_SNAPSHOT=""
    CURRENT_SNAPSHOT_PATH=""
}

#######################################
# Rollback to snapshot (undo operation)
# Arguments:
#   $1 - Snapshot ID (optional, uses current if not specified)
#   $2 - Repository path (optional)
#######################################
rollback_snapshot() {
    local snapshot_id="${1:-$CURRENT_SNAPSHOT}"
    local repo_path="${2:-.}"
    local snapshot_path

    if [[ -z "$snapshot_id" ]]; then
        # Find most recent snapshot
        snapshot_id=$(ls -1 "$SNAPSHOT_DIR" 2>/dev/null | sort -r | head -1)
        if [[ -z "$snapshot_id" ]]; then
            echo -e "${RED}No snapshots available for rollback${NC}"
            return 1
        fi
    fi

    snapshot_path="$SNAPSHOT_DIR/$snapshot_id"

    if [[ ! -d "$snapshot_path" ]]; then
        echo -e "${RED}Snapshot not found: $snapshot_id${NC}"
        return 1
    fi

    local manifest="$snapshot_path/manifest.json"
    if [[ ! -f "$manifest" ]]; then
        echo -e "${RED}Invalid snapshot (no manifest): $snapshot_id${NC}"
        return 1
    fi

    echo -e "${YELLOW}Rolling back to snapshot: $snapshot_id${NC}"

    local restored=0
    local failed=0

    # Restore registry
    if [[ -f "$snapshot_path/registry.yaml.bak" ]]; then
        local registry="$repo_path/machines/registry.yaml"
        if cp "$snapshot_path/registry.yaml.bak" "$registry"; then
            echo -e "  ${GREEN}✓${NC} Restored: machines/registry.yaml"
            ((restored++))
        else
            echo -e "  ${RED}✗${NC} Failed: machines/registry.yaml"
            ((failed++))
        fi
    fi

    # Restore Claude settings
    if [[ -f "$snapshot_path/settings.json.bak" ]]; then
        if cp "$snapshot_path/settings.json.bak" "$HOME/.claude/settings.json"; then
            echo -e "  ${GREEN}✓${NC} Restored: ~/.claude/settings.json"
            ((restored++))
        else
            echo -e "  ${RED}✗${NC} Failed: ~/.claude/settings.json"
            ((failed++))
        fi
    fi

    # Restore Claude local settings
    if [[ -f "$snapshot_path/settings.local.json.bak" ]]; then
        if cp "$snapshot_path/settings.local.json.bak" "$HOME/.claude/settings.local.json"; then
            echo -e "  ${GREEN}✓${NC} Restored: ~/.claude/settings.local.json"
            ((restored++))
        else
            echo -e "  ${RED}✗${NC} Failed: ~/.claude/settings.local.json"
            ((failed++))
        fi
    fi

    # Restore systemd service
    if [[ -f "$snapshot_path/machine-sync.service.bak" ]]; then
        local service_dir="$HOME/.config/systemd/user"
        mkdir -p "$service_dir"
        if cp "$snapshot_path/machine-sync.service.bak" "$service_dir/machine-sync.service"; then
            systemctl --user daemon-reload 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Restored: systemd service"
            ((restored++))
        else
            echo -e "  ${RED}✗${NC} Failed: systemd service"
            ((failed++))
        fi
    fi

    # Restore git state (optional, dangerous)
    if [[ -f "$snapshot_path/git-head.txt" ]]; then
        local old_head
        old_head=$(cat "$snapshot_path/git-head.txt")
        if [[ "$old_head" != "none" ]]; then
            echo -e "  ${CYAN}ℹ${NC} Git was at: $old_head"
            echo -e "  ${YELLOW}!${NC} To reset git: git reset --hard $old_head"
        fi
    fi

    # Update manifest
    local tmp
    tmp=$(jq '.status = "rolled_back" | .rollback_time = "'"$(date -Iseconds)"'"' "$manifest")
    echo "$tmp" > "$manifest"

    # Summary
    echo ""
    if (( failed > 0 )); then
        echo -e "${YELLOW}Rollback completed with issues: $restored restored, $failed failed${NC}"
        return 2
    else
        echo -e "${GREEN}✓ Rollback complete: $restored files restored${NC}"
        return 0
    fi
}

#######################################
# List available snapshots
#######################################
list_snapshots() {
    echo -e "${CYAN}Available Snapshots${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        echo "No snapshots found"
        return
    fi

    local count=0
    for snap_dir in "$SNAPSHOT_DIR"/*/; do
        [[ -d "$snap_dir" ]] || continue

        local snap_id
        snap_id=$(basename "$snap_dir")
        local manifest="$snap_dir/manifest.json"

        if [[ -f "$manifest" ]]; then
            local operation status
            operation=$(jq -r '.operation' "$manifest")
            status=$(jq -r '.status' "$manifest")

            local status_color
            case "$status" in
                committed) status_color="${GREEN}" ;;
                rolled_back) status_color="${YELLOW}" ;;
                pending) status_color="${RED}" ;;
                *) status_color="${NC}" ;;
            esac

            echo -e "  $snap_id  ${CYAN}$operation${NC}  ${status_color}$status${NC}"
            ((count++))
        fi
    done

    if (( count == 0 )); then
        echo "No snapshots found"
    else
        echo ""
        echo "Total: $count snapshot(s)"
    fi
}

#######################################
# Cleanup old snapshots
# Keeps snapshots newer than SNAPSHOT_RETENTION_DAYS
#######################################
cleanup_old_snapshots() {
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        return
    fi

    local cutoff_date
    cutoff_date=$(date -d "-${SNAPSHOT_RETENTION_DAYS} days" +%Y-%m-%d 2>/dev/null || date -v-${SNAPSHOT_RETENTION_DAYS}d +%Y-%m-%d)

    local removed=0
    for snap_dir in "$SNAPSHOT_DIR"/*/; do
        [[ -d "$snap_dir" ]] || continue

        local snap_id
        snap_id=$(basename "$snap_dir")
        local snap_date="${snap_id:0:10}"

        # Compare dates
        if [[ "$snap_date" < "$cutoff_date" ]]; then
            rm -rf "$snap_dir"
            ((removed++))
        fi
    done

    if (( removed > 0 )); then
        echo -e "  ${CYAN}ℹ${NC} Cleaned up $removed old snapshot(s)"
    fi
}

#######################################
# Get snapshot details
# Arguments:
#   $1 - Snapshot ID
#######################################
show_snapshot() {
    local snapshot_id="$1"
    local snapshot_path="$SNAPSHOT_DIR/$snapshot_id"

    if [[ ! -d "$snapshot_path" ]]; then
        echo -e "${RED}Snapshot not found: $snapshot_id${NC}"
        return 1
    fi

    local manifest="$snapshot_path/manifest.json"
    if [[ ! -f "$manifest" ]]; then
        echo -e "${RED}Invalid snapshot (no manifest)${NC}"
        return 1
    fi

    echo -e "${CYAN}Snapshot Details: $snapshot_id${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    jq '.' "$manifest"

    echo ""
    echo "Backed up files:"
    ls -la "$snapshot_path"/*.bak 2>/dev/null || echo "  (none)"
}

# Export functions
export -f create_snapshot
export -f commit_snapshot
export -f rollback_snapshot
export -f list_snapshots
export -f cleanup_old_snapshots
export -f show_snapshot
