---
name: Multi-AI Workflow — OpenAI MCP Setup
description: Plan and current state for adding GPT-4o/OpenAI as a callable MCP tool within Claude Code sessions
type: project
originSessionId: 52524d78-338b-4022-96b3-43c4e0136e00
---
Goal: make GPT-4o (and other OpenAI models) callable as native tools inside Claude Code sessions via an OpenAI MCP server.

**Why:** Multi-AI workflow where Claude orchestrates tasks and can delegate to OpenAI models when useful.

**How to apply:** When setup is complete, Claude can call OpenAI models directly without Bash curl wrappers. Architecture chosen: MCP server (not Bash), so OpenAI tools appear in ToolSearch natively.

---

## Current State (2026-04-11) — COMPLETE

### Done
- Playwright MCP fixed to use Chrome Canary (see Playwright section below)
- Custom OpenAI MCP server written at `~/.claude/mcp/openai/server.mjs`
- Dependencies installed: `~/.claude/mcp/openai/node_modules/`
- `OPENAI_API_KEY` added to `~/.bashrc`
- OpenAI MCP server registered in `~/.claude.json` under key `"openai"`:
  ```json
  {
    "command": "node",
    "args": ["/home/rob/.claude/mcp/openai/server.mjs"],
    "env": { "OPENAI_API_KEY": "..." }
  }
  ```

### Pending (next session — requires restart)
- Restart Claude to load the new MCP server
- Verify tools appear: `ToolSearch("ask-openai")` and `ToolSearch("list-openai-models")`

### Why custom server (not mcp-openai package)
- `mcp-openai` v0.0.1 = 433 bytes, hardcodes gpt-4o-mini, no model selection
- Custom server: uses `registerTool` (current SDK API), supports gpt-4o/gpt-4o-mini/o1-mini/o3-mini, system prompt param

---

## Playwright MCP Fix (2026-04-11)

**Problem**: Playwright MCP defaults to Chrome stable distribution, which expects binary at `/opt/google/chrome/chrome` — not present on Arch (user has Chrome Canary only).

**Fix applied**: Both Playwright MCP config files updated to use Chrome Canary:

Config files (BOTH must match):
- `/home/rob/.claude/plugins/cache/claude-plugins-official/playwright/unknown/.mcp.json`
- `/home/rob/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json`

Current args:
```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--browser", "chromium", "--headed", "--executable-path", "/usr/bin/google-chrome-canary"]
  }
}
```

**Chrome Canary binary paths**:
- Real binary: `/usr/bin/google-chrome-canary`
- Wrapper script (stale-lock handler): `~/.local/bin/google-chrome-canary` → calls the real binary
- Playwright should target: `/usr/bin/google-chrome-canary` (the real binary, not the wrapper)

**Chromium headless shell** also installed at:
`~/.cache/ms-playwright/chromium_headless_shell-1217` (from `npx playwright install chromium`) — not used now that we point to Chrome Canary.

**Future option**: Add `--user-data-dir /home/rob/.config/google-chrome-canary/Default` to use existing Chrome Canary profile (already logged into sites). Without it, Playwright creates a fresh isolated profile requiring re-login every time.

**Requires session restart** to take effect (MCP servers load at startup).
