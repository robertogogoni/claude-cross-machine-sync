---
name: Hive — Beeper Intelligence Platform
description: Composable plugin ecosystem and CLI for Beeper. Monorepo at ~/repos/hive/ with 5 plugins (toolkit, intel, bridges, auto) + CLI + copilot skill.
type: project
---

Hive is a composable plugin ecosystem and CLI for Beeper — transforms the Desktop API into a personal AI-powered messaging copilot.

**Why:** beeper-extended has only 11 basic MCP tools, no intelligence, no KB integration, hardcoded port 23373. Hive replaces it with 37+ MCP tools, semantic search, automation, bridge management, and a copilot.

**How to apply:** When working on Beeper projects, use Hive as the primary interface. The design spec is at `~/repos/beeper-kb/docs/superpowers/specs/2026-04-03-hive-design.md`.

## Architecture

```
hive/ (monorepo, npm workspaces)
├── cli/              @hive/cli — user entry point, 52+ commands
├── shared/           @hive/shared — typed API client, auth, pagination, dedup
├── plugins/
│   ├── toolkit/      @hive/toolkit — 18 MCP tools (full Beeper API)
│   ├── intel/        @hive/intel — KB + harvesting (evolves beeper-kb)
│   ├── bridges/      @hive/bridges — bbctl wrapper (5 tools)
│   └── auto/         @hive/auto — monitors, rules, systemd (6 tools)
└── skills/copilot/   Claude Code skill (capstone)
```

## Key locations
- **Repo**: `~/repos/hive/` | GitHub: `robertogogoni/hive` (to be created)
- **Design spec**: `~/repos/beeper-kb/docs/superpowers/specs/2026-04-03-hive-design.md`
- **Phase 1 plan**: `~/repos/hive/docs/superpowers/plans/2026-04-03-phase-1-shared-toolkit-cli.md`
- **Data dir**: `~/.hive/` (migrates from `~/.beeper-kb/`)

## 55 capabilities mapped
- 30 proven (API-confirmed)
- 15 experimental (WebSocket, agentremote)
- 10 ecosystem (absorb beepctl, beeper-cli, beepex, etc.)

## Build phases
1. shared/ + toolkit/ + cli/ core (foundation)
2. intel/ (migrate beeper-kb)
3. bridges/ + ecosystem integrations
4. auto/ + systemd + hooks
5. copilot skill + experimental

## Key decisions
- Monorepo with npm workspaces (not Turborepo)
- Cursor pagination (not before — before returns same page)
- Always use Voyage AI embeddings (paid tier: 32/batch, 200ms)
- Content-hash dedup (INSERT OR IGNORE, not REPLACE)
- Auto-discover port (ss) and Voyage key (~/.claude.json)
- Beeper port: 23374 (not 23373)
