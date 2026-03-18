#!/usr/bin/env bash
#
# Display current machine profile in a human-readable format
#

MACHINES_DIR="$HOME/.claude/machines"
CURRENT="$MACHINES_DIR/current.json"

if [[ ! -f "$CURRENT" ]]; then
  echo "❌ No current machine profile found"
  echo "Run: ~/.claude/machines/detect-machine.sh"
  exit 1
fi

# Display machine profile
echo "╔══════════════════════════════════════════════════════════╗"
echo "║             CURRENT MACHINE PROFILE                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

echo "🖥️  IDENTITY"
jq -r '"   Name: \(.identity.friendlyName)\n   Hostname: \(.identity.hostname)\n   Type: \(.identity.type)\n   Primary: \(if .identity.primary then "Yes ⭐" else "No" end)"' "$CURRENT"

echo ""
echo "⚙️  HARDWARE"
jq -r '"   CPU: \(.hardware.cpu.model)\n   Cores: \(.hardware.cpu.cores) cores / \(.hardware.cpu.threads) threads\n   RAM: \(.hardware.memory.total)\n   Storage: \(.hardware.storage.root.size) (\(.hardware.storage.root.usage) used)\n   Graphics: \(.hardware.graphics.integrated)"' "$CURRENT"

echo ""
echo "💿 OPERATING SYSTEM"
jq -r '"   OS: \(.os.distribution)\n   Kernel: \(.os.kernel)\n   Architecture: \(.os.architecture)"' "$CURRENT"

echo ""
echo "🎯 CAPABILITIES"
jq -r '"   Performance: \(.capabilities.performance)\n   Portability: \(.capabilities.portability)\n   Good for: \(.capabilities.goodFor | join(", "))"' "$CURRENT"

echo ""
echo "🔧 CLAUDE CODE"
jq -r '"   Passwordless Sudo: \(if .claudeCode.features.passwordlessSudo then "✅" else "❌" end)\n   MCP Servers: \(.claudeCode.features.mcpServers | length) active\n   Custom Commands: \(.claudeCode.features.customCommands | length)\n   Output Style: \(.claudeCode.preferences.outputStyle)"' "$CURRENT"

echo ""
echo "📝 USAGE"
jq -r '"   Purpose: \(.usage.primaryPurpose)\n   Location: \(.usage.location)"' "$CURRENT"

echo ""
echo "───────────────────────────────────────────────────────────"
echo "Profile: $(readlink -f "$CURRENT")"
echo "Last Updated: $(jq -r '.metadata.lastUpdated' "$CURRENT")"
