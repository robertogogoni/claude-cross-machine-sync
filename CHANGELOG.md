# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- `[machine:samsung-laptop]` Telegram Desktop setup: telegram-desktop-bin 6.6.2, qt6-imageformats, hunspell-en_us, hunspell-pt-br
- `[machine:samsung-laptop]` Custom .desktop launcher with QT_SCALE_FACTOR=0.8 for static Qt binary scaling
- `[machine:samsung-laptop]` Samsung omarchy config: monitors.conf, envs.conf, input.conf (BR ABNT2 keyboard)
- `[machine:samsung-laptop]` Samsung omarchy machine.yaml with display/GPU/input specs
- `[machine:samsung-laptop]` Updated system packages memory with Telegram section (2026-03-19)
- `[machine:samsung-laptop]` Synced all 6 machine-specific Hyprland configs (bindings, input, looknfeel, monitors, envs, autostart)
- `[machine:samsung-laptop]` Omarchy bindings.conf and looknfeel.conf synced to omarchy/machines/samsung-laptop/
- `[universal]` Deployed missing planner agent, eureka and think-harder commands to live system
- `[docs]` Omarchy sync status table added to README.md
- `[docs]` New learning: sync-daemon-architecture.md (daemon comparison, bugs, recommendations)
- `[machine:samsung-laptop]` Omarchy sync daemon installed and enabled via systemd (omarchy-sync.service)

### Changed
- `[machine:samsung-laptop]` machine.yaml: kernel updated to 6.19.8, added apps section (Telegram), bumped to v1.1
- `[machine:samsung-laptop]` hypr/envs.conf synced with current system state
- `[universal]` Desktop config template: sidebarMode corrected from "task" to "chat" to match live

### Fixed
- `[linux]` Platform daemon hostname bug: added registry lookup so conflict resolution matches `machines/samsung-laptop/` not `machines/samsung-omarchy/`
- `[docs]` CLAUDE.md: Samsung hostname corrected from "samsung-arch" to "omarchy", user from "TBD" to "robthepirate"
- `[docs]` CLAUDE.md: Samsung machine status updated from "Pending" to "Active"
- `[docs]` SETUP.md: Machine comparison table fully updated with current status for all 3 machines
- `[docs]` README.md: Commit count and Samsung config count updated
- `[docs]` Design doc (2026-01-23): Stale hostname "samsung-arch" replaced with "omarchy"

---

## [1.0.0] - 2026-03-18 — Full Ecosystem

The repo graduates from a sync tool to a complete Claude Code ecosystem manager. Samsung laptop fully onboarded, memory bridge built, comprehensive documentation layer added.

### Added
- `[machine:samsung-laptop]` Samsung 270E5J fully registered with 10 config files, 4 memories
- `[universal]` 3 skills (debugging, code-review, testing), 3 agents, 4 commands deployed to universal/
- `[universal]` Memory-sync MCP server bridging CLI memories to Claude Desktop (`get_user_profile`, `sync_memories` tools)
- `[universal]` Claude Desktop config template with `${HOME}` and `${BRAVE_API_KEY}` placeholders
- `[universal]` Bootstrap steps 5a-5i: deploy skills, agents, commands, scripts, machine detection, memory (3-layer merge), MCP servers, platform scripts, Desktop config
- `[universal]` 11 Mermaid diagram sets (30+ charts): ecosystem map, memory architecture, MCP topology, chrome extension bridge, hooks lifecycle, repo structure, knowledge graph, AI history, multi-machine state, hookify rules, full repo map
- `[universal]` INSIGHTS.md: 12 rationale documents explaining WHY behind every major decision
- `[universal]` RUNBOOK.md: 15 troubleshooting scenarios with copy-paste diagnosis and fix commands
- `[universal]` INDEX.md: "I need to..." quick-start navigation linking all docs
- `[universal]` 8 Architecture Decision Records
- `[universal]` Tools inventory, backup strategy with rsync script, restore procedures
- `[universal]` `claude-health` script: 14 system health indicators with color-coded output
- `[universal]` `claude-backup` script: rsync-based, 7-day rotation
- `[linux]` Claude Desktop auto-updater script + systemd timer/service
- `[linux]` 3 platform memories (Chrome Canary, Claude Desktop, system packages)
- `[universal]` 6 new learnings: chrome-performance-tuning, claude-desktop-linux, memory-sync-bridge, native-messaging-chrome-canary, system-diagnostics-patterns, custom-instructions-optimization

