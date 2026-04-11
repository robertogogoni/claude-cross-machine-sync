---
name: OpenAI Codex CLI — capabilities, MCP integration, auth
description: Codex CLI v0.120.0 at ~/.local/bin/codex — native MCP server, non-interactive exec, code review, own memory/skills system
type: reference
originSessionId: ad53e300-2305-4932-b11b-1394b85ba9ec
---
## Install location

- Binary: `/home/rob/.local/bin/codex` (v0.120.0)
- Config dir: `~/.codex/` — contains `memories/`, `skills/`, `tmp/`
  - `~/.codex/config.toml` does NOT exist — using defaults
  - **Codex has its own memory and skills system** at `~/.codex/{memories,skills}/`

## Authentication

Two auth modes (independent):

| Mode | How | Status |
|------|-----|--------|
| API key | `OPENAI_API_KEY` env var | ✅ Active (key in `~/.bashrc` and MCP server env) |
| OAuth login | `codex login` (ChatGPT Plus / OpenAI account) | ❌ Not logged in |

`codex login status` shows "Not logged in" — that's the OAuth flow. API key auth works fine for all models.

## Key subcommands

```bash
codex mcp-server              # Start as MCP stdio server (native)
codex exec [PROMPT]           # Non-interactive agent run
codex exec review             # Code review (git repo, non-interactive)
codex [PROMPT]                # Interactive TUI session
codex resume                  # Resume previous interactive session
codex apply                   # Apply latest diff as git apply
codex cloud                   # Browse Codex Cloud tasks
```

## Non-interactive exec flags (most useful for MCP)

```bash
codex exec "fix the bug" \
  -m o3 \                           # Model (o3, o4-mini, gpt-4o, etc.)
  -C /path/to/repo \                # Working directory
  -s workspace-write \              # Sandbox: read-only | workspace-write | danger-full-access
  -a never \                        # Approval policy: never | untrusted | on-request
  --ephemeral \                     # Don't persist session files to ~/.codex/
  -o /tmp/output.txt \              # Write last agent message to file (clean extraction)
  --json                            # Print all events as JSONL (alternative to -o)
```

**Design note**: Use `-o <file>` over `--json` for MCP wrappers — cleaner single output vs parsing JSONL stream.

## Sandbox modes

| Mode | What agent can do |
|------|-------------------|
| `read-only` | Read files only, no shell writes |
| `workspace-write` | Edit files in working dir |
| `danger-full-access` | Unrestricted shell access |

## Native MCP server tools

`codex mcp-server` exposes:

| Tool | Params | Purpose |
|------|--------|---------|
| `codex` | `prompt:str, [model:str], [cwd:str], [sandbox:str], [approval-policy:str], [config:obj], ...` | Start new Codex session |
| `codex-reply` | `prompt:str, [conversationId:str], [threadId:str]` | Continue existing session |

`codex-reply` enables multi-turn conversations — save the `conversationId` from first call and pass it back.

## Custom MCP wrapper (codex-exec)

`~/.claude/mcp/codex/server.mjs` — wraps non-interactive exec for Claude:

| Tool | Purpose |
|------|---------|
| `codex-exec(prompt, model?, cwd?, sandbox?)` | One-shot non-interactive agent call |
| `codex-review(cwd, model?)` | Code review on git repo at cwd |

Registered in `~/.claude.json` as `"codex-exec"` server.

## MCP registration in ~/.claude.json

```json
"codex": {
  "command": "/home/rob/.local/bin/codex",
  "args": ["mcp-server"],
  "env": { "OPENAI_API_KEY": "sk-proj-..." }
},
"codex-exec": {
  "command": "node",
  "args": ["/home/rob/.claude/mcp/codex/server.mjs"],
  "env": { "OPENAI_API_KEY": "sk-proj-..." }
}
```

Both registered 2026-04-11. Requires session restart to activate.
After restart: verify with `ToolSearch("codex-exec")` and `ToolSearch("codex-review")`.

## settings.json allow list additions

```
"mcp__openai__*"
"mcp__codex__*"
"mcp__codex-exec__*"
```
