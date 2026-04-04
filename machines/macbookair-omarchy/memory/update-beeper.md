# update-beeper — Self-Healing Beeper Updater

Last updated: 2026-04-03

## Overview

| Property | Value |
|----------|-------|
| Version | 1.8.0 |
| Location | `~/.local/bin/update-beeper` |
| Repo | `beeper-community/update-beeper` (GitHub) |
| Local clone | `~/repos/update-beeper/` |
| Language | Bash (~1600 lines) |
| License | MIT |

## Two-Tier Update Strategy

```
1. Try AUR (yay -S beeper-v4-bin)
   └── Success → done
   └── Fail → fallback to direct download

2. Direct download from Beeper CDN
   └── Downloads .deb, extracts, installs to /opt/Beeper/
   └── Then deregisters pacman tracking to prevent desync
   └── Then preserves runtime deps from orphan cleanup (v1.7.0)
```

## Key Functions

### `deregister_pacman_tracking()` (v1.6.0)
Prevents pacman/AUR desync after direct install:
1. `sudo mv /opt/Beeper /opt/Beeper-deregister-tmp`
2. `sudo pacman -Rdd --noconfirm beeper-v4-bin` (removes DB entry; files already moved)
3. `sudo mv /opt/Beeper-deregister-tmp /opt/Beeper` (restore files)
4. Calls `preserve_runtime_deps` (v1.7.0)

### `preserve_runtime_deps()` (v1.7.0)
Prevents orphan cleanup from removing Beeper's runtime dependencies after pacman deregistration:
- Iterates `BEEPER_RUNTIME_DEPS` array (`libappindicator libnotify libsecret hicolor-icon-theme`)
- Checks each dep's install reason via `pacman -Qi`
- If reason is "dependency" (not "explicitly installed"), runs `pacman -D --asexplicit` (DB-only, no download)
- Logs count of preserved deps

### `perform_update()`
Main update logic. On successful direct install, calls `deregister_pacman_tracking()` if `PACMAN_TRACKED=true`.

### `install_icon()` (v1.8.0)
Copies bundled 512px icon from `/opt/beeper/usr/share/icons/hicolor/512x512/apps/beepertexts.png` to `~/.local/share/icons/hicolor/512x512/apps/`. Runs `gtk-update-icon-cache` to refresh. Idempotent via `cmp -s`.

### `setup_wayland_desktop_override()` (rewritten v1.8.0)
- Sources from bundled `/opt/beeper/beepertexts.desktop` (not system file)
- Creates `beeper-wayland.desktop` (not `beeper.desktop`)
- Detects `~/bin/beeper-wayland` wrapper and uses it if present
- Falls back to generating desktop file from scratch
- Stamps `X-AppImage-Version` from `package.json`
- Calls `cleanup_stale_desktop_files()` to remove old `beeper.desktop`/`beepertexts.desktop`

### `validate_desktop_entry()` (v1.8.0)
Checks desktop shortcut health using `check_add`/`check_flush` pattern:
1. Desktop file exists
2. Exec binary resolves and is executable
3. Version matches installed (via X-AppImage-Version)
4. Icon resolves in hicolor theme
5. No stale duplicate desktop files

### `cleanup_stale_desktop_files()` (v1.8.0)
Removes leftover `beeper.desktop` and `beepertexts.desktop` from user applications dir.

## CLI Options

```bash
update-beeper                # Normal update check
update-beeper --force        # Force reinstall
update-beeper --quiet        # Minimal output (for cron/hooks)
update-beeper --check        # Check only, don't install
update-beeper --check-desktop # Validate desktop shortcut and icon
update-beeper --version      # Show version
```

## Companion Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `beeper-version` | `~/.local/bin/beeper-version` | Quick version status (installed/latest/AUR) |
| `beeper-health` | `~/.local/bin/beeper-health` | Process health check + `--desktop` flag delegates to update-beeper |
| `jarvis-beeper` | `~/repos/update-beeper/jarvis-beeper` | Natural language interface ("check desktop", "update beeper") |

