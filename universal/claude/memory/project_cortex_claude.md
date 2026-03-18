---
name: Cortex Claude — user's own memory system
description: User's cortex-claude repo is their original persistent memory system for Claude Code (LADS pipeline), installed as the active MCP server
type: project
---

User's `cortex-claude` (v3.0.0) is installed at `~/.local/share/mcp-servers/cortex-claude/` and active as the `cortex` MCP server.

**Why:** This is the user's own creation — NOT related to michaelv2/claude-cortex-core (which is forked from mkdelta221/claude-cortex, a different project). The user's version has a fundamentally different architecture with dual-model reasoning and local embeddings.

**How to apply:**
- MCP server entry: `node ~/.local/share/mcp-servers/cortex-claude/cortex/server.cjs`
- 4 hooks in settings.json: SessionStart, SessionEnd, PreCompact, Stop
- Tools: cortex__query, cortex__recall, cortex__reflect, cortex__infer, cortex__learn, cortex__consolidate
- Dependencies: @anthropic-ai/sdk, @xenova/transformers (local embeddings), hnswlib-node (vector search), better-sqlite3
- Dual-model features (reflect/infer/learn/consolidate) require ANTHROPIC_API_KEY — not yet configured
- Basic query/recall works without API key via FTS5 + local vector search
- DB at `~/.claude-cortex/memories.db`
