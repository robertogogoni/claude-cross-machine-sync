# Beeper Update System Design

**Date:** 2026-01-15
**Status:** Approved

## Overview

A smart Beeper update system that combines CLI automation with GUI management, ensuring you always have access to the latest version even when the AUR lags behind.

## Components

| Component | Purpose | Install Method |
|-----------|---------|----------------|
| **Bauh** | GUI for AUR + AppImage management with tray notifications | `paru -S bauh` |
| **AM** | CLI AppImage manager for future use | Installer script |
| **`update-beeper`** | Smart CLI: paru → direct download fallback | Script in `~/bin` |

## How It Works

```
update-beeper
      │
      ▼
┌─────────────┐
│ Check versions │
│ (installed/latest/AUR) │
└──────┬──────┘
       │
 Up to date? ──Yes──▶ Exit
       │
      No
       │
 AUR has it? ──Yes──▶ paru -Syu beeper-v4-bin ──▶ Done
       │
      No
       │
┌──────▼──────┐
│ Direct download │
│ from Beeper API │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Backup → Extract │
│ Patch → Install │
└──────┬──────┘
       │
       ▼
    Done!
```

## Script Features

- **Version comparison** — Proper semantic versioning with `sort -V`
- **Check-only mode** — `update-beeper --check` to see updates without installing
- **Auto-restart** — `update-beeper --restart` to restart Beeper after update
- **Notifications** — `update-beeper --check --notify` for timer/cron use
- **Backup** — Keeps last 3 backups in `/opt/beeper-backups`
- **AUR patches** — Applies same fixes as official AUR package

## Installation Steps

### 1. Install Bauh (GUI)
```bash
paru -S bauh
```

### 2. Install AM (CLI)
```bash
wget -q https://raw.githubusercontent.com/ivan-hc/AM/main/AM-INSTALLER && \
chmod a+x ./AM-INSTALLER && \
./AM-INSTALLER && \
rm ./AM-INSTALLER
```

### 3. Install update-beeper script
```bash
# Script is at ~/bin/update-beeper
chmod +x ~/bin/update-beeper
```

### 4. (Optional) Enable daily update check
```bash
systemctl --user enable --now beeper-check.timer
```

### 5. (Optional) Add to topgrade
```toml
# ~/.config/topgrade.toml
[commands]
"Beeper" = "update-beeper"
```

## Usage

| Task | Command |
|------|---------|
| Update Beeper | `update-beeper` |
| Check only | `update-beeper --check` |
| Update + auto-restart | `update-beeper --restart` |
| Update all AppImages | `am -u` |
| GUI management | Open Bauh |

## Files Created

- `~/bin/update-beeper` — Main update script
- `~/.config/systemd/user/beeper-check.service` — Systemd service
- `~/.config/systemd/user/beeper-check.timer` — Daily timer
- `~/.config/topgrade.toml` — Topgrade integration (optional)

## Technical Details

### Beeper API Endpoint
```
https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop
```
Redirects to latest AppImage download URL.

### AUR Package
- Name: `beeper-v4-bin`
- Maintainer: mathix (active, updates within days)
- Patches applied: AppRun path fix, auto-update disable

### Backup Location
`/opt/beeper-backups/` — Keeps last 3 versions

## Notes

- When direct-installing, pacman still shows old version
- Run `paru -Syu beeper-v4-bin` when AUR catches up to resync
- Bauh can monitor AUR package for updates with tray notifications
