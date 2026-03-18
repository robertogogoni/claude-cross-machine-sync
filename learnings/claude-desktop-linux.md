# Claude Desktop on Arch Linux (Hyprland/Wayland)

**Created**: 2026-03-18
**Package**: claude-desktop-bin (AUR)

## Installation
- `claude-desktop-bin` is the best AUR option: official binary repackaged, most maintained, highest community trust
- Depends on `electron` (system package) and `nodejs`
- Wrapper at `/usr/bin/claude-desktop`: `exec electron /usr/lib/claude-desktop-bin/app.asar "$@"`

## Wayland configuration
- Electron apps read `~/.config/electron-flags.conf` when launched via the `electron` binary
- Required flags: `--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --enable-wayland-ime`
- This file is GLOBAL for ALL Electron apps (Stremio, Claude Desktop, etc.)
- Do NOT put `--force-device-scale-factor` here; that's Chrome-only

## Credential persistence with auto-login
- SDDM auto-login bypasses PAM keyring unlock (no password provided)
- gnome-keyring stays locked, Electron can't persist OAuth tokens
- Fix: add to Hyprland autostart: `exec-once = echo -n "" | gnome-keyring-daemon --replace --unlock --components=pkcs11,secrets`
- Trade-off: physical access = keyring access. Acceptable for personal dev machine.

## Auto-update pattern
- systemd user timer (`claude-desktop-update.timer`) with `Persistent=true` + `RandomizedDelaySec=1h`
- Script checks AUR version via `yay -Si`, compares with `pacman -Q`
- Desktop notification via `notify-send` on successful update
- Logs to `~/.local/share/claude-desktop/update.log`

## MCP server config
- `~/.config/Claude/claude_desktop_config.json` is separate from CLI config
- Desktop does NOT read CLAUDE.md or CLI memory files natively
- Bridge via memory-sync MCP server (see memory-sync-bridge.md)
