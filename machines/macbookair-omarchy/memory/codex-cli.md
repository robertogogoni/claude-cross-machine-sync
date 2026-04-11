---
name: OpenAI Codex CLI — capabilities, MCP integration, auth, feature flags
description: Codex CLI v0.120.0 — corrected exec flags, new flags, feature flags, OAuth vs API key models, MCP server tools, local model support
type: reference
originSessionId: ad53e300-2305-4932-b11b-1394b85ba9ec
---

## Install location

- Binary: `/home/rob/.local/bin/codex` (v0.120.0)
- Config dir: `~/.codex/` — contains `memories/`, `skills/`, `tmp/`
  - `~/.codex/config.toml` does NOT exist — using built-in defaults
  - **Codex has its own memory and skills system** at `~/.codex/{memories,skills}/`

## Authentication

Two auth modes (independent):

| Mode | How | Status |
|------|-----|--------|
| API key | `OPENAI_API_KEY` env var | ✅ Active (key in `~/.bashrc` and MCP server env) |
| OAuth login | `codex login` (ChatGPT Plus / OpenAI account) | ❌ Not logged in |

**Critical**: `codex-mini-latest` is ONLY accessible via OAuth login. API key returns "model does not exist".  
Run `codex login` to unlock it.

## Key subcommands

```bash
codex mcp-server              # Start as MCP stdio server (native)
codex exec [PROMPT]           # Non-interactive agent run
codex exec review             # Code review (git repo, non-interactive)
codex [PROMPT]                # Interactive TUI session
codex resume                  # Resume previous interactive session
codex fork                    # Fork a previous interactive session
codex apply                   # Apply latest diff as git apply
codex cloud                   # Browse Codex Cloud tasks
codex features list           # List all feature flags and their states
```

## Non-interactive exec flags (corrected for v0.120.0)

```bash
codex exec "fix the bug" \
  -m o3 \                                    # Model
  -C /path/to/repo \                         # Working directory
  -s workspace-write \                       # Sandbox (ignored if --dangerously-bypass used)
  --dangerously-bypass-approvals-and-sandbox \ # Skip ALL approvals + sandbox (use instead of -a)
  -p fast \                                  # Config profile from ~/.codex/config.toml
  --oss --local-provider lmstudio \          # Use local model (LM Studio or Ollama)
  --ephemeral \                              # Don't persist session files to ~/.codex/
  --skip-git-repo-check \                    # Allow running outside git repos
  --add-dir /extra/writable/path \           # Extra writable directories
  --output-schema /path/schema.json \        # Constrain output to JSON schema
  --full-auto \                              # Alias for --sandbox workspace-write
  -o /tmp/output.txt \                       # Write last agent message to file (cleanest)
  --json                                     # Print all events as JSONL (alternative to -o)
```

### ⚠️ INVALID FLAG (DO NOT USE)
`-a never` — **does not exist in v0.120.0**. Was in older MCP server implementation as a bug. Removed 2026-04-11.

### Approval bypass
`--dangerously-bypass-approvals-and-sandbox` skips ALL confirmation prompts AND overrides the `-s` sandbox policy.  
When used, `-s` is irrelevant. This is the correct flag for non-interactive MCP use.

**Design note**: Use `-o <file>` over `--json` — cleaner single output vs parsing JSONL stream.

## Sandbox modes (when NOT using bypass)

| Mode | What agent can do |
|------|-------------------|
| `read-only` | Read files only, no shell writes |
| `workspace-write` | Edit files in working dir |
| `danger-full-access` | Unrestricted shell access |

## Local model support (OSS providers)

```bash
# LM Studio
codex exec "prompt" --oss --local-provider lmstudio -m <local-model-name>

# Ollama
codex exec "prompt" --oss --local-provider ollama -m llama3
```
No API cost. Requires local server running at default ports.

## Feature flags (from `codex features list`, 2026-04-11)

| Feature | Stage | Default | Notes |
|---------|-------|---------|-------|
| `multi_agent` | stable | true | Multi-agent coordination |
| `fast_mode` | stable | true | Speed optimization |
| `plugins` | stable | true | Plugin system |
| `shell_snapshot` | stable | true | Shell state snapshots |
| `tool_suggest` | stable | true | Tool suggestions |
| `skill_mcp_dependency_install` | stable | true | Auto-install MCP deps |
| `unified_exec` | stable | true | Unified exec pipeline |
| `apps` | stable | true | App support |
| `undo` | stable | **false** | Undo last action (disabled by default!) |
| `js_repl` | experimental | false | JavaScript REPL tool |
| `guardian_approval` | experimental | false | Approval gating |
| `image_detail_original` | experimental | false | Full-res image detail |
| `prevent_idle_sleep` | experimental | false | Prevent system sleep |
| `memories` | under development | false | Codex own memory system |
| `multi_agent_v2` | under development | false | Next-gen multi-agent |
| `codex_git_commit` | under development | false | Auto git commits |
| `codex_hooks` | under development | false | Lifecycle hooks |
| `image_generation` | under development | false | Image gen tool |
| `tool_search` | under development | false | Tool discovery |
| `realtime_conversation` | under development | false | Realtime mode |
| `exec_permission_approvals` | under development | false | Per-command approval |
| `js_repl_tools_only` | under development | false | REPL without full shell |

Enable with: `codex --enable <feature>` or `codex features enable <feature>`

## Native MCP server tools (`codex mcp-server`)

| Tool | Params | Purpose |
|------|--------|---------|
| `codex` | `prompt:str, [model:str], [cwd:str], [sandbox:str], [config:obj]` | Start new Codex session |
| `codex-reply` | `prompt:str, [conversationId:str], [threadId:str]` | Continue existing session |

`codex-reply` enables multi-turn — save `conversationId` from first call.

## Custom MCP wrapper (`codex-exec` server at `~/.claude/mcp/codex/server.mjs`)

| Tool | Params | Purpose |
|------|--------|---------|
| `codex-exec` | prompt, model?, cwd?, sandbox?, provider?, profile?, bypass_approvals? | One-shot non-interactive |
| `codex-review` | cwd, model?, provider?, profile?, bypass_approvals? | Code review on git repo |

**Defaults**: `sandbox=workspace-write`, `provider=openai`, `bypass_approvals=true`  
When `bypass_approvals=true`, adds `--dangerously-bypass-approvals-and-sandbox` (overrides sandbox).  
When `provider=lmstudio` or `ollama`, adds `--oss --local-provider <name>`.

## MCP registration in `~/.claude.json`

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

## `settings.json` allow list

```
"mcp__openai__*"
"mcp__codex__*"
"mcp__codex-exec__*"
```
