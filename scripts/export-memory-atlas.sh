#!/bin/bash
# Export a Cortex-generated Obsidian memory atlas from the sync repo's markdown sources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CORTEX_DIR="${CORTEX_DIR:-$HOME/repos/cortex-claude}"
VAULT_PATH="${VAULT_PATH:-$HOME/knowledge-vault}"
ROOT_FOLDER="${ROOT_FOLDER:-Cortex Atlas}"
LOCAL_CLAUDE_MEMORY="${LOCAL_CLAUDE_MEMORY:-$HOME/.claude/projects/-home-rob/memory}"
MACHINE_MEMORY_PATH="${MACHINE_MEMORY_PATH:-}"

if [[ ! -f "$CORTEX_DIR/bin/cortex.cjs" ]]; then
    printf 'Cortex CLI not found at %s/bin/cortex.cjs\n' "$CORTEX_DIR" >&2
    printf 'Set CORTEX_DIR or clone cortex-claude to ~/repos/cortex-claude\n' >&2
    exit 1
fi

MARKDOWN_DIRS=(
    "$REPO_DIR/universal/claude/memory"
    "$REPO_DIR/learnings"
    "$REPO_DIR/connections"
    "$REPO_DIR/docs/research"
)

if [[ -n "$MACHINE_MEMORY_PATH" && -d "$MACHINE_MEMORY_PATH" ]]; then
    MARKDOWN_DIRS+=("$MACHINE_MEMORY_PATH")
fi

if [[ -d "$LOCAL_CLAUDE_MEMORY" ]]; then
    MARKDOWN_DIRS+=("$LOCAL_CLAUDE_MEMORY")
fi

exec node "$CORTEX_DIR/bin/cortex.cjs" export-vault \
    --vault-path "$VAULT_PATH" \
    --root-folder "$ROOT_FOLDER" \
    --clean \
    --markdown-dir "${MARKDOWN_DIRS[@]}" \
    "$@"
