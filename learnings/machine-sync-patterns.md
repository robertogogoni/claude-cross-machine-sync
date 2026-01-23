# Machine Sync Patterns - Auto-Categorization System

**Created**: 2026-01-23
**Context**: Building AI-driven auto-categorization for multi-machine ecosystem (Windows + Linux)

## Overview

A 3-layer architecture for automatically categorizing and syncing configuration changes across machines:

1. **Claude AI Layer** - Intelligent categorization decisions
2. **Directory Structure Layer** - Physical file organization
3. **Git Conventions Layer** - Searchable commit history

## Directory Hierarchy

```
machines/           → Machine-specific (hardware-dependent)
platform/           → Platform-specific (OS-dependent)
universal/          → Cross-platform (works everywhere)
```

### Categorization Decision Tree

```
Is it hardware-dependent?
├─YES→ machines/<hostname>/
│      Examples: monitor layout, GPU settings, trackpad sensitivity
│
Is it OS-dependent?
├─YES→ platform/<os>/
│      Examples: PowerShell scripts, systemd services, Hyprland
│
OTHERWISE
└─NO→ universal/
       Examples: shared settings, keybindings, preferences
```

## Commit Tag Conventions

| Tag | Pattern | Purpose |
|-----|---------|---------|
| `[universal]` | Cross-platform changes | Works everywhere |
| `[windows]` | Windows-specific | PowerShell, Task Scheduler |
| `[linux]` | Linux-specific | Bash, systemd, Hyprland |
| `[machine:<id>]` | Hardware-specific | GPU, monitors, devices |

### Searching Git History

```bash
# Find all Windows changes
git log --grep='\[windows\]' --oneline

# Find machine-specific commits
git log --grep='\[machine:dell-g15\]' --oneline

# Find all universal changes
git log --grep='\[universal\]' --oneline
```

## Background Sync Daemon Architecture

### Windows (PowerShell + Task Scheduler)

**Key Components**:
- `FileSystemWatcher` for real-time file monitoring
- `Task Scheduler` for startup persistence
- Debouncing to batch rapid changes

```powershell
# FileSystemWatcher setup
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $RepoPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Event handlers
Register-ObjectEvent $watcher "Changed" -Action { ... }
Register-ObjectEvent $watcher "Created" -Action { ... }
Register-ObjectEvent $watcher "Deleted" -Action { ... }
```

**Gotcha**: `$pid` is a reserved variable in PowerShell. Use `$daemonPid` instead.

### Linux (Bash + inotifywait + systemd)

**Key Components**:
- `inotifywait` (from inotify-tools) for file monitoring
- `systemd user service` for startup persistence
- Background subshell for periodic pulls

```bash
# Watch with inotifywait
inotifywait -m -r \
    -e modify,create,delete,move \
    --exclude '\.git|\.swp|~$' \
    "$WATCH_DIRS" | while read -r directory event filename; do
    # Handle change
done
```

**Required package**: `inotify-tools` (Arch: `pacman -S inotify-tools`)

## Bootstrap Process

### Hardware Detection

**Windows (WMI)**:
```powershell
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor
$gpu = Get-CimInstance Win32_VideoController
```

**Linux (/sys)**:
```bash
VENDOR=$(cat /sys/class/dmi/id/sys_vendor)
MODEL=$(cat /sys/class/dmi/id/product_name)
CHASSIS=$(cat /sys/class/dmi/id/chassis_type)
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2)
GPU=$(lspci | grep -i "vga\|3d\|display")
```

### Chassis Type Mapping (Linux)

```bash
case "$CHASSIS" in
    9|10|14) TYPE="laptop" ;;
    3|4|5|6|7) TYPE="desktop" ;;
    *) TYPE="unknown" ;;
esac
```

## Machine Registry Schema

```yaml
machines:
  <machine-id>:
    hostname: string           # OS hostname
    platform: windows|linux
    os: string                 # OS name (e.g., "Windows 11", "Arch Linux")
    desktop: string            # Desktop env (omarchy, kde, etc.)
    hardware:
      vendor: string
      model: string
      type: laptop|desktop
      cpu: string
      gpu: string
    status: active|pending|inactive
    primary_user: string
    config_paths:
      home: string
      claude: string
      sync_repo: string
```

## Sync Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  File Change    │────▶│  Categorize     │────▶│  Git Commit     │
│  (detected)     │     │  (by path/type) │     │  [scope] msg    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                                               │
         │                                               ▼
         │                                      ┌─────────────────┐
         │                                      │  Git Push       │
         │                                      │  (to remote)    │
         │                                      └─────────────────┘
         │                                               │
         ▼                                               ▼
┌─────────────────┐                            ┌─────────────────┐
│  Periodic Pull  │◀───────────────────────────│  Other Machines │
│  (every 5 min)  │                            │  (pull changes) │
└─────────────────┘                            └─────────────────┘
```

## Key Patterns

### 1. Debouncing File Events

Both daemons implement debouncing to avoid committing every keystroke:

```powershell
# PowerShell
$script:DebounceSeconds = 3
if (($now - $script:LastSyncTime).TotalSeconds -lt $script:DebounceSeconds) {
    return
}
```

```bash
# Bash
DEBOUNCE_SECONDS=3
if (( now - last_sync >= DEBOUNCE_SECONDS )); then
    # Sync
fi
```

### 2. Lock Files for Single Instance

```powershell
# Windows
$PID | Out-File $script:LockFile -Force
```

```bash
# Linux
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; exit' EXIT INT TERM
```

### 3. Exclude Patterns

```powershell
$excludePatterns = @("\.git", "\.swp$", "~$", "\.lock$", "\.log$")
```

```bash
--exclude '\.git|\.swp|~$|\.lock'
```

### 4. Graceful Shutdown

Both daemons clean up lock files on exit:
- Remove lock file
- Stop file watchers
- Log shutdown message

## Best Practices

1. **Test on one machine first** before syncing to others
2. **Use meaningful commit messages** - the scope tags make history searchable
3. **Keep machine-specific configs minimal** - prefer universal when possible
4. **Check daemon status** after boot to ensure it's running
5. **Pull before making changes** to avoid merge conflicts

## Related Files

- `machines/registry.yaml` - Machine ecosystem definition
- `platform/windows/scripts/sync-daemon.ps1` - Windows daemon
- `platform/linux/scripts/sync-daemon.sh` - Linux daemon
- `bootstrap.ps1` / `bootstrap.sh` - Setup scripts
- `docs/plans/2026-01-23-machine-sync-auto-categorization-design.md` - Full design

---

*Pattern: Treat cross-machine sync as infrastructure - automate it once, benefit forever.*
