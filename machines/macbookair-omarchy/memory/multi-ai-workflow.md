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

## Current State (2026-04-11)

### Done
- Playwright MCP fixed to use Chrome Canary (see Playwright section below)
- Architecture decided: OpenAI MCP server added to `~/.claude.json`
- User confirmed they have an OpenAI API key

### Pending (next session)
1. Add `OPENAI_API_KEY` to `~/.bashrc`:
   ```bash
   echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc
   source ~/.bashrc
   ```
2. Add OpenAI MCP server to `~/.claude.json`:
   ```json
   "openai": {
     "command": "npx",
     "args": ["-y", "mcp-openai"],
     "env": {
       "OPENAI_API_KEY": "${OPENAI_API_KEY}"
     }
   }
   ```
   **Verify package name first**: `npm info mcp-openai` before installing — this space moves fast.
   Alternative package to check: `@openai/mcp-server-openai`

3. Restart Claude session for MCP to load
4. Verify OpenAI tools appear in ToolSearch

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
