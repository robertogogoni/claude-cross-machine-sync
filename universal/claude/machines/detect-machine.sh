#!/usr/bin/env bash
#
# Machine Detection Script for Claude Code
# Automatically identifies which machine Claude is running on
#
# Usage: ./detect-machine.sh [--json] [--name-only]
#

set -euo pipefail

MACHINES_DIR="$HOME/.claude/machines"
OUTPUT_JSON=false
NAME_ONLY=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --json) OUTPUT_JSON=true ;;
    --name-only) NAME_ONLY=true ;;
  esac
done

# Get machine identifiers
get_hostname() {
  hostname 2>/dev/null || echo "unknown"
}

get_machine_id() {
  if [[ -f /etc/machine-id ]]; then
    cat /etc/machine-id
  elif [[ -f /var/lib/dbus/machine-id ]]; then
    cat /var/lib/dbus/machine-id
  else
    echo "unknown"
  fi
}

get_os_type() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

# Detect current machine
detect_machine() {
  local hostname=$(get_hostname)
  local machine_id=$(get_machine_id)
  local os_type=$(get_os_type)

  # Check each profile
  for profile in "$MACHINES_DIR"/*.json; do
    [[ -f "$profile" ]] || continue
    [[ "$(basename "$profile")" == "current.json" ]] && continue

    # Extract profile hostname and machine ID
    local profile_hostname=$(jq -r '.identity.hostname // "unknown"' "$profile" 2>/dev/null)
    local profile_machine_id=$(jq -r '.identity.machineId // "unknown"' "$profile" 2>/dev/null)
    local profile_name=$(jq -r '.identity.name // "unknown"' "$profile" 2>/dev/null)

    # Match by hostname first (most reliable)
    if [[ "$hostname" == "$profile_hostname" ]] && [[ "$profile_hostname" != "unknown" ]] && [[ "$profile_hostname" != "TO_BE_DETECTED" ]]; then
      echo "$profile_name"
      return 0
    fi

    # Match by machine ID (unique identifier)
    if [[ "$machine_id" == "$profile_machine_id" ]] && [[ "$profile_machine_id" != "unknown" ]] && [[ "$profile_machine_id" != "TO_BE_DETECTED" ]]; then
      echo "$profile_name"
      return 0
    fi
  done

  echo "unknown"
  return 1
}

# Main detection logic
MACHINE_NAME=$(detect_machine)

if [[ "$NAME_ONLY" == true ]]; then
  echo "$MACHINE_NAME"
  exit 0
fi

if [[ "$OUTPUT_JSON" == true ]]; then
  # Output detailed JSON
  cat <<EOF
{
  "detected": "$([ "$MACHINE_NAME" != "unknown" ] && echo "true" || echo "false")",
  "name": "$MACHINE_NAME",
  "hostname": "$(get_hostname)",
  "machineId": "$(get_machine_id)",
  "osType": "$(get_os_type)",
  "timestamp": "$(date -Iseconds)",
  "profile": "$MACHINES_DIR/$MACHINE_NAME.json"
}
EOF
else
  # Human-readable output
  if [[ "$MACHINE_NAME" == "unknown" ]]; then
    echo "❌ Could not detect machine profile"
    echo "Hostname: $(get_hostname)"
    echo "Machine ID: $(get_machine_id)"
    echo "OS Type: $(get_os_type)"
    echo ""
    echo "Create a profile for this machine in: $MACHINES_DIR/"
    exit 1
  else
    echo "✅ Detected machine: $MACHINE_NAME"
    echo "Profile: $MACHINES_DIR/$MACHINE_NAME.json"

    # Show brief machine info
    if [[ -f "$MACHINES_DIR/$MACHINE_NAME.json" ]]; then
      echo ""
      echo "Machine Info:"
      jq -r '"  Name: \(.identity.friendlyName // "N/A")\n  Type: \(.identity.type // "N/A")\n  CPU: \(.hardware.cpu.model // "N/A")\n  RAM: \(.hardware.memory.total // "N/A")\n  OS: \(.os.distribution // "N/A")"' "$MACHINES_DIR/$MACHINE_NAME.json"
    fi
  fi
fi

exit 0
