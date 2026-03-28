---
name: Claude Desktop setup
description: Claude Desktop installed via AUR with auto-updater, Wayland config, keyring unlock, and memory-sync MCP
type: project
---

## Installation

- **Package:** `claude-desktop-bin` (AUR) v1.1.7203
- **Binary:** `/usr/bin/claude-desktop` (bash wrapper: `exec electron /usr/lib/claude-desktop-bin/app.asar`)
- **App:** `/usr/lib/claude-desktop-bin/app.asar`

## Auto-updater

- **Script:** `~/.local/bin/claude-desktop-update` checks AUR daily
- **Timer:** `~/.config/systemd/user/claude-desktop-update.timer` (enabled, daily, Persistent=true, RandomizedDelaySec=1h)
- **Service:** `~/.config/systemd/user/claude-desktop-update.service`
- **Logs:** `~/.local/share/claude-desktop/update.log`
- Desktop notification on successful update via `notify-send`

## Wayland config

- `~/.config/electron-flags.conf` applies to ALL Electron apps (Claude Desktop, Stremio, etc.)
- Flags: `--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --enable-wayland-ime`
- NO `--force-device-scale-factor` here (that's Chrome-only in chrome-canary-flags.conf)

## Credential persistence

- gnome-keyring auto-unlock added to `~/.config/hypr/autostart.conf`
- `exec-once = echo -n "" | gnome-keyring-daemon --replace --unlock --components=pkcs11,secrets`
- Required because SDDM auto-login bypasses PAM keyring unlock

## MCP config

- 13 servers in `~/.config/Claude/claude_desktop_config.json` (synced with CLI)
- Includes memory-sync MCP for accessing CLI memories from Desktop

**Why:** Claude Desktop was installed 2026-03-18. The auto-updater, Wayland config, and keyring unlock ensure zero-friction daily use on this Arch/Hyprland setup.

**How to apply:** Restart Desktop to pick up config changes. Check `systemctl --user status claude-desktop-update.timer` for updater status.
