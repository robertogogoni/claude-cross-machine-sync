# Machine Sync Auto-Categorization System

**Design Document**
**Date**: 2026-01-23
**Status**: Approved for Implementation
**Author**: Claude Code + Roberto Gogoni

---

## Overview

A comprehensive system for automatically categorizing and syncing configurations across a multi-machine ecosystem:

| Machine | Hostname | Platform | OS | Desktop | Status |
|---------|----------|----------|-----|---------|--------|
| Dell G15 5530 | `Rob-Dell` | windows | Windows 11 | Native | Active |
| MacBook Air | `macbook-air` | linux | Arch Linux | Omarchy/Hyprland | Active |
| Samsung Laptop | `samsung-arch` | linux | Arch Linux | Omarchy/Hyprland | Pending |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLAUDE CODE (AI Layer)                       │
│  • Detects current machine at session start                     │
│  • Makes intelligent categorization decisions                   │
│  • Auto-places files, auto-generates commit tags                │
│  • Warns on miscategorization                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 DIRECTORY STRUCTURE (Organization)              │
│  machines/           → Machine-specific configs                 │
│  platform/windows/   → Windows-only configs                     │
│  platform/linux/     → Linux-only configs (includes omarchy)    │
│  universal/          → Cross-platform configs                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 SYNC LAYER (Background Daemons)                 │
│  Linux: systemd user service (inotifywait + git)                │
│  Windows: Task Scheduler + PowerShell (FileSystemWatcher)       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 GIT CONVENTIONS (Traceability)                  │
│  [universal]           → All machines                           │
│  [windows]             → Windows platform                       │
│  [linux]               → Linux platform                         │
│  [machine:hostname]    → Specific machine                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component 1: Machine Registry

**File**: `machines/registry.yaml`

```yaml
machines:
  dell-g15:
    hostname: Rob-Dell
    platform: windows
    os: Windows 11
    hardware:
      vendor: Dell Inc.
      model: Dell G15 5530
      type: desktop
    status: active
    primary_user: rober

  macbook-air:
    hostname: macbook-air
    platform: linux
    os: Arch Linux
    desktop: omarchy
    hardware:
      vendor: Apple Inc.
      model: MacBookAir7,2
      type: laptop
    status: active
    primary_user: rob

  samsung-laptop:
    hostname: samsung-arch
    platform: linux
    os: Arch Linux
    desktop: omarchy
    hardware:
      vendor: Samsung
      model: TBD
      type: laptop
    status: pending
    primary_user: rob

platforms:
  windows:
    machines: [dell-g15]
    shell: powershell
    config_paths:
      home: "%USERPROFILE%"
      claude: "%USERPROFILE%\\.claude"

  linux:
    machines: [macbook-air, samsung-laptop]
    shell: bash
    config_paths:
      home: "$HOME"
      claude: "$HOME/.claude"
      hypr: "$HOME/.config/hypr"
```

---

## Component 2: Directory Structure

```
claude-cross-machine-sync/
│
├── machines/                          # MACHINE-SPECIFIC
│   ├── registry.yaml                  # Source of truth
│   ├── dell-g15/
│   │   ├── machine.yaml               # Hardware details
│   │   ├── claude/
│   │   │   └── settings.local.json    # Machine-specific Claude settings
│   │   └── shell/
│   │       └── profile.ps1            # PowerShell profile additions
│   ├── macbook-air/
│   │   ├── machine.yaml
│   │   ├── claude/
│   │   └── hypr/                      # Machine-specific Hyprland
│   │       ├── monitors.conf
│   │       ├── input.conf
│   │       └── looknfeel.conf
│   └── samsung-laptop/
│       ├── machine.yaml
│       ├── claude/
│       └── hypr/
│
├── platform/                          # PLATFORM-SPECIFIC
│   ├── windows/
│   │   ├── shell/
│   │   │   ├── aliases.ps1            # PowerShell aliases
│   │   │   └── functions.ps1          # PowerShell functions
│   │   ├── apps/                      # Windows app configs
│   │   └── scripts/
│   │       ├── sync-daemon.ps1        # Windows sync daemon
│   │       └── deploy.ps1             # Windows deploy script
│   └── linux/
│       ├── shell/
│       │   ├── aliases.sh             # Bash/Zsh aliases
│       │   └── functions.sh           # Bash/Zsh functions
│       ├── omarchy/                   # Migrated from omarchy/universal/
│       │   ├── hypr/
│       │   │   ├── bindings.conf
│       │   │   ├── envs.conf
│       │   │   ├── apps.conf
│       │   │   ├── apps/
│       │   │   └── workspace-window-rules.conf
│       │   ├── waybar/
│       │   ├── terminals/
│       │   └── walker/
│       └── scripts/
│           ├── sync-daemon.sh         # Linux sync daemon
│           └── deploy.sh              # Linux deploy script
│
├── universal/                         # CROSS-PLATFORM
│   ├── claude/
│   │   ├── settings.json              # Shared Claude settings
│   │   └── skills/                    # Shared skills
│   ├── git/
│   │   └── gitconfig                  # Shared git config
│   └── scripts/
│       └── sync-now.sh                # Manual sync trigger (cross-platform)
│
├── docs/
├── learnings/
├── CLAUDE.md
└── README.md
```

---

## Component 3: Claude Code Integration

### Session Start Detection

When Claude Code starts, it:

1. Reads hostname via system command
2. Loads `machines/registry.yaml`
3. Matches hostname to machine entry
4. Sets session context: machine, platform, capabilities

### Categorization Decision Logic

