---
name: Protect customized system configs
description: hypridle.conf, monitors.conf, input.conf, and Chrome policy are protected from edits — user disabled lock screen and extended idle timeouts
type: feedback
---

Do not modify hypridle.conf, monitors.conf, input.conf, or Chrome policy without explicit user permission.

**Why:** User customized hypridle.conf to remove lock screen and extend screensaver to 10min / screen-off to 15min. They don't want these reverted or overwritten. Chrome policy blocks notifications/popups system-wide. monitors.conf and input.conf are hardware-specific and stable. On 2026-03-17, monitors.conf was intentionally switched from 2x retina preset to 1x preset (correct for 1366x768 panel).

**How to apply:** These files are enforced by the PreToolUse hook (exits code 2 if an Edit/Write targets them). Protected patterns: `hypridle.conf`, `monitors.conf`, `input.conf`, `chrome/policies/managed/permissions.json`. Use Bash with sed to bypass when user explicitly requests changes. Do not suggest running `omarchy-refresh-hyprland` or `omarchy-refresh-config hypr/hypridle.conf` as those would revert customizations.
