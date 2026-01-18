#!/bin/bash
# Install hookify skill-enforcement rules to ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude"

mkdir -p "$TARGET_DIR"

echo "Installing hookify rules..."

for rule in "$SCRIPT_DIR"/hookify.*.local.md; do
    if [ -f "$rule" ]; then
        filename=$(basename "$rule")
        cp "$rule" "$TARGET_DIR/$filename"
        echo "  ✓ $filename"
    fi
done

echo ""
echo "Done! Rules are active immediately - no restart needed."
echo ""
echo "Installed rules:"
ls -1 "$TARGET_DIR"/hookify.*.local.md 2>/dev/null | xargs -I{} basename {}
