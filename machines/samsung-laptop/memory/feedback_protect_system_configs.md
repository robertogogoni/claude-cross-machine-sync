---
name: Protect customized system configs
description: hypridle fully killed (systemd mask + autostart pkill), monitors.conf, input.conf, Chrome policy protected
type: feedback
---

Do not modify hypridle.conf, monitors.conf, input.conf, or Chrome policy without explicit user permission.

**Why:** User does not want idle lock, DPMS, suspend, or screensavers. The TV (second display) fails to wake from DPMS off. hypridle has THREE layers of disablement (all required):
1. systemd service masked (`~/.config/systemd/user/hypridle.service` → `/dev/null`)
2. `exec-once = sleep 2 && pkill -x hypridle` in `~/.config/hypr/autostart.conf`
3. `hypridle.conf` set to screensaver-only (no lock/DPMS) as a safety net

Layer 2 exists because Omarchy's default autostart (`~/.local/share/omarchy/default/hypr/autostart.conf`) launches `uwsm-app -- hypridle` directly, bypassing the systemd mask entirely. Without the pkill, hypridle runs as a bare process and triggers `screensaver-launch` after 5 min idle (fullscreen ghostty terminals on every monitor + hidden cursor).

Chrome policy blocks notifications/popups system-wide. monitors.conf and input.conf are hardware-specific and stable.

**How to apply:** These files are enforced by the PreToolUse hook (exits code 2 if an Edit/Write targets them). Protected patterns: `hypridle.conf`, `monitors.conf`, `input.conf`, `chrome/policies/managed/permissions.json`. Use Bash with sed to bypass when user explicitly requests changes. Do not suggest running `omarchy-refresh-hyprland` or `omarchy-refresh-config hypr/hypridle.conf` as those would revert customizations. If hypridle resurfaces after an Omarchy update, check if `uwsm-app -- hypridle` was re-added to the default autostart.
