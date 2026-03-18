---
name: GitHub repo map
description: Key GitHub repos and their locations — personal (robertogogoni) and org (beeper-community)
type: reference
---

## Personal (robertogogoni)

| Repo | Purpose | Branch |
|------|---------|--------|
| `robertogogoni/robertogogoni` | Profile README with featured projects, badges, stats | main |
| `robertogogoni/cortex-claude` | Cortex memory system for Claude Code (v3.0.0, LADS) | master |
| `robertogogoni/claude-cross-machine-sync` | Cross-machine Claude Code settings sync | — |
| `robertogogoni/beeper-intel` | Intelligence dashboard for Beeper ecosystem | — |
| `robertogogoni/awesome-beeper` | Community docs for Beeper | — |
| `robertogogoni/wayland-cedilla-fix` | Fix ç on Wayland (AUR package) | — |
| `robertogogoni/datapub` | (private) Document analysis system | — |

## Organization (beeper-community)

| Repo | Purpose | Branch |
|------|---------|--------|
| `beeper-community/update-beeper` | Beeper Desktop updater (v1.8.1) | master |
| `beeper-community/beeper-pulse` | Monitoring suite + status page | main |
| `beeper-community/awesome-beeper` | Curated Beeper resources | — |
| `beeper-community/beeper-scout` | Ecosystem discovery tool | — |
| `beeper-community/.github` | Org profile README | main |

## Profile README Badges

The profile README (`robertogogoni/robertogogoni`) uses dynamic badges that auto-update:
- Release badge: pulls from GitHub Releases API
- Beeper Latest: pulls from `beeper-community/update-beeper/master/.github/badges/beeper-version.json`
- Test/Lint badges: pulls from GitHub Actions status
