---
name: npm cache corruption kills npx-based MCP servers
description: When MCP servers fail in bulk, check npm cache corruption first (ECOMPROMISED/ENOTEMPTY), fix with rm -rf ~/.npm/_npx
type: feedback
---

When multiple MCP servers fail simultaneously (especially npx-based ones), the first thing to check is npm cache corruption, not individual server configs.

**Why:** On 2026-04-04, 5 out of 14 Desktop MCP servers crashed. The root cause was a single corrupted npm package lock that affected all npx-launched servers. Investigating individual servers would have been a waste of time.

**How to apply:** When diagnosing MCP failures: (1) check `~/.config/Claude/logs/mcp-server-*.log` for `ECOMPROMISED` or `ENOTEMPTY`, (2) if found, run `rm -rf ~/.npm/_npx && rm -f ~/.npm/_locks/* && npm cache verify`, (3) restart Claude Desktop. Don't chase individual server configs until cache is ruled out.
