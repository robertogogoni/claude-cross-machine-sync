# GitHub Repositories — robertogogoni

Last audited: 2026-03-10

## Repository Inventory

### Actively Maintained (public)

| Repo | Local Path | Description | Last Action |
|------|-----------|-------------|-------------|
| `cortex-claude` | `~/repos/cortex-claude/` | Memory system for Claude Code (MCP + hooks) | 3 commits pushed 2026-03-09 |
| `beeper-intel` | `~/repos/beeper-intel/` | Intelligence dashboard for Beeper ecosystem (160+ repos, 13k+ msgs) | Created + published 2026-03-10 |
| `wayland-cedilla-fix` | `~/wayland-cedilla-fix/` | Fix ç cedilla on Wayland (Hyprland, Sway, etc.) | AUR published + badge restored 2026-03-02 |
| `awesome-beeper` | `~/awesome-beeper/` | Community Beeper docs, changelogs, resources | Major restructure (30+ projects) 2026-03-10 |
| `claude-cross-machine-sync` | `~/claude-cross-machine-sync/` | Cross-machine Claude Code sync hub | Topics added 2026-03-09 |
| `update-beeper` | `~/repos/update-beeper/` | Self-healing Beeper updater for Linux | Nightly URL FAQ added 2026-03-10 |
| `robertogogoni` | `~/repos/robertogogoni/` | GitHub profile README with widgets | 4-project grid + beeper-intel 2026-03-10 |

### Actively Maintained (private)

| Repo | Local Path | Description | Last Action |
|------|-----------|-------------|-------------|
| `datapub` | `~/repos/datapub/` | Brazilian public document analysis platform | Topics added 2026-03-09 |
| `candle-craft-ux-vision` | — | Candle craft UX with Supabase backend | Description added 2026-03-09 |
| `chatgptbot` | `~/repos/chatgptbot/` | Fork of oceanlvr/ChatGPTBot (unmodified) | No changes needed |

### Other Repos (36 total on GitHub)
- Most are forks, references, or archived projects
- See `gh repo list robertogogoni --limit 50` for full list

## GitHub Profile Widgets

### Vercel-Hosted (include private repo data)

| Widget | Vercel URL | PAT Env Var |
|--------|-----------|-------------|
| github-readme-stats | `github-readme-stats-zeta-blush-29.vercel.app` | `PAT_1` |
| github-readme-activity-graph | `github-readme-activity-graph-sage.vercel.app` | `TOKEN` |

### Additional Self-Hosted Widgets

| Widget | Vercel URL | Status |
|--------|-----------|--------|
| github-profile-summary-cards | `github-profile-summary-cards-beige-alpha.vercel.app` | READY |
| github-readme-streak-stats | `github-readme-streak-stats-chi-brown.vercel.app` | READY (limited — PHP on Vercel) |
| github-trophies | `github-trophies-sandy.vercel.app` | READY (duplicate?) |
| github-profile-trophy | `github-profile-trophy-three-indol.vercel.app` | READY (duplicate?) |

### Public Instances

| Widget | URL | Notes |
|--------|-----|-------|
| streak-stats | `streak-stats.demolab.com` | PHP/Heroku, can't self-host on Vercel |

### GitHub Actions Workflows (robertogogoni/robertogogoni)

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| GitHub Metrics | cron + manual | SVG metrics, isocalendar, habits, languages, activity |
| Snake | cron + manual | Contribution snake animation SVG |
| README Stats | cron + manual | Commit-based readme stats |

**Cache busting**: Append `&cache_seconds=1800&t=<timestamp>` to widget URLs.

**Force refresh**: `gh workflow run <workflow>.yml -R robertogogoni/robertogogoni`

## GitHub Stats (2026-03-10)

| Metric | Value |
|--------|-------|
| Public repos | 7 |
| Private repos | 30 |
| Total repos | 37 |
| update-beeper description | "Self-healing Beeper Desktop updater for Linux with automatic rollback and Wayland desktop integration" |

## GitHub Topics (2026-03-10)

| Repo | Topics |
|------|--------|
| `cortex-claude` | ai, claude-code, cognitive-layer, cross-session, dual-model, hooks, llm, mcp, memory, persistent-memory |
| `beeper-intel` | beeper, intelligence, dashboard, matrix, mcp, bridges, api, community |
| `update-beeper` | appimage, arch-linux, aur, bash-script, beeper, beeper-desktop, electron, linux, messaging, self-healing, systemd, updater, wayland |
| `wayland-cedilla-fix` | arch-linux, brazilian-portuguese, cedilla, compose-key, dead-keys, fcitx5, hyprland, input-method, labwc, linux, portuguese, river, sway, us-international, wayland, wlroots, xcompose, c-cedilla |
| `awesome-beeper` | awesome-list, beeper, beeper-desktop, changelog, community, documentation, messaging, resources |
| `claude-cross-machine-sync` | ai, claude-code, cross-machine, dotfiles, linux, mcp, memory, settings, sync, windows |
| `datapub` | brazil, legislation, nlp, open-data, public-documents, python, web-scraping |

## Profile README Badges (2026-03-09)

### update-beeper section
- Release (dynamic from GitHub Releases API)
- Beeper Latest (custom endpoint badge from daily workflow)
- Lint (CI workflow status)
- License (MIT)

### awesome-beeper section
- Awesome (awesome.re badge)
- Last Commit (freshness)
- Stars (social proof)
- License (MIT)

### Tech Stack (12 badges)
Languages: TypeScript, JavaScript, Python, Bash, PowerShell
Infra: Node.js, SQLite, Docker, Git
Platform: Linux, Arch, Hyprland

## README Audit Findings (2026-03-02)

| Repo | Issue | Fix Applied |
|------|-------|-------------|
| cortex-claude | MCP tools count said 6, actually 7 | Fixed to 7, added cortex__health |
| cortex-claude | Test listing showed 7/22 suites | Listed all 22 suites |
| cortex-claude | Model names outdated | Updated to Haiku 4.5 / Sonnet 4.6 |
| wayland-cedilla-fix | AUR badge 404 (not published yet) | Replaced with release badge, then restored AUR badge after publish |
| awesome-beeper | TBD version placeholders | Removed, simplified status table |
| awesome-beeper | No mention of update-beeper | Added Tools section with 3 tools |
| datapub | `databub` typo in tree | Fixed to `datapub` |
| datapub | Tree showed README.rst only | Added README.md as primary |
| datapub | No entity code docs | Added entity codes table |
| chatgptbot | Upstream README, private fork | Skipped — no custom content |
