---
name: MCP diagnostic log locations
description: Where to find MCP server logs and error details for Claude Desktop and CLI
type: reference
---

## Claude Desktop MCP Logs
- **Main MCP log:** `~/.config/Claude/logs/mcp.log` (connection events, init messages)
- **Per-server stderr:** `~/.config/Claude/logs/mcp-server-<name>.log` (e.g., mcp-server-memory.log, mcp-server-git.log)
- **App log:** `~/.config/Claude/logs/main.log` (general Desktop errors)

## Claude Code CLI MCP
- **CLI MCP servers registered in:** `~/.claude.json` (mcpServers section)
- **CLI hooks/permissions in:** `~/.claude/settings.json`
- **Bash command audit log:** `~/.claude/logs/bash-commands.log`

## npm Debug Logs
- **Location:** `~/.npm/_logs/` (timestamped debug files)
- **npx cache:** `~/.npm/_npx/` (can be nuked safely if corrupted)
- **npm lock files:** `~/.npm/_locks/`

## Cortex Logs
- **Bridge status:** `~/.local/state/cortex-bridge-status.json`
- **Bridge log:** `~/.local/state/cortex-bridge.log`
- **Memory JSONL logs:** `~/.claude/memory/logs/cortex-*.jsonl`
