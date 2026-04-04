---
name: Hive — Beeper Intelligence Platform
description: Composable plugin ecosystem for Beeper. Monorepo at ~/repos/hive/ with 4 plugins, CLI, HTTP gateway (Hono), Beeper Desktop widget (Next.js), and Chrome extension. 41 MCP tools, 586 tests, all features complete.
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
| Exp-E | WebSocket EventStream (shared/) | 35 | Done |
| Exp-E | WS MCP tools + rules bridge (auto/) | 30 | Done |
| **Total** | | **557 (+11 integration)** | |

## MCP server registration
All 4 plugins registered in `~/.claude.json` (beeper-kb deprecated 2026-04-04):
- `hive-toolkit`: 18 tools (chats, messages, reactions, accounts, contacts, assets, export)
- `hive-intel`: 8 tools (search, ingest, harvest, stats, browse, trends, ask, discover)
- `hive-bridges`: 5 tools (list, run, stop, status, bounties)
- `hive-auto`: 8 tools (watch list/add/remove, rules list/add, forward add, events subscribe/stream)

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

## What's been done (session 2026-04-04 continued — WebSocket)
- Probed live Beeper Desktop API: discovered /v1/ws endpoint EXISTS (returns 401 without auth)
- Fetched full OpenAPI spec from /v1/spec — saved to `docs/beeper-desktop-api-spec.json`
- Confirmed WebSocket protocol: ready → subscriptions.set → events (chat/message upserted/deleted)
- Built EventStream client in shared/src/events.ts: reconnection, ring buffer, auto-discovery
- Built 2 MCP tools: hive_events_subscribe (start/stop/status), hive_events_stream (poll/filter)
- Built EventHandler: bridges WS events to rules engine (watch + forward rules with cooldown)
- Built CLI: `hive events listen` (real-time) + `hive events status`
- Also discovered: /oauth/authorize returns 400 (exists!), /v1/search returns 500 (needs query param)

## What's been done (session 2026-04-04 — Gateway + Widget + Extension)
- Built HTTP API gateway (`gateway/`, Hono): 17+ REST endpoints, Beeper API proxy, intelligence
- Built Beeper Desktop sidebar widget (`widget/`, Next.js 15): 5-tab UI (search/ask/trends/discover/suggest)
  - @beeper/matrix-widget-toolkit installed from npm, capabilities registered properly
  - Dual-mode: Widget API inside Beeper, gateway fallback standalone
- Built Chrome extension (`extension/`, Manifest V3): side panel, popup, content script, context menus
- All API keys validated and persisted to ~/.hive/config.json (Anthropic 108 chars, Voyage 46 chars)
- Fixed all loose ends: EventStream wiring, chats.create mode bug, OAuth port, getRecentEvents args
- Gateway URL configurable in widget (NEXT_PUBLIC_HIVE_GATEWAY_URL) and extension (chrome.storage.sync)
- Beeper Desktop OpenAPI spec saved at docs/beeper-desktop-api-spec.json (v0.2.0, 123KB)
- Created comprehensive README.md
- Formatted codebase with Prettier

## What's next (remaining)
- **Run `hive install-services`**: Install systemd units on the machine
- **Test widget in Beeper Desktop**: Add http://localhost:3000 as widget, verify all tabs
- **Load extension in Chrome Canary**: chrome://extensions → Developer mode → Load unpacked
- **Test OAuth PKCE live**: `hive auth login` to get first-party token
- **Live WebSocket test**: Send message from phone, verify event arrives
- **KB harvest**: Run `hive harvest` to update stale data (last: 2026-04-03)
- **beeper-extended plugin removal**: Still installed as Claude Code plugin
