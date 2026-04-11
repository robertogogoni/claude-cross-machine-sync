---
name: mcp CLI tool (mcptools)
description: Go binary for on-demand MCP server discovery and tool invocation — installed at ~/.local/bin/mcp
type: reference
originSessionId: ad53e300-2305-4932-b11b-1394b85ba9ec
---
## What it is

`mcp` CLI from [github.com/f/mcptools](https://github.com/f/mcptools) — lets you discover and invoke any MCP server without permanently registering it in `~/.claude.json`. Useful for exploration, one-off calls, and testing servers before committing.

## Installation

```bash
cd /tmp && git clone --depth 1 https://github.com/f/mcptools.git
cd mcptools && CGO_ENABLED=0 go build -o ~/.local/bin/mcp ./cmd/mcptools
```

**Requires Go** (`go version go1.26.2` installed at `/usr/bin/go`). Built 2026-04-11.

## Key commands

```bash
# Discover tools on any MCP server
mcp tools <server-command>
mcp tools --format json <server-command>    # full schema with param types

# Call a tool
mcp call <tool_name> --params '<json>' <server-command>
mcp call <tool_name> --params '<json>' -f json <server-command>   # JSON output

# Persistent aliases for repeated use
mcp alias add <name> <server-command>
mcp alias remove <name>
mcp alias list

# Interactive shell
mcp shell <server-command>

# Web UI (browser-based)
mcp web <server-command>
```

## Example: discover codex tools

```bash
mcp tools codex mcp-server
# → codex(prompt:str, [model:str], [cwd:str], ...)
# → codex-reply(prompt:str, [conversationId:str], [threadId:str])
```

## Output format flags

| Flag | Output |
|------|--------|
| (none) | table — human readable |
| `-f json` | raw JSON |
| `-f pretty` | indented JSON |

## Parameter type notation in table output

- `param:str` = string (required)
- `[param:str]` = string (optional)
- `param:obj` = object
- `param:str[]` = array of strings
