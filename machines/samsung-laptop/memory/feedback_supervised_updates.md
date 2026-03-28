---
name: System updates must route through Claude Code
description: All system upgrades (pacman, yay, omarchy-update) are intercepted and routed through Claude Code's /system-update command
type: feedback
---

All system updates must go through Claude Code's supervised `/system-update` flow.

**Why:** The user's Samsung laptop (8GB RAM, 2C i7-4510U, HDD) is resource-constrained. Unsupervised updates caused a Chromium source build that exhausted swap, stalled the system, and wasted 101GB of disk (2026-03-28 incident). Claude Code reviews packages, enforces preferences, creates btrfs snapshots, and verifies post-update health.

**How to apply:**
- The `/system-update` command is at `~/.claude/commands/system-update.md`
- The `system-update` shell wrapper is at `~/.local/bin/system-update`
- Shell functions in `~/.bashrc` intercept `yay -Syu`, `pacman -Syu`, and aliases `syu`, `update`
- `omarchy-update` is wrapped via `~/.local/bin/omarchy-update` (PATH precedence)
- Bypass with `omarchy-update --direct` if Claude is unavailable
- Post-update verification hook at `~/.config/omarchy/hooks/post-update` logs to `~/.claude/logs/system-updates.log`
- When running `/system-update`, always check for new electron versions in IgnorePkg