## Integration Points

| Where | How |
|-------|-----|
| omarchy post-update hook | `~/.config/omarchy/hooks/post-update` runs `update-beeper --quiet` |
| systemd timer | `update-beeper.timer` — checks every 12h |
| beeper-health --desktop | Delegates to `update-beeper --check-desktop` |
| Manual | `update-beeper` or `update-beeper --force` |

## Desktop Shortcut Management (v1.8.0)

| Path | Purpose |
|------|---------|
| `~/.local/share/applications/beeper-wayland.desktop` | Active desktop shortcut (Wayland) |
| `~/.local/share/icons/hicolor/512x512/apps/beepertexts.png` | Launcher icon (copied from bundled) |
| `~/bin/beeper-wayland` | Wrapper script (XWayland mode with GPU disabled) |
| `/opt/beeper/beepertexts.desktop` | Bundled source desktop file (from AppImage) |

**Key gotcha**: `set -e` + `grep -oP` returning exit 1 on no match kills the script. All greps in `validate_desktop_entry()` need `|| true`.

## Critical Gotcha: pacman -Rdd

`pacman -Rdd --noconfirm <pkg>` removes **files AND database entry**, not just the DB entry. This is why `deregister_pacman_tracking()` moves files out of the way first.

## Critical Gotcha: Orphaned Dependencies (fixed in v1.7.0)

When `deregister_pacman_tracking()` removes `beeper-v4-bin` from pacman's DB, its dependencies (installed as "dependency" reason) become orphans. System update orphan cleanup (`pacman -Rns $(pacman -Qdtq)`) then silently removes them. `libappindicator` is most vulnerable — it typically has NO other dependents. Fix: `pacman -D --asexplicit` marks deps as explicitly installed (DB-only operation, no download/reinstall).

## GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `update-version-badge.yml` | Daily 6AM UTC | Detects Beeper version via API redirect, updates badge JSON |
| `lint.yml` | Push/PR | ShellCheck + bash -n on all scripts |
| `test-install.yml` | install.sh changes | Tests local + remote install paths |
| `version-check.yml` | update-beeper/CHANGELOG changes | Validates SCRIPT_VERSION ≥ latest tag |
| `release.yml` | Tag `v*.*.*` | Creates GitHub release with changelog excerpt |
| `checksums.yml` | Script changes / release | Regenerates checksums.sha256 |

## GitHub Releases

| Tag | Commit | Status | URL |
|-----|--------|--------|-----|
| v1.6.0 | `4a81fb9084c2a6ec4db9cd4788f14eefea688621` | Released | `beeper-community/update-beeper/releases/tag/v1.6.0` |
| v1.7.0 | `33318aaf7a51353f6928dfd8e101a6e9a16581ee` | Released | `beeper-community/update-beeper/releases/tag/v1.7.0` |
| v1.8.0 | `e935af2` | Released | `beeper-community/update-beeper/releases/tag/v1.8.0` |

## Release Process Gotchas

- `gh release create --target` requires **full 40-char SHA** — short SHAs cause 422 Validation Failed
- Parallel `gh release create` calls can fail with 504 Gateway Timeout — create releases sequentially
- install.sh always fetches from `master` branch raw URL — no version-specific edits needed for releases
- Full release checklist: code → CHANGELOG → README → install.sh review → profile README → GitHub releases

## Current State (2026-04-03)

- Beeper version: 4.2.692 (direct install)
- update-beeper version: 1.9.0 (interactive CLI, branch support, beeper-intel)
- pacman tracking: deregistered
- Install location: `/opt/beeper/`
- Runtime deps: preserved as explicit (v1.7.0)
- Desktop shortcut: `beeper-wayland.desktop` → `~/bin/beeper-wayland` (validated, icon installed)
- GitHub releases: v1.6.0 + v1.7.0 + v1.8.0 live
- beeper-kb: 1,054 docs, 312 vectors (deep harvest Apr 3)
