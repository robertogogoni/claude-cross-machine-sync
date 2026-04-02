#!/bin/bash
# generate-machine-info.sh — Auto-detect hardware and generate machine-info.json
#
# Usage:
#   ./generate-machine-info.sh                    # Print to stdout
#   ./generate-machine-info.sh --write            # Write to .claude/machine-info.json
#   ./generate-machine-info.sh --check            # Check if current info matches this machine
#
# Called by:
#   - bootstrap.sh (initial setup)
#   - omarchy-sync-daemon.sh (auto-regenerate if stale/wrong)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$REPO_DIR/.claude/machine-info.json"
REGISTRY="$REPO_DIR/machines/registry.yaml"

# ── Hardware detection ───────────────────────────────────────────────────────

detect_hardware() {
    local hostname vendor model chassis chassis_type
    local cpu cpu_arch cpu_cores cpu_threads cpu_vendor
    local mem_total mem_avail
    local disk_total disk_used disk_avail disk_pct
    local fw_ver fw_date
    local os_name os_id kernel machine_id
    local claude_ver shell_path git_ver node_ver

    hostname=$(hostname)
    vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | tr -d '\n' || echo "Unknown")
    model=$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr -d '\n' || echo "Unknown")
    chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "0")
    case "$chassis" in
        9|10|14) chassis_type="laptop" ;;
        3|4|5|6|7) chassis_type="desktop" ;;
        *) chassis_type="unknown" ;;
    esac

    cpu=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    cpu_arch=$(uname -m)
    cpu_cores=$(nproc)
    cpu_threads=$(grep -c ^processor /proc/cpuinfo)
    cpu_vendor=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | xargs)
    mem_total=$(free -h | awk '/^Mem:/{print $2}')
    mem_avail=$(free -h | awk '/^Mem:/{print $7}')
    disk_total=$(df -h / | awk 'NR==2{print $2}')
    disk_used=$(df -h / | awk 'NR==2{print $3}')
    disk_avail=$(df -h / | awk 'NR==2{print $4}')
    disk_pct=$(df -h / | awk 'NR==2{print $5}')
    fw_ver=$(cat /sys/class/dmi/id/bios_version 2>/dev/null | tr -d '\n' || echo "unknown")
    fw_date=$(cat /sys/class/dmi/id/bios_date 2>/dev/null | tr -d '\n' || echo "unknown")
    os_name=$(grep -E "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2)
    os_id=$(grep -E "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2)
    kernel=$(uname -r)
    machine_id=$(cat /etc/machine-id 2>/dev/null || echo "unknown")
    claude_ver=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    shell_path=${SHELL:-/bin/bash}
    git_ver=$(git --version 2>/dev/null | awk '{print $3}' || echo "unknown")
    node_ver=$(node --version 2>/dev/null || echo "unknown")

    # Resolve machine name from registry
    local machine_name="" machine_id_reg=""
    if [ -f "$REGISTRY" ]; then
        local current_machine=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9_-]+):$ ]]; then
                current_machine="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ hostname:[[:space:]]*(.+) ]]; then
                local reg_hostname="${BASH_REMATCH[1]}"
                reg_hostname=$(echo "$reg_hostname" | xargs)
                if [ "$reg_hostname" = "$hostname" ]; then
                    machine_id_reg="$current_machine"
                    break
                fi
            fi
        done < "$REGISTRY"
    fi

    # Fallback: derive from hostname
    if [ -z "$machine_id_reg" ]; then
        machine_id_reg=$(echo "$hostname" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '-' | sed 's/-$//')
    fi

    # Human-readable name from machine ID
    machine_name=$(echo "$machine_id_reg" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

    jq -n \
        --arg mn "$machine_name" \
        --arg mi "$machine_id_reg" \
        --arg hv "$vendor" --arg hm "$model" --arg hc "$chassis_type" \
        --arg cm "$cpu" --arg ca "$cpu_arch" --argjson cc "$cpu_cores" --argjson ct "$cpu_threads" --arg cv "$cpu_vendor" \
        --arg mt "$mem_total" --arg ma "$mem_avail" \
        --arg dt "$disk_total" --arg du "$disk_used" --arg da "$disk_avail" --arg dp "$disk_pct" \
        --arg fv "$fw_ver" --arg fd "$fw_date" \
        --arg on "$os_name" --arg oi "$os_id" --arg kr "$kernel" --arg hn "$hostname" --arg mid "$machine_id" \
        --arg clv "$claude_ver" --arg sh "$shell_path" --arg gv "$git_ver" --arg nv "$node_ver" \
        --arg ts "$(date -Iseconds)" \
        '{
          machineName: $mn, machineId: $mi,
          hardware: {
            vendor: $hv, model: $hm, chassis: $hc,
            cpu: { model: $cm, architecture: $ca, cores: $cc, threads: $ct, vendor: $cv },
            memory: { total: $mt, available: $ma },
            disk: { total: $dt, used: $du, available: $da, usage: $dp },
            firmware: { version: $fv, date: $fd }
          },
          system: { os: $on, osId: $oi, prettyName: $on, buildId: "rolling", kernel: ("Linux " + $kr), hostname: $hn, machineId: $mid },
          software: { claudeCode: { version: $clv, installMethod: "global" }, shell: $sh, git: $gv, node: $nv },
          lastUpdated: $ts,
          notes: [ ($hv + " " + $hm + " running " + $on), ("Hostname: " + $hn) ]
        }'
}

# ── Check mode: is the current machine-info.json correct? ────────────────────

check_info() {
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "missing"
        return 1
    fi

    local current_hostname
    current_hostname=$(jq -r '.system.hostname // ""' "$OUTPUT_FILE" 2>/dev/null)

    if [ "$current_hostname" != "$(hostname)" ]; then
        echo "stale (hostname: $current_hostname, expected: $(hostname))"
        return 1
    fi

    # Check if older than 7 days
    local file_age
    file_age=$(( $(date +%s) - $(stat -c %Y "$OUTPUT_FILE") ))
    if [ "$file_age" -gt 604800 ]; then
        echo "stale ($(( file_age / 86400 )) days old)"
        return 1
    fi

    echo "ok"
    return 0
}

# ── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
    --check)
        status=$(check_info)
        echo "$status"
        [ "$status" = "ok" ] && exit 0 || exit 1
        ;;
    --write)
        detect_hardware > "$OUTPUT_FILE"
        echo "Wrote $OUTPUT_FILE"
        ;;
    --auto)
        # Auto mode: only regenerate if stale or wrong
        if ! check_info > /dev/null 2>&1; then
            detect_hardware > "$OUTPUT_FILE"
            echo "regenerated"
        else
            echo "current"
        fi
        ;;
    *)
        detect_hardware
        ;;
esac
