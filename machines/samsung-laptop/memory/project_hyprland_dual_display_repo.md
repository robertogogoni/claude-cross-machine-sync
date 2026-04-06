---
name: hyprland-dual-display public repo
description: Public GitHub repo shipping the full dual-display Hyprland setup with installer, scripts, EDID, TV jailbreak docs
type: project
---

## Repository: robertogogoni/hyprland-dual-display

Public repo published 2026-04-06 with live screenshots, MIT license.

### What shipped (v1.0.0)
- **40 files**, 3,539 lines across 4 layers
- Layer 1: Dual waybar (26px laptop / 38px TV), DPI scaling, dock
- Layer 2: 10 Python/Bash scripts (4 daemons + 6 tools), split-monitor-workspaces plugin
- Layer 3: Custom 256-byte EDID binary, GPU/zram/journald tuning, crash docs
- Layer 4: webOS TV jailbreak guide with Luna API and hidden pcMode
- Interactive installer (`install.sh`) with 7 selectable modules + backup
- Full docs: TIMELINE.md, TV-JAILBREAK.md, KEYBINDINGS.md, edid/README.md

### Pre-publish code review fixes
1. Scrubbed leaked internal IP from TIMELINE.md
2. Security warning on empty-password gnome-keyring in autostart.conf
3. Added `ensure_single_instance()` PID guard to `hypr-workspace-icons` (was missing, other 3 daemons had it)
4. Marked external waybar scripts (sync-status, ai-usage) as not-included
5. Fixed install.sh menu loop on invalid input

### Local source
`/home/robthepirate/hyprland-dual-display/` — git repo with origin at GitHub.

**Why:** Distill the entire dual-display debugging journey (crash fix, EDID surgery, TV jailbreak) into a reusable, public repo others can learn from.
**How to apply:** When user references this repo or wants to update it, work from `/home/robthepirate/hyprland-dual-display/`. Screenshots are in `assets/`. README has placeholder for more screenshots (zen mode, workspace colors).
