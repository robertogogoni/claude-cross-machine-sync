---
name: Hive — Beeper Intelligence Platform
description: Composable plugin ecosystem and CLI for Beeper. Monorepo at ~/repos/hive/ with 4 plugins (toolkit, intel, bridges, auto) + CLI + copilot skill. All phases complete + experimental features (trends, ask, discover, OAuth). 492 tests, pushed to GitHub.
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

## Build status (all phases complete + experimental)

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
| DX | CI/CD + ESLint/Prettier | — | Done |
| DX | systemd install CLI | 12 | Done |
| DX | dashboard CLI | 7 | Done |
| Exp-B | hive_trends (SQL analytics) | 38 | Done |
| Exp-C | hive_ask (RAG + citations) | 32 | Done |
| Exp-A | OAuth 2.0 + PKCE | 38 | Done |
| Exp-D | hive_discover (AI insights) | 21 | Done |
| **Total** | | **492 (+11 integration)** | |

## MCP server registration
All 4 plugins registered in `~/.claude.json` (beeper-kb deprecated 2026-04-04):
- `hive-toolkit`: 18 tools (chats, messages, reactions, accounts, contacts, assets, export)
- `hive-intel`: 8 tools (search, ingest, harvest, stats, browse, trends, ask, discover)
- `hive-bridges`: 5 tools (list, run, stop, status, bounties)
- `hive-auto`: 6 tools (watch list/add/remove, rules list/add, forward add)

Note: hive_ask + hive_discover require ANTHROPIC_API_KEY (auto-discovered from env, ~/.hive/config.json, or ~/.claude.json).

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

## What's been done (session 2026-04-03/04)
- Built entire Hive platform from zero: scaffold → 5 phases → live integration tests
- 12 git commits, 65 source files, 44 test files, ~10,500 lines of TypeScript
- `hive` CLI globally installed and working (`hive doctor` shows all 5 checks PASS)
- 4 MCP servers registered in ~/.claude.json (restart Claude Code to activate)
- Integration tests verified against live Beeper Desktop on port 23374
- Copilot skill written at skills/copilot/SKILL.md

## What's been done (session 2026-04-04 continued)
- CI/CD: GitHub Actions workflow (Node 22/24 matrix, typecheck + vitest)
- ESLint v9 flat config + Prettier (matching existing code style)
- `hive install-services` / `uninstall-services` / `services-status` CLI commands
- `hive dashboard` — local HTTP server with KB stats API proxy
- `hive trends` — SQL analytics (timeline, top authors, sources, spikes with z-score)
- `hive_ask` — RAG over KB with Anthropic Claude, citations, confidence scoring, caching
- `hive_discover` — AI-powered pattern discovery (topic clusters, knowledge gaps, notable authors)
- OAuth 2.0 + PKCE auth flow (browser-based, token refresh, secure storage)
- `hive auth login/logout/status/token` CLI commands
- beeper-kb MCP server deprecated (removed from ~/.claude.json)
- Experimental features design spec written

## What's next (remaining)
- **WebSocket events**: Live message monitoring via GET /v1/ws — needs endpoint discovery first (highest risk, undocumented). Design in `docs/superpowers/specs/2026-04-04-experimental-features-design.md` section 2.
- **Run `hive install-services`**: Actually install systemd units on the machine
- **Format codebase**: Run `npm run format` to apply Prettier to all files
- **beeper-extended plugin removal**: Still installed as a Claude Code plugin (not just MCP server)
- **Test OAuth against live Beeper**: Verify `/oauth/authorize` endpoint exists
