---
name: Sync daemon audit (updated 2026-04-04)
description: Omarchy sync daemon running on Samsung, platform daemon has hostname bug, cortex-to-learnings bridge active
type: project
---

## Two Daemons, Different Purposes

1. **Omarchy daemon** (`omarchy/omarchy-sync-daemon.sh`): Watches ~/.config/hypr, waybar, terminals, Claude Code dirs. Syncs user desktop configs to git. Uses inotifywait + 5min pull cycle. Designed for Hyprland machines.

2. **Platform daemon** (`platform/linux/scripts/sync-daemon.sh`): Watches entire repo (machines/, platform/, universal/, docs/). General-purpose machine state sync. 667 lines, sophisticated retry/offline queue/conflict handling.

## Current Samsung State (updated 2026-04-04)

- **Omarchy daemon: RUNNING** (PID 1053, started at boot via systemd)
  - Watches: ~/.config/hypr, waybar, alacritty, kitty, ghostty, walker, mako, .claude/agents, .claude/commands, .claude/skills, .claude/projects/*/memory, learnings/
- **Platform daemon: NOT running** (hostname bug still present)
- inotify-tools: installed and active (PID 1316)
- cortex-to-learnings bridge: active (SessionEnd hook)

## Known Bugs

**Platform daemon hostname bug (line 327):** Checks `machines/$HOSTNAME/` but Samsung hostname is "samsung-omarchy" while directory is `machines/samsung-laptop/`. Auto-conflict-resolution never triggers. Needs registry lookup instead of raw hostname.

## Architecture

For Omarchy/Hyprland machines (Samsung, MacBook): omarchy daemon handles config sync.
Platform daemon is better suited for repo-level watches but has bugs.
Cortex-to-learnings bridge handles AI memory flow: cortex insights -> JSONL -> topic markdown -> learnings/ -> daemon auto-commit.

**Why:** Config drift accumulated for 2.5 months before the omarchy daemon was installed. Now auto-syncing is active.

**How to apply:** Omarchy daemon is the priority for Hyprland machines. Fix platform daemon hostname bug before enabling it.
