# Sync Daemon Architecture: Findings & Fixes (2026-03-19)

## Overview

The repo contains **two distinct sync daemons** that serve complementary but overlapping purposes.

## Daemon Comparison

| Feature | Omarchy Daemon | Platform Daemon |
|---------|---------------|-----------------|
| **File** | `omarchy/omarchy-sync-daemon.sh` | `platform/linux/scripts/sync-daemon.sh` |
| **Lines** | 272 | 667 |
| **Direction** | System → Repo | Repo → System (bidirectional) |
| **Watch scope** | `~/.config/hypr`, waybar, terminals | Entire repo (machines/, platform/, universal/) |
| **Mechanism** | inotifywait + 5min pull | inotifywait + systemd timer |
| **Debounce** | 3 seconds | Built-in |
| **Auto-categorize** | Yes (machine vs universal) | Yes (but hostname bug) |
| **Samsung support** | Works if installed | Hostname mismatch bug |
| **Install method** | `omarchy/setup.sh` | `bootstrap.sh --install` |
| **Systemd service** | `omarchy-sync.service` | `machine-sync.service` |

## Critical Bug: Platform Daemon Hostname Mismatch

**Location**: `platform/linux/scripts/sync-daemon.sh` line 327

**Problem**: Uses raw `$(hostname)` ("samsung-omarchy") to match directory paths, but machine directory is `machines/samsung-laptop/`.

**Fix needed**: Registry lookup function that maps hostname → machine directory name.

```bash
# Current (broken)
if [[ "$file" =~ ^machines/$HOSTNAME/ ]]; then

# Should be
MACHINE_NAME=$(get_machine_name_from_registry "$HOSTNAME")
if [[ "$file" =~ ^machines/$MACHINE_NAME/ ]]; then
```

## Auto-Categorization (Omarchy Daemon)

Works correctly. Uses pattern matching in `sync-to-repo.sh` (lines 34-68):

**Always machine-specific**: monitors.conf, input.conf, looknfeel.conf
**Always universal**: envs.conf, workspace-window-rules.conf, apps.conf
**Content-detected**: Files containing GPU references, touchpad settings, display connectors

## Recommended Architecture

For Omarchy/Hyprland machines (Samsung, MacBook Air):
1. **Omarchy daemon** (primary): Syncs desktop configs from ~/.config to git
2. **Platform daemon** (secondary, optional): Syncs repo changes back to system

For Windows (Dell G15):
1. **PowerShell daemon** (not yet implemented): Would use FileSystemWatcher

## Installation Status (2026-03-19)

| Machine | Omarchy Daemon | Platform Daemon | Status |
|---------|---------------|-----------------|--------|
| Samsung 270E5J | Not installed | Not installed | Manual sync only |
| MacBook Air | Not installed | Not installed | Unknown |
| Dell G15 | N/A | N/A (no PS1 daemon) | Manual sync only |

## Key Files

- Omarchy daemon: `omarchy/omarchy-sync-daemon.sh`
- Omarchy setup: `omarchy/setup.sh` (creates systemd service)
- Omarchy sync: `omarchy/sync-to-repo.sh` (categorization logic)
- Omarchy deploy: `omarchy/deploy.sh` (deploys from repo to system)
- Platform daemon: `platform/linux/scripts/sync-daemon.sh`
- Registry: `machines/registry.yaml`
