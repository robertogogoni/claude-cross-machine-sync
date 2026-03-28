---
name: Sync daemon audit 2026-03-19
description: Two sync daemons exist (omarchy + platform), neither running on Samsung, platform daemon has hostname bug, omarchy daemon never installed
type: project
---

## Two Daemons, Different Purposes

1. **Omarchy daemon** (`omarchy/omarchy-sync-daemon.sh`): Watches ~/.config/hypr, waybar, terminals. Syncs user desktop configs to git. Uses inotifywait + 5min pull cycle. Designed for Hyprland machines.

2. **Platform daemon** (`platform/linux/scripts/sync-daemon.sh`): Watches entire repo (machines/, platform/, universal/, docs/). General-purpose machine state sync. 667 lines, sophisticated retry/offline queue/conflict handling.

## Critical Bugs Found

**Platform daemon hostname bug (line 327):** Checks `machines/$HOSTNAME/` but Samsung hostname is "samsung-omarchy" while directory is `machines/samsung-laptop/`. Auto-conflict-resolution never triggers. Needs registry lookup instead of raw hostname.

**Neither daemon is installed on Samsung.** Only omarchy-battery-monitor.timer and claude-desktop-update.timer exist. No omarchy-sync.service, no machine-sync.service.

## Current Samsung State

- inotify-tools: installed (ready for daemon)
- omarchy/setup.sh: never run on Samsung
- Systemd user services: only battery-monitor + claude-desktop-update
- Manual sync only (git add/commit/push)

## Architecture Decision Needed

For Omarchy/Hyprland machines (Samsung, MacBook): run omarchy daemon (watches ~/.config/).
Platform daemon is better suited for repo-level watches but has bugs.
Both could coexist but serve different directions (system→repo vs repo→system).

**Why:** Config drift accumulated for 2.5 months because no daemon was auto-syncing Samsung configs.

**How to apply:** Install omarchy daemon on Samsung via setup.sh. Fix platform daemon hostname bug before using it. Both daemons should be installable, but omarchy daemon is the priority for Hyprland machines.
