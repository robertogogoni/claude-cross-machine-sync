---
name: MCP server inventory
description: Full list of MCP servers in CLI (13) and Desktop (14), registry locations, and npm cache fix applied 2026-04-04
type: project
---

## CLI MCP Servers (13 total, registered in ~/.claude.json)

| Server | Command | Source | Status |
|--------|---------|--------|--------|
| cortex | node ~/.local/share/mcp-servers/cortex-claude/cortex/server.cjs | User's own repo | Working |
| context7 | npx -y @upstash/context7-mcp@latest | Plugin | Working |
| playwright | npx -y @playwright/mcp@latest | Plugin | Working |
| filesystem | npx -y @modelcontextprotocol/server-filesystem /home/robthepirate | npm | Working |
| sequential-thinking | npx -y @modelcontextprotocol/server-sequential-thinking | npm | Working |
| brave-search | npx -y @modelcontextprotocol/server-brave-search | npm | Working (needs BRAVE_API_KEY) |
| sqlite | uvx mcp-server-sqlite --db-path ~/test.db | PyPI via uvx | Working |
| fetch | uvx mcp-server-fetch | PyPI via uvx | Working |
| time | uvx mcp-server-time --local-timezone=America/New_York | PyPI via uvx | Working |
| github | npx -y @modelcontextprotocol/server-github | npm | Working (needs GITHUB_PERSONAL_ACCESS_TOKEN) |
| memory | npx -y @modelcontextprotocol/server-memory | npm | Working |
| memory-sync | node ~/.local/share/mcp-servers/memory-sync/server.cjs | Custom | Working |
| beeper | http://0.0.0.0:23373/v0/mcp (HTTP) | Beeper Desktop | Only when Beeper is running |

**Note:** CLI MCP servers are in `~/.claude.json` (NOT `~/.claude/settings.json`). Cortex installed itself there via its install.sh.

## Desktop MCP Servers (14 total, in ~/.config/Claude/claude_desktop_config.json)

All CLI servers except cortex/beeper, plus:
- **chrome:** node ~/.local/share/mcp-servers/superpowers-chrome/mcp/dist/index.js
- **git:** uvx mcp-server-git --repository ~/claude-cross-machine-sync (updated 2026-04-04, was incorrectly pointing to ~ which is not a git repo)

## Memory Sync System

Bridges CLI memories to Desktop via compiled profile:
- **Script:** `~/.local/bin/claude-memory-sync` compiles memory files into `~/.claude/memory-profile.md`
- **Hook:** SessionEnd in settings.json auto-triggers sync
- **MCP server:** `~/.local/share/mcp-servers/memory-sync/server.cjs` exposes `get_user_profile` and `sync_memories` tools
- Both CLI and Desktop have this MCP

## Known Issues and Fixes

### npm cache corruption (fixed 2026-04-04)
When Claude Desktop launches all npx-based servers simultaneously, they race to acquire npm's package lock. If any crashes mid-install, the lock becomes corrupted (ECOMPROMISED), blocking ALL subsequent npx operations. Context7 also had an ENOTEMPTY (stale rename directory).

**Fix:** `rm -rf ~/.npm/_npx && rm -f ~/.npm/_locks/* && npm cache verify`

**Prevention:** For frequently used MCP servers, consider `npm install -g` and using direct binary paths instead of `npx -y`.

**How to apply:** `claude mcp add/remove --scope user` for CLI. Desktop config is the JSON file (hook-protected, use python3 or manual edit).
