---
name: No Nerd Font icons in waybar at 768p
description: Workspace icons render as broken squares on 768p displays, use text labels instead
type: feedback
---

Do not use Nerd Font icons in waybar workspace buttons on 768p displays. They render as illegible squares/tofu at 11-13px.

**Why:** User's Samsung laptop is 1366x768. Waybar height is 26px. Nerd Font characters need at least 16-18px to be legible. The format "{name}" approach with icon characters failed visually.

**How to apply:** Use plain text labels (L1-L5, T1-T5) with color differentiation via CSS nth-child. Icons work fine in the wlr/taskbar module (18px+ icon-size) and nwg-dock (36px icons), just not in workspace button text.
