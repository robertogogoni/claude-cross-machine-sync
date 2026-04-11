---
name: Multi-AI Workflow — OpenAI + Codex MCP
description: OpenAI MCP (ask-openai/list-openai-models) and Codex MCP (codex/codex-reply/codex-exec/codex-review) — both registered, fixed 2026-04-11, require session restart to activate
type: project
originSessionId: 52524d78-338b-4022-96b3-43c4e0136e00
---

Goal: make GPT-4o (and other OpenAI models) callable as native tools inside Claude Code sessions via an OpenAI MCP server.

**Why:** Multi-AI workflow where Claude orchestrates tasks and can delegate to OpenAI models when useful.

**How to apply:** When setup is complete, Claude can call OpenAI models directly without Bash curl wrappers. Architecture chosen: MCP server (not Bash), so OpenAI tools appear in ToolSearch natively.

---

## Current State (2026-04-11) — COMPLETE + Fixed

### Done
- Playwright MCP fixed to use Chrome Canary (see Playwright section below)
- Custom OpenAI MCP server written at `~/.claude/mcp/openai/server.mjs`
- Dependencies installed: `~/.claude/mcp/openai/node_modules/`
- `OPENAI_API_KEY` added to `~/.bashrc`
- OpenAI MCP server registered in `~/.claude.json` under key `"openai"`
- **Codex CLI MCP** registered:
  - `"codex"` → `codex mcp-server` (native, tools: `codex`, `codex-reply`)
  - `"codex-exec"` → `~/.claude/mcp/codex/server.mjs` (custom wrapper, tools: `codex-exec`, `codex-review`)
- `mcp__codex__*` and `mcp__codex-exec__*` added to settings.json allow list

### Fixes applied 2026-04-11

**`~/.claude/mcp/codex/server.mjs`**:
- Removed invalid `-a never` flag (doesn't exist in Codex v0.120.0)
- Added `provider` param: `openai` (default) | `lmstudio` | `ollama`
- Added `profile` param: named config profile from `~/.codex/config.toml`
- Added `bypass_approvals` param (default: `true`) → `--dangerously-bypass-approvals-and-sandbox`
- Updated model descriptions to include all live-verified models

**`~/.claude/mcp/openai/server.mjs`**:
- `ask-openai` model param: `z.enum(4 models)` → `z.string()` (any model now works)
- `list-openai-models` now calls `openai.models.list()` live (was hardcoded 4 models — fake)
- Description updated with full verified model list

### Pending (after session restart)
- Restart Claude to load updated MCP servers
- Verify: `ToolSearch("codex-exec")`, `ToolSearch("ask-openai")`

---

## OpenAI models available on this account (live verified 2026-04-11)

Verified via `GET /v1/models` with production API key.

### Reasoning / o-series
- `o1`, `o1-mini`, `o1-pro`
- `o3`, `o3-mini`, `o3-pro`
- `o3-deep-research`, `o3-deep-research-2025-06-26`
- `o4-mini`, `o4-mini-deep-research`, `o4-mini-deep-research-2025-06-26`

### GPT-4.x
- `gpt-4.1`, `gpt-4.1-mini`, `gpt-4.1-nano` (+ dated `-2025-04-14` versions)

### GPT-4o variants
- `gpt-4o`, `gpt-4o-mini`
- `gpt-4o-search-preview`, `gpt-4o-mini-search-preview`
- `gpt-4o-audio-preview`, `gpt-4o-mini-audio-preview`
- `gpt-4o-realtime-preview`, `gpt-4o-mini-realtime-preview`
- `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`
- `gpt-4o-mini-tts`

### ❌ NOT available on API key
- `codex-mini-latest` — requires Codex CLI OAuth login (`codex login`), ChatGPT Plus account

---

## Why custom server (not mcp-openai package)
- `mcp-openai` v0.0.1 = 433 bytes, hardcodes gpt-4o-mini, no model selection
- Custom server: `z.string()` model param (any model), system prompt param, live model list

---

## Playwright MCP Fix (2026-04-11)

**Problem**: Playwright MCP defaults to Chrome stable distribution, binary at `/opt/google/chrome/chrome` — not present (Chrome Canary only).

**Fix**: Both config files updated to use Chrome Canary:
- `/home/rob/.claude/plugins/cache/claude-plugins-official/playwright/unknown/.mcp.json`
- `/home/rob/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json`

```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--browser", "chromium", "--headed", "--executable-path", "/usr/bin/google-chrome-canary"]
  }
}
```

**Chrome Canary real binary**: `/usr/bin/google-chrome-canary`  
**Wrapper** (stale-lock handler): `~/.local/bin/google-chrome-canary` → calls the real binary

**Future option**: Add `--user-data-dir /home/rob/.config/google-chrome-canary/Default` to reuse existing Chrome profile (logged-in sessions, no re-auth needed).

**Requires session restart** to take effect.
