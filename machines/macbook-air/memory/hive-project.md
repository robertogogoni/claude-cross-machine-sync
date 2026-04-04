---
name: Hive — Beeper Intelligence Platform
description: Composable plugin ecosystem and CLI for Beeper. Monorepo at ~/repos/hive/ with 4 plugins (toolkit, intel, bridges, auto) + CLI + copilot skill. All 5 phases complete, 344 tests, pushed to GitHub.
type: project
---

Hive is a composable plugin ecosystem and CLI for Beeper — transforms the Desktop API into a personal AI-powered messaging copilot.

**Why:** beeper-extended has only 11 basic MCP tools, no intelligence, no KB integration, hardcoded port 23373. Hive replaces it with 34 MCP tools, semantic search, automation, bridge management, and a copilot.

**How to apply:** When working on Beeper projects, use Hive as the primary interface. The `hive` command is globally installed.

## Architecture

```
hive/ (monorepo, npm workspaces)
├── cli/              @hive/cli — 12 commands, branded UI
├── shared/           @hive/shared — typed API client, auth, pagination, dedup
├── plugins/
│   ├── toolkit/      @hive/toolkit — 18 MCP tools (full Beeper API)
│   ├── intel/        @hive/intel — KB + harvesting (migrated from beeper-kb)
│   ├── bridges/      @hive/bridges — bbctl wrapper (5 tools, 16 bridges)
│   └── auto/         @hive/auto — monitors, rules, systemd (6 tools)
├── skills/copilot/   Claude Code skill (orchestrates all 34 tools)
└── tests/integration/ Live API tests (gated behind HIVE_INTEGRATION=1)
```

## Key locations
- **Repo**: `~/repos/hive/` | GitHub: `robertogogoni/hive` (private)
- **Design spec**: `~/repos/beeper-kb/docs/superpowers/specs/2026-04-03-hive-design.md`
- **Phase 1 plan**: `~/repos/hive/docs/superpowers/plans/2026-04-03-phase-1-shared-toolkit-cli.md`
- **Data dir**: `~/.hive/` (intel data, auto rules, exports, downloads)
- **Binary**: `hive` globally linked via npm

## Build status (all phases complete)

| Phase | Package | Tests | Status |
|-------|---------|:---:|:---:|
| 1A | shared/ foundation (8 modules) | 96 | Done |
| 1B | shared/client (HiveClient) | 22 | Done |
| 1C | toolkit/ (18 MCP tools) | 38 | Done |
| 1D | cli/ (12 commands) | 27 | Done |
| 1E | integration tests | 11 | Done (live verified) |
| 2 | intel/ (KB + search) | 31 | Done |
| 3 | bridges/ (bbctl, 16 bridges) | 58 | Done |
| 4 | auto/ (rules, systemd) | 72 | Done |
| 5 | copilot skill | — | Done (SKILL.md) |
| **Total** | | **344 (+11 integration)** | |

## MCP server registration
All 4 plugins registered in `~/.claude.json`:
- `hive-toolkit`: 18 tools (chats, messages, reactions, accounts, contacts, assets, export)
- `hive-intel`: 5 tools (search, ingest, harvest, stats, browse)
- `hive-bridges`: 5 tools (list, run, stop, status, bounties)
- `hive-auto`: 6 tools (watch list/add/remove, rules list/add, forward add)

## Key decisions
- Monorepo with npm workspaces (not Turborepo, not pnpm)
- `workspace:*` protocol replaced with `"*"` for npm compat
- Cursor pagination (not before — before returns same page)
- Always use Voyage AI embeddings (paid tier: 32/batch, 200ms)
- Content-hash dedup (INSERT OR IGNORE, not REPLACE)
- Auto-discover port (ss) and Voyage key (~/.claude.json)
- Beeper port: 23374 (not 23373)
- No `/v1/server` endpoint — info() derives from accounts
- Contacts API returns `{ items: [...] }` not raw array
- Account ID field is `accountID` (not `id`)
- `encodeRoomId` uses explicit replace (not encodeURIComponent — `!` is unreserved)
- beeper-kb migrated via symlink: ~/.hive/intel → ~/.beeper-kb
