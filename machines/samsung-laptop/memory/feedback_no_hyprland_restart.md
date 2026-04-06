---
name: Never restart Hyprland mid-session
description: Hyprland exit drops to TTY with no graphical recovery — SDDM autologin only fires at boot
type: feedback
---

Never use `hyprctl dispatch exit` or restart Hyprland mid-session. The system drops to a TTY login prompt and entering valid credentials does not restore the graphical session.

**Why:** SDDM autologin (User=robthepirate, Session=hyprland-uwsm) only triggers at boot. When Hyprland exits mid-session, SDDM's greeter on VT2/Xorg doesn't re-engage autologin. The user gets stuck on a text console.

**How to apply:** When changes require a Hyprland restart (env vars, compositor-level config), use `systemctl reboot` instead. Always warn the user before any action that would kill Hyprland. Never disable eDP-1 without confirming the user can recover (TV may not wake from DPMS). Test monitor changes with `hyprctl keyword monitor` first (live, no restart needed) before committing to monitors.conf.
