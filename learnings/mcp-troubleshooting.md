# MCP Server Troubleshooting

## npm Cache Corruption (ECOMPROMISED / ENOTEMPTY)

**Problem:** Claude Desktop launches all npx-based MCP servers simultaneously. They all race to acquire npm's package lock at the same time. If any process crashes or gets killed mid-install (OOM on 8GB RAM, power loss, etc.), the lock file is left corrupted, blocking ALL subsequent npx operations.

**Symptoms:**
- Multiple MCP servers show "Server disconnected" in Desktop
- `mcp.log` shows servers starting but then "Server transport closed unexpectedly"
- Per-server logs (`mcp-server-*.log`) show `npm error code ECOMPROMISED` or `npm error code ENOTEMPTY`
- Testing with `echo '{"jsonrpc":"2.0"...}' | npx -y <package>` reproduces the error

**Fix:**
```bash
# Nuclear option: clear the entire npx cache and verify
rm -rf ~/.npm/_npx
rm -f ~/.npm/_locks/*
npm cache verify

# Then restart Claude Desktop
pkill -f "claude-desktop-bin"
sleep 2
nohup claude-desktop &>/dev/null &
```

**Prevention:**
- For frequently-used MCP servers, install globally (`npm install -g @modelcontextprotocol/server-memory`) and use the binary path instead of `npx -y`
- Alternatively, pin versions instead of using `@latest` to reduce cache churn

**Affected servers (npx-based):** memory, sequential-thinking, brave-search, filesystem, github, context7, playwright

**Unaffected servers:** chrome (local node), memory-sync (local node), cortex (local node), sqlite/fetch/time/git (uvx, separate package manager)

## Git MCP Server: Not a Valid Repository

**Problem:** The `git` MCP server in `claude_desktop_config.json` was pointing to `/home/robthepirate` which is not a git repository.

**Symptom:** `mcp-server-git.log` shows `ERROR:mcp_server_git.server:/home/robthepirate is not a valid Git repository`

**Fix:** Update the `--repository` argument to point to an actual git repo:
```json
"git": {
  "command": "uvx",
  "args": ["mcp-server-git", "--repository", "/home/robthepirate/claude-cross-machine-sync"]
}
```

## Cortex MCP Reconnect Failure

**Problem:** `/mcp` command shows "Failed to reconnect to cortex"

**Cause:** Transient stdio pipe issue. Cortex is registered in `~/.claude.json` (not `settings.json`). The MCP server process itself is healthy; this is a stale connection handle.

**Fix:** Restart Claude Code session. The hooks (SessionStart, SessionEnd) work independently as separate node processes and are unaffected.

## Diagnostic Commands

```bash
# Test any npx MCP server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 10 npx -y <package> 2>&1

# Check Desktop MCP logs
tail -50 ~/.config/Claude/logs/mcp.log | grep -E "error|disconnected|connected"

# Check per-server stderr
tail -20 ~/.config/Claude/logs/mcp-server-<name>.log

# Test cortex MCP server directly
echo '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' | timeout 5 node ~/.local/share/mcp-servers/cortex-claude/cortex/server.cjs

# Verify all Desktop servers connected after restart
grep "started and connected" ~/.config/Claude/logs/mcp.log | tail -14
```

## Tool Versions (as of 2026-04-04)

- node: v25.2.1 (via mise)
- npm: 11.6.2
- npx: 11.6.2
- uvx: 0.10.11
- bun: 1.3.11
- claude: 2.1.92
