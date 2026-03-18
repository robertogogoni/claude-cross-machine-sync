---
name: MCP server inventory
description: Full list of MCP servers in CLI (13) and Desktop (13), plus memory-sync bridge between them
type: project
---

## CLI MCP Servers (13 total)

| Server | Command | Source |
|--------|---------|--------|
| cortex | node ~/.local/share/mcp-servers/cortex-claude/cortex/server.cjs | User's own repo |
| context7 | npx -y @upstash/context7-mcp@latest | Plugin |
| playwright | npx -y @playwright/mcp@latest | Plugin |
| filesystem | npx -y @modelcontextprotocol/server-filesystem /home/robthepirate | npm |
| sequential-thinking | npx -y @modelcontextprotocol/server-sequential-thinking | npm |
| brave-search | npx -y @modelcontextprotocol/server-brave-search | npm |
| sqlite | uvx mcp-server-sqlite --db-path ~/test.db | PyPI via uvx |
| fetch | uvx mcp-server-fetch | PyPI via uvx |
| time | uvx mcp-server-time --local-timezone=America/New_York | PyPI via uvx |
| github | npx -y @modelcontextprotocol/server-github | Plugin |
| memory | npx -y @modelcontextprotocol/server-memory | npm |
| memory-sync | node ~/.local/share/mcp-servers/memory-sync/server.cjs | Custom |
| beeper | http://0.0.0.0:23373/v0/mcp (HTTP) | Beeper Desktop |

## Desktop MCP Servers (13 total)

Same servers minus cortex/beeper, plus chrome (superpowers). Config: `~/.config/Claude/claude_desktop_config.json`.

## Memory Sync System

Bridges CLI memories to Desktop via compiled profile:
- **Script:** `~/.local/bin/claude-memory-sync` compiles memory files into `~/.claude/memory-profile.md`
- **Hook:** SessionEnd in settings.json auto-triggers sync
- **MCP server:** `~/.local/share/mcp-servers/memory-sync/server.cjs` exposes `get_user_profile` and `sync_memories` tools
- Both CLI and Desktop have this MCP

**How to apply:** `claude mcp add/remove --scope user` for CLI. Desktop config is the JSON file.
