# Memory Sync Bridge: CLI to Desktop

**Created**: 2026-03-18
**Problem**: Claude Code CLI and Claude Desktop don't share memories

## Architecture

```
CLI Memory Files (16 .md files, source of truth)
    |
    v  SessionEnd hook (auto)
claude-memory-sync script (bash)
    |
    v
~/.claude/memory-profile.md (337 lines, compiled markdown)
    |
    v  memory-sync MCP server (Node.js)
Both CLI and Desktop -> get_user_profile / sync_memories tools
```

## Components

### Sync script (`~/.local/bin/claude-memory-sync`)
- Reads all `~/.claude/projects/<project>/memory/*.md` files
- Strips YAML frontmatter, groups by type (user, feedback, project, reference)
- Outputs single compiled markdown file
- Triggered automatically by SessionEnd hook

### MCP server (`~/.local/share/mcp-servers/memory-sync/server.cjs`)
- Node.js CommonJS module (not ESM, for compatibility)
- Two tools: `get_user_profile` (read profile) and `sync_memories` (re-run sync + return)
- One resource: `memory://profile` (MCP resources protocol)
- Reads `~/.claude/memory-profile.md` on each call (always fresh)

### Hook (in `~/.claude/settings.json`)
- SessionEnd hook runs `~/.local/bin/claude-memory-sync`
- Fires after cortex session-end hook
- Ensures profile is current for next Desktop interaction

## Key design decisions
- One-directional: CLI writes, Desktop reads
- CommonJS not ESM: avoids Node.js ESM edge cases with stdin/readline
- Tool-based not resource-based: Desktop's Cowork/Chat tabs can call tools more reliably than reading MCP resources
- Compiled markdown not raw files: single clean document vs 16 separate files with frontmatter

## Custom instructions integration
Account-wide custom instructions reference memory-sync conditionally:
"If memory-sync MCP is available, call get_user_profile for detailed context."
This degrades gracefully on machines without the MCP server.
