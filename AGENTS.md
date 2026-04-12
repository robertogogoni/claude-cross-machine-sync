# Claude Cross-Machine Sync - Agents Guide

**Purpose**: Help AI agents understand the cross-machine sync architecture and avoid mistakes.

## Architecture Overview

This repository syncs Claude Code configuration across 3 machines:

| Machine | Hostname | Platform | Status |
|---------|----------|----------|--------|
| Dell G15 5530 | Rob-Dell | Windows 11 | ✅ Active |
| MacBook Air | macbook-air | Arch Linux | ✅ Active |
| Samsung 270E5J | omarchy | Arch Linux | ✅ Active |

## Directory Structure

```
~/claude-cross-machine-sync/
├── machines/              # Machine-specific configs (registry.yaml, machine.yaml)
├── platform/              # OS-level configs (windows/, linux/)
├── universal/             # Cross-platform configs
│   └── claude/
│       ├── settings.json  # Shared Claude settings
│       └── memory/        # Cortex memory exports (knowledge-graph.jsonl, patterns.json)
├── skills/                # Custom Claude Code skills
├── episodic-memory/       # Conversation archive (Git LFS)
├── warp-ai/               # Warp Terminal AI history (1,708 queries, 49 agents)
├── learnings/             # AI-generated knowledge
└── docs/                  # Documentation and plans
```

## Critical Commands

```bash
# Linux systemd sync daemon
./platform/linux/scripts/sync-daemon.sh --status
./platform/linux/scripts/sync-daemon.sh --install

# Windows Task Scheduler sync daemon
.\platform\windows\scripts\sync-daemon.ps1 -Mode Status
.\platform\windows\scripts\sync-daemon.ps1 -Mode Install

# Manual sync
git add . && git commit -m "[universal] Description" && git push
```

## Commit Tag Conventions

| Tag | Meaning | Example |
|-----|------------------|
| `[universal]` | Works on all machines | Settings, shared configs |
| `[linux]` | Linux-specific | Bash scripts, systemd, Hyprland |
| `[windows]` | Windows-specific | PowerShell scripts, .ps1 files |
| `[machine:hostname]` | Specific machine only | GPU tweaks, monitor layout |

## Memory Persistence Stack

The universal memory layer integrates:

1. **Cortex MCP** (`@modelcontextprotocol/server-memory`) - Knowledge graph
2. **Claudeception** - Auto-skill extraction
3. **claude-mem** - Session capture
4. **Custom hooks** - SessionEnd extraction to CLAUDE.md

**Paths**:
- Knowledge graph: `universal/claude/memory/knowledge-graph.jsonl`
- Patterns: `universal/claude/memory/patterns.json`
- Observations: `universal/claude/memory/tool-observations.jsonl`

## Common Pitfalls

1. **Git LFS required** for episodic-memory (128MB JSONL files)
2. **Don't commit `.claude.json`** - Machine-specific, use universal configs
3. **Sync daemon debouncing** - 2s delay prevents git race conditions
4. **Hook paths use `~`** - Always expand with `expandPath()` or use absolute

## Hooks Architecture

```
~/.claude/hooks/
├── skill-activator.js      # UserPromptSubmit - AI intent detection
├── session-memory-capture.js # SessionEnd - CLAUDE.md updates
└── tool-output-capture.js   # PostToolUse - Tool observation logging
```

## Testing Quirks

- Always run `git lfs pull` after clone
- Check daemon status before debugging sync issues
- Episodic memory requires plugin: `/plugin list`

## Files That Matter Most

| File | Why Read It |
|------|-------------|
| `CLAUDE.md` | Project memory and session history |
| `machines/registry.yaml` | Machine ecosystem definition |
| `universal/claude/settings.json` | Shared Claude configuration |
| `docs/plans/*.md` | Design documents for implemented features |
## MANDATORY INSTRUCTIONS (FOR CLAUDE, GEMINI, AND ALL AGENTS)
1. NEVER write placeholder code, stubs, or mock implementations.
2. If a feature requires an external dependency, install it and write the actual execution logic.
3. Every script must contain 100% production-ready, fully functional code.

## STRICT ANTI-PATTERNS (ZERO TOLERANCE FOR ANY AI)
- No simulation
- No faking
- No generic implementations
- No placeholders
- No stubs
- No 'fast coding' just to deliver quickly
- Every line of code MUST mean a feature fully shipped to production standard.