```
WHEN creating/modifying a file:

1. ANALYZE content and purpose
   │
   ├─ Hardware-specific? (GPU, display, trackpad, keyboard)
   │   └─ → machines/{hostname}/
   │
   ├─ OS-specific with NO equivalent?
   │   ├─ Windows-only (PowerShell, Registry, etc.)
   │   │   └─ → platform/windows/
   │   └─ Linux-only (systemd, Hyprland, etc.)
   │       └─ → platform/linux/
   │
   ├─ OS-specific WITH equivalent?
   │   └─ → universal/ (document both variants in same file or paired files)
   │
   └─ Workflow/preference (works anywhere)?
       └─ → universal/

2. PLACE file in determined location

3. GENERATE commit with appropriate tag:
   [universal] | [windows] | [linux] | [machine:{hostname}]
```

### Auto-Actions

Claude does not ask "where should this go?" — it decides and informs:

```
Creating trackpad sensitivity config.
Location: machines/macbook-air/hypr/input.conf
Commit tag: [machine:macbook-air]

Reason: Trackpad sensitivity is hardware-specific (Apple Force Touch).
```

---

## Component 4: Commit Conventions

### Format

```
[scope] Brief description

scope = universal | windows | linux | machine:{hostname}
```

### Examples

```bash
# Universal
[universal] Add cross-platform git aliases
[universal] Update shared Claude settings

# Platform
[windows] Add PowerShell sync daemon
[linux] Configure shared Hyprland keybindings

# Machine-specific
[machine:dell-g15] Configure NVIDIA GPU settings
[machine:macbook-air] Tune Intel HD 6000 for Hyprland
[machine:samsung-laptop] Set up HiDPI scaling
```

### Searching

```bash
git log --oneline --grep="\[windows\]"
git log --oneline --grep="\[machine:macbook-air\]"
git log --oneline --grep="\[universal\]"
```

---

## Component 5: Background Sync Daemons

### Linux (systemd)

**Service**: `~/.config/systemd/user/machine-sync.service`

```ini
[Unit]
Description=Machine Sync Daemon
After=network-online.target

[Service]
Type=simple
ExecStart=%h/claude-cross-machine-sync/platform/linux/scripts/sync-daemon.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

**Timer**: `~/.config/systemd/user/machine-sync.timer`

```ini
[Unit]
Description=Machine Sync Timer (pull every 5 min)

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

**Behavior**:
- Watches config directories via inotifywait
- On change: analyze, commit with tag, push
- Every 5 min: pull, deploy if changes

### Windows (Task Scheduler)

**Task**: `Machine-Sync-Daemon`

**Trigger**: At logon + every 5 minutes

**Action**: PowerShell script

```powershell
# platform/windows/scripts/sync-daemon.ps1
# Uses FileSystemWatcher for change detection
# Commits with [windows] or [machine:dell-g15] tags
# Pulls and deploys on schedule
```

**Behavior**:
- FileSystemWatcher monitors sync directory
- On change: analyze, commit with tag, push
- Every 5 min: pull, deploy if changes

---

## Component 6: Bootstrap Process

### Linux Bootstrap (`bootstrap.sh`)

```bash
#!/bin/bash
# 1. Detect hostname + hardware
# 2. Check/create machine entry in registry
# 3. Install systemd service + timer
# 4. Deploy configs (universal → platform → machine)
# 5. Commit registration, push
```

### Windows Bootstrap (`bootstrap.ps1`)

```powershell
# 1. Detect hostname + hardware
# 2. Check/create machine entry in registry
# 3. Create Task Scheduler task
# 4. Deploy configs (universal → platform → machine)
# 5. Commit registration, push
```

### Usage

```bash
# New Linux machine
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync
./bootstrap.sh

# New Windows machine
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync
.\bootstrap.ps1
```

---

## Migration Plan

### Phase 1: Create New Structure (Non-Breaking)

1. Create `machines/registry.yaml`
2. Create `machines/dell-g15/` with machine.yaml
3. Create `platform/windows/` structure
4. Create `universal/` with shared configs

### Phase 2: Migrate Linux Configs

1. Move `omarchy/universal/` → `platform/linux/omarchy/`
2. Move `omarchy/machines/macbook-air/` → `machines/macbook-air/`
3. Update deploy scripts to use new paths
4. Keep `omarchy/` scripts working (they read from new locations)

### Phase 3: Add Daemons

1. Create Linux systemd service
2. Create Windows Task Scheduler task
3. Test sync both directions

### Phase 4: Update Bootstrap

1. Update `scripts/linux-setup.sh` → new bootstrap
2. Update `scripts/windows-setup.ps1` → new bootstrap
3. Test full setup on both platforms

### Phase 5: Deprecate Legacy

1. Mark `omarchy/` as legacy in README
2. Remove after 2 weeks of stable operation

---

## Success Criteria

- [ ] Machine detected automatically at Claude Code session start
- [ ] Files placed in correct location without manual intervention
- [ ] Commits tagged with correct scope automatically
- [ ] Changes sync within 5 minutes between machines
- [ ] New machine joins ecosystem in under 2 minutes
- [ ] No manual categorization decisions required

---

## Files to Create

| File | Purpose |
|------|---------|
| `machines/registry.yaml` | Machine definitions |
| `machines/dell-g15/machine.yaml` | Dell hardware details |
| `platform/windows/scripts/sync-daemon.ps1` | Windows sync daemon |
| `platform/windows/scripts/deploy.ps1` | Windows deploy script |
| `platform/linux/scripts/sync-daemon.sh` | Linux sync daemon (migrate from omarchy) |
| `platform/linux/scripts/deploy.sh` | Linux deploy script (migrate from omarchy) |
| `bootstrap.sh` | Linux bootstrap |
| `bootstrap.ps1` | Windows bootstrap |

---

*Document created by Claude Code during brainstorming session.*
