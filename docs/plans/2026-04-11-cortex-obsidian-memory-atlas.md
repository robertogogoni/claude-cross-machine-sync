# Cortex + Obsidian Memory Atlas

**Date**: 2026-04-11
**Status**: Implemented foundation

## Goal

Use the existing `cortex-claude` memory engine as the **local intelligence layer** while exporting a portable, Obsidian-compatible vault subtree that can be synced across machines through the existing `claude-cross-machine-sync` workflow.

## Why this shape

This follows the current repo architecture and the research findings:

1. Flat markdown remains human-readable and diffable.
2. Cortex remains the local query/index/retrieval layer.
3. The exported Obsidian vault becomes the cross-machine, app-agnostic memory surface.
4. Derived local indexes stay local and rebuildable instead of becoming another sync problem.

## Implemented Pieces

### In `~/repos/cortex-claude/`

- `adapters/markdown-tree-adapter.cjs`
  - Reads arbitrary markdown trees and normalizes them into Cortex `MemoryRecord`s.
  - Intended for Claude auto-memory, learnings, connections, and other markdown knowledge bases.

- `core/obsidian-vault.cjs`
  - Exports normalized memory records into an Obsidian-compatible subtree.
  - Generates:
    - `Cortex Atlas/00 Home.md`
    - `Cortex Atlas/10 Records/...`
    - `Cortex Atlas/20 Sources/...`
    - `Cortex Atlas/30 Types/...`
    - `Cortex Atlas/40 Tags/...`
    - `Cortex Atlas/manifest.json`

- `bin/cortex.cjs`
  - New command: `cortex export-vault`

### In this repo

- `scripts/export-memory-atlas.sh`
  - Thin wrapper that points Cortex at repo-native markdown sources plus optional local Claude memory.

## Example Usage

```bash
./scripts/export-memory-atlas.sh \
  --limit 250
```

Optional environment overrides:

```bash
VAULT_PATH="$HOME/Obsidian/MainVault" \
ROOT_FOLDER="Unified Memory" \
MACHINE_MEMORY_PATH="$PWD/machines/macbookair-omarchy/memory" \
./scripts/export-memory-atlas.sh
```

If Cortex lives somewhere else:

```bash
CORTEX_DIR="$HOME/.claude/memory/cortex" ./scripts/export-memory-atlas.sh
```

## Current Source Coverage

The wrapper currently exports markdown-based knowledge from:

- `universal/claude/memory/`
- `learnings/`
- `connections/`
- `docs/research/`
- optional machine memory via `MACHINE_MEMORY_PATH`
- optional local Claude auto memory via `LOCAL_CLAUDE_MEMORY`

Other sources such as Warp SQLite, Gemini brain sessions, Cortex JSONL stores, and MCP-backed sources are already supported by Cortex itself and can also be included through direct `cortex export-vault` usage.

## Architectural Model

```text
Repo markdown + local markdown memories
    -> Cortex adapters normalize/query
    -> Cortex exports generated Obsidian subtree
    -> Vault syncs across machines
    -> Each machine rebuilds local Cortex indexes as needed
```

## What this does not solve yet

- No automatic systemd/timer export job yet
- No bidirectional Obsidian -> Cortex write-back yet
- No temporal/entity graph note generation beyond source/type/tag structure yet
- No sync conflict policy for generated vault content yet

## Recommended Next Steps

1. Add a scheduled export hook or timer.
2. Add richer entity extraction for people, machines, repos, and services.
3. Add a machine-specific source manifest so the wrapper can auto-discover the correct `machines/<name>/memory` path.
4. Decide whether the generated vault subtree lives inside this repo or in a separate synced Obsidian vault.
