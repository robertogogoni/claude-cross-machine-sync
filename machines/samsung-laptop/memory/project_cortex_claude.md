---
name: Cortex Claude — user's own memory system
description: cortex-claude v3.0.1 installed as MCP server with 4 hooks, warp-sqlite adapter with 219 memories, NOT related to michaelv2's fork
type: project
---

User's `cortex-claude` (v3.0.1) is installed at `~/.local/share/mcp-servers/cortex-claude/` and active as the `cortex` MCP server.

**Why:** This is the user's own creation — NOT related to michaelv2/claude-cortex-core (which is forked from mkdelta221/claude-cortex, a different project). The user's version has a fundamentally different architecture with dual-model reasoning and local embeddings.

**How to apply:**
- MCP server registered in `~/.claude.json` (NOT settings.json): `node ~/.local/share/mcp-servers/cortex-claude/cortex/server.cjs`
- 4 hooks in `~/.claude/settings.json`: SessionStart, SessionEnd, PreCompact (not currently in config), Stop (not currently in config)
- Active hooks as of 2026-04-04: SessionStart (session-start.cjs) and SessionEnd (session-end.cjs + cortex-to-learnings bridge)
- Tools: cortex__query, cortex__recall, cortex__reflect, cortex__infer, cortex__learn, cortex__consolidate
- Dependencies: @anthropic-ai/sdk, @xenova/transformers (local embeddings), hnswlib-node (vector search), better-sqlite3
- Dual-model features (reflect/infer/learn/consolidate) require ANTHROPIC_API_KEY — not yet configured
- Basic query/recall works without API key via FTS5 + local vector search
- DB at `~/.local/share/mcp-servers/cortex-claude/data/memories.db`

## Adapters (5 total)
- **warp-sqlite:** Primary adapter, 219 memories stored, 216 from warp history
- **gemini:** 3 memories
- **claudemd:** 0 memories
- **jsonl:** 0 memories
- **vector:** 0 memories (cold start)

## Bridge System
- `~/.local/bin/cortex-to-learnings` runs on SessionEnd, bridges insights to `~/claude-cross-machine-sync/learnings/`
- Status tracked in `~/.local/state/cortex-bridge-status.json`

## Known Issue
- "Failed to reconnect to cortex" can appear on `/mcp` command. This is a transient stdio pipe issue. The hooks work independently (they run as separate node processes). Self-heals on session restart.
