---
name: claude-sync public distribution plan
description: Research-backed positioning and feature plan for distributing claude-cross-machine-sync publicly as "claude-sync"
type: project
---

## Public Distribution Plan (researched 2026-03-29)

**Proposed name**: `claude-sync`
**Tagline**: "One brain across all your machines"
**Source repo**: `~/claude-cross-machine-sync` (personal, 148 commits, 2016 files)
**Target**: New clean repo `robertogogoni/claude-sync` (public distributable)

## Competitive Landscape (40+ projects analyzed)

Direct competitors: perfectra1n/claude-code-sync (40 stars, Rust, conversations only), mariopaglia/claude-config-sync (9 stars, Gists), FelixIsaac/claude-code-sync (5 stars, Go, age encryption). Memory giants: claude-mem (44.6k stars, single-machine), mem0 (51.8k stars, cloud SaaS).

**Our unique position**: Only project combining settings + memory + conversations + skills + machine profiles + background daemons + cortex bridge + waybar dashboard.

## Official Claude Code Status (as of 2026-03-29)

- Auto memory is explicitly "machine-local" (no cross-machine)
- Zero Anthropic responses to 6+ sync feature requests over months
- `autoMemoryDirectory` setting (v2.1.74+) can redirect memory to custom path (KEY DISCOVERY: no competitor uses this)
- 26 hook event types, statusLine API, plugin marketplace all exist but are local-only
- Anthropic priorities: Agent Teams, Computer Use, Cowork, plugins. NOT sync.

## Unique Value Props for v1.0 (build order)

1. `autoMemoryDirectory` integration (Claude Code writes directly into sync repo)
2. Full-stack sync (settings + memory + skills + agents + commands + conversations)
3. Background daemons (systemd + Task Scheduler + inotifywait)
4. Machine hardware profiles with auto-detection
5. Cortex bridge (LLM insight extraction fed into sync)
6. Waybar dashboard with knowledge inventory + sparklines
7. Encryption at rest (age or GPG for sensitive files)
8. Go Charm CLI installer (like aifuel)
9. Proper CLI (`claude-sync push/pull/status/diff/machines`)

## Gaps to Close vs Competitors

- Encryption: FelixIsaac uses age, btafoya uses AES-256 (they call us out)
- Polished CLI: mariopaglia has npm push/pull/status
- README quality: competitors have better-polished READMEs
- Conversation sync: perfectra1n has TUI conflict resolution in Rust

## Resume Point

After system update, resume building the public distribution starting from the 9 unique value props above.

**How to apply:** When user asks to continue claude-sync work, start from the value props list and begin extracting the framework into a clean distributable repo.