### Changed
- `[universal]` README.md completely rewritten to reflect full repo scope
- `[universal]` CHANGELOG.md rewritten with semantic versioning and release tags
- `[universal]` Updated: electron-wayland, chrome-extension-troubleshooting, code-reviewer agent, electron-flags.conf, .gitignore
- `[machine:samsung-laptop]` registry.yaml fixed: hostname, user, status, hardware specs

---

## [0.10.0] - 2026-03-17 — CI/CD

### Added
- Claude Code Review GitHub Action workflow
- Claude PR Assistant workflow

---

## [0.9.0] - 2026-02-25 — Cedilla & Design Docs

### Added
- `[machine:macbook-air][universal]` Wayland cedilla fix configuration
- `[docs]` Wayland-cedilla-fix design and implementation plan
- Design docs: skill activator v4, unified Cortex vector DB, Beeper Extended v2, Beeper knowledge base

---

## [0.8.0] - 2026-02-02 — Public Release

### Added
- `[docs]` Professional README with badges, progress bars, collapsible sections
- Logo and banner SVG assets
- Architecture diagram (tree-style layout)

---

## [0.7.0] - 2026-02-02 — Production Architecture

### Added
- `[linux]` Production-ready v1.0 architecture
- `[universal]` Validator library (`lib/validator.sh`): pre-flight checks
- `[universal]` Rollback library (`lib/rollback.sh`): snapshot/restore
- Beeper package conflict fix documentation
- GitHub profile widgets troubleshooting

---

## [0.6.0] - 2026-01-24 — CLI Intelligence

### Added
- `[universal]` CLI Intelligence Engine (Phases 1-3): AI-powered skill activation, intent detection, caching
- `[universal]` SuperNavigator 6.1.0 enhancement plan
- `[universal]` GitHub Actions workflows
- `[universal]` Beeper Scout learnings (Matrix API adapter)

---

## [0.5.0] - 2026-01-22 — One-Command Bootstrap

### Added
- `bootstrap.sh`: one-command setup with hardware detection
- Auto-sync daemon (inotifywait + systemd / FileSystemWatcher + Task Scheduler)
- Omarchy config sync with automatic machine categorization
- Bidirectional sync support

---

## [0.4.0] - 2026-01-23 — Auto-Categorization

### Added
- `[universal]` Machine sync auto-categorization system v2.0
- Three-tier classification: universal / platform / machine
- Episodic memory summaries from multiple machines
- Community Claude Code configurations
- `[windows]` Sync daemon fixes

---

## [0.3.0] - 2026-01-18 — Skill Enforcement

### Added
- `[universal]` 5 hookify rules: brainstorming, writing-plans, tdd, systematic-debugging, subagent-development
- Connections registry
- Personal communication patterns

---

## [0.2.0] - 2026-01-17 — Multi-Machine Foundation

### Added
- Comprehensive cross-machine sync (MacBook Air + Windows Desktop)
- Windows setup guide
- Warp AI history extraction: 1,708 queries + 49 agent conversations
- Antigravity/Gemini Brain: 14 sessions
- Claude Code episodic memory archive (128MB)
- 10 initial learnings
- Chrome extension troubleshooting

---

## [0.1.0] - 2026-01-06 — Initial Setup

### Added
- Initial repository structure
- MacBook Air machine registration
- Basic settings and skills sync

---

[1.0.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.10.0...v1.0.0
[0.10.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/robertogogoni/claude-cross-machine-sync/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/robertogogoni/claude-cross-machine-sync/releases/tag/v0.1.0
