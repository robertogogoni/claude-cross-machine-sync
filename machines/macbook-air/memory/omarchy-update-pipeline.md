# Omarchy Update Pipeline & Recovery

Last updated: 2026-03-02

## Update Chain

```
omarchy-update
├── omarchy-update-git              # git pull --autostash in ~/.local/share/omarchy/
├── omarchy-update-perform          # runs the update sequence (wraps in `script` for PTY)
│   ├── omarchy-update-keyring      # refresh pacman keyring
│   ├── omarchy-update-available-reset
│   ├── omarchy-update-system-pkgs  # sudo pacman -Syu
│   ├── omarchy-migrate             # run pending migrations from migrations/*.sh
│   ├── omarchy-update-aur-pkgs     # yay -Sua --noconfirm
│   ├── omarchy-update-orphan-pkgs  # pacman -Rns orphans
│   ├── omarchy-hook post-update    # runs ~/.config/omarchy/hooks/post-update
│   ├── omarchy-update-analyze-logs
│   └── omarchy-update-restart      # restart waybar etc.
└── (TTY confirmation prompt — blocks in non-interactive shells)
```

**Non-interactive workaround**: Run individual steps directly (`omarchy-update-git`, then `yay -Syu --noconfirm`, then `omarchy-migrate`). The top-level `omarchy-update` requires a TTY for its gum confirmation prompt.

## Key Directories

| Path | Purpose | Writable? |
|------|---------|-----------|
| `~/.local/share/omarchy/` | Git-managed source (scripts, configs, themes) | READ ONLY for users |
| `~/.config/omarchy/` | User customization (hooks, themes) | YES |
| `~/.local/bin/` | User scripts safe from omarchy updates | YES |
| `~/.config/hypr/` | Hyprland config (auto-reloads on save) | YES |

## Post-Update Hook

File: `~/.config/omarchy/hooks/post-update`
```bash
#!/bin/bash
if command -v update-beeper &>/dev/null; then
  echo -e "\e[32m\nCheck Beeper updates\e[0m"
  update-beeper --quiet 2>/dev/null || true
fi
```

## Git Rebase Recovery (omarchy source)

When `omarchy-update-git` fails due to rebase conflicts in `~/.local/share/omarchy/`:

### Diagnosis
```bash
cd ~/.local/share/omarchy
git status  # Shows "rebase in progress" or conflict markers
```

### Fix: Skip the conflicting local commit
```bash
cd ~/.local/share/omarchy
git rebase --skip   # Drops the local commit that conflicts with upstream
```

### Fix: Stash conflicts after rebase
```bash
git stash pop  # May fail with conflicts
git checkout --theirs <file>  # Take upstream version
git restore --staged <file>
git stash drop  # Clean up
```

### Root Cause (2026-03-02)
Local commit `a6aef583` (beeper-v4-bin fix) conflicted with upstream's refactored update scripts. The `omarchy-update-system-pkgs` file had `<<<<<<< HEAD` merge conflict markers, blocking all future updates.

**Prevention**: Never commit to `~/.local/share/omarchy/` directly. Custom scripts belong in `~/.local/bin/`.

## Custom Scripts Safety

Scripts originally in `~/.local/share/omarchy/bin/` must be copied to `~/.local/bin/` to survive updates:

| Script | Purpose |
|--------|---------|
| `omarchy-scale-switcher` | Display scaling toggle |
| `omarchy-smart-screensaver` | Smart screensaver |

## Claude Code Installation (AUR only)

As of 2026-03-02, Claude Code is managed solely by the AUR `claude-code` package:

| Component | Path |
|-----------|------|
| Binary | `/usr/bin/claude` (wrapper script) |
| Actual binary | `/opt/claude-code/bin/claude` |
| Version | 2.1.90 (updated 2026-04-02) |
| Updater | `DISABLE_AUTOUPDATER=1` (AUR handles it via yay) |

**Previous self-managed binary** at `~/.local/share/claude/versions/` was removed (freed ~652MB).

**Important**: `~/.claude.json` should have `"autoUpdates": false` and `"installMethod": "native"` to prevent the self-managed updater from reinstalling.

## Beeper Desync Problem

When `update-beeper` does a direct download install, pacman still tracks the old AUR `beeper-v4-bin` version. This causes `yay -Sua` to try updating a package that's already newer on disk.

**Fix (v1.6.0)**: `deregister_pacman_tracking()` — moves files aside, removes pacman DB entry with `pacman -Rdd`, restores files.

**Critical**: `pacman -Rdd` removes BOTH database entry AND files. Must move files out first.
