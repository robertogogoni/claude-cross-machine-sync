# Keyboard Cedilla Configuration (Arch/Hyprland/fcitx5)

**Task**: Make `' + c` produce `ç` (cedilla) instead of `ć` (c-acute)
**Status**: Working and verified (2026-02-25)
**Date**: 2026-02-25

## What Was Done

### 1. XCompose Override (`~/.XCompose`)
```
include "%L"
<dead_acute> <c> : "ç" ccedilla
<dead_acute> <C> : "Ç" Ccedilla
```

### 2. Hyprland Input Config (`~/.config/hypr/input.conf`)
- Set `kb_variant = intl,` (US International with dead keys)

### 3. fcitx5 Profile (`~/.config/fcitx5/profile`)
- Set `DefaultIM=keyboard-us-intl`
- Set `Default Layout=us-intl`

### 4. Environment Variables (`~/.config/environment.d/fcitx.conf`)
```
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
XCOMPOSEFILE=/home/rob/.XCompose
```

### 5. Browser Flags (for fcitx5 in Electron/Chromium)
- `~/.config/chromium-flags.conf` - added `--gtk-version=4`
- `~/.config/brave-flags.conf` - added `--gtk-version=4`
- `~/.config/chrome-canary-flags.conf` - added `--gtk-version=4`
- `~/.config/electron-flags.conf` - created with `--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime`
- `~/.config/electron39-flags.conf` - same as above

### 6. Hyprland Environment (`~/.config/hypr/envs.conf`)
- Added `XCOMPOSEFILE` env var

## Verification Needed
- [ ] Test `' + c` → `ç` in terminal (Ghostty/Kitty/Alacritty)
- [ ] Test in Chromium/Brave browsers
- [ ] Test in Electron apps (VS Code, etc.)
- [ ] Test after full reboot (persistence check)

## Key Insight
fcitx5 overwrites its profile on graceful shutdown. Must either:
- `pkill -9 fcitx5` (force kill, no profile save) before editing profile
- Or use `fcitx5-remote` commands to change layout at runtime

## AUR Package (published 2026-03-02)

- **Package**: `wayland-cedilla-fix` on AUR
- **AUR repo**: `~/repos/aur-wayland-cedilla-fix/` (contains PKGBUILD + .SRCINFO)
- **Remote**: `ssh://aur@aur.archlinux.org/wayland-cedilla-fix.git`
- **SSH key**: `~/.ssh/aur` (ed25519, Host config in `~/.ssh/config`)
- **Install**: `yay -S wayland-cedilla-fix`

### Updating the AUR Package
1. Edit `PKGBUILD` in `~/repos/aur-wayland-cedilla-fix/` (bump `pkgver`)
2. Regenerate: `makepkg --printsrcinfo > .SRCINFO`
3. Commit both files
4. Push: `git push` (remote is AUR)

### Source vs AUR Repo
- **Source repo**: `~/wayland-cedilla-fix/` → GitHub `robertogogoni/wayland-cedilla-fix`
- **AUR repo**: `~/repos/aur-wayland-cedilla-fix/` → AUR `aur@aur.archlinux.org:wayland-cedilla-fix.git`
- `.SRCINFO` in source repo root is a leftover from generation — it belongs in the AUR repo only

## Backups Created
The session created timestamped backups before modifying:
- `~/.config/hypr/input.conf.bak.*`
- `~/.config/hypr/envs.conf.bak.*`
- `~/.config/fcitx5/profile.bak.*`
