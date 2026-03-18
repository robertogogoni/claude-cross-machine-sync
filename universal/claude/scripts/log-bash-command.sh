#!/bin/bash
# Log bash commands from Claude Code PostToolUse hook
# Receives JSON on stdin with tool_input.command and tool_input.description

LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/bash-commands.log"

mkdir -p "$LOG_DIR"

INPUT=$(cat)

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // "unknown"' 2>/dev/null)
DESC=$(echo "$INPUT" | jq -r '.tool_input.description // "no description"' 2>/dev/null)

if [ -n "$COMMAND" ]; then
    echo "[$TIMESTAMP] $COMMAND - $DESC" >> "$LOG_FILE"
fi
