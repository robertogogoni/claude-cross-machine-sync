---
description: Supervised full system upgrade (pacman + AUR + omarchy) with intelligent package review
---

# Supervised System Update

You are performing a supervised full system upgrade. Execute each phase sequentially, providing status updates and catching issues before they cause problems.

## Phase 1: Pre-flight checks

Run these diagnostics in parallel:
- `free -h` and `swapon --show` to verify enough memory/swap
- `df -h /` to verify enough disk space
- `checkupdates 2>/dev/null` for official package updates
- `command yay -Qua 2>/dev/null` for AUR updates pending
- Check for pacman lock: `ls /var/lib/pacman/db.lck 2>/dev/null`
- Check for failed systemd units: `systemctl --failed --no-pager`

Present a summary table of what will be updated. If memory is critically low (free + available < 1GB), warn the user and suggest closing applications first.

**Stale pacman lock**: If `/var/lib/pacman/db.lck` exists but no pacman/yay process is running (`ps aux | grep -E "pacman|yay" | grep -v grep`), remove it: `sudo rm /var/lib/pacman/db.lck`

## Phase 2: Package review (CRITICAL)

Before running any update, review the pending packages for:

### 2a. Electron / Chromium source-build blockers

**This is the most important check.** Run:
```bash
command yay -Qua 2>/dev/null | awk '{print $1}' | grep -E '^electron[0-9]+$'
```

If ANY electron source package appears:
1. For each one (e.g., `electron33`), check if `-bin` variant exists: `command yay -Si electron33-bin`
2. Pre-install the `-bin` variant: `command yay -S electron33-bin --noconfirm`
3. Add it to `/etc/pacman.conf` IgnorePkg if not already there
4. Build the `--ignore` list for the yay command in Phase 4c

Also check what AUR package is pulling the electron dependency:
```bash
command yay -Qua 2>/dev/null | while read pkg _; do
    deps=$(command yay -Si "$pkg" 2>/dev/null | grep "Depends On" | grep -oE 'electron[0-9]+')
    [ -n "$deps" ] && echo "$pkg requires $deps"
done
```

### 2b. Other large AUR source builds
Flag any AUR package that builds from source and is known to be massive: chromium, firefox, libreoffice, rust, gcc, llvm, qt5-webengine, qt6-webengine. Suggest `-bin` alternatives.

### 2c. Kernel updates
If a kernel update is pending:
- Note that a reboot will be needed
- Verify `grep "^MODULES" /etc/mkinitcpio.conf` has `i915` (NOT nvidia modules)
- If nvidia modules appear, fix BEFORE proceeding

### 2d. Breaking changes
Check for major version bumps that could break dependencies.

## Phase 3: Create snapshot

```bash
sudo snapper create -d "pre-system-update $(date +%Y-%m-%d)" -c timeline 2>/dev/null || true
```

## Phase 4: Execute updates

Run in this order, stopping if any step fails. **Always use `command yay` and `sudo pacman` to bypass shell wrappers.**

### 4a. Keyring update
```bash
sudo pacman -Sy --noconfirm archlinux-keyring
```

### 4b. Official packages
```bash
sudo pacman -Syu --noconfirm
```

### 4c. AUR packages

Build the ignore list dynamically:
```bash
IGNORE_ELECTRON=$(command yay -Qua 2>/dev/null | awk '{print $1}' | grep -E '^electron[0-9]+$' | paste -sd,)
IGNORE_ALL="${IGNORE_ELECTRON}"
```

Then run:
```bash
command yay -Sua --noconfirm --cleanafter ${IGNORE_ALL:+--ignore "$IGNORE_ALL"}
```

**Critical**: Always use `command yay` to bypass the shell wrapper in ~/.bashrc.

If the build stalls (check with `ps aux | grep -E "git.*chromium|makepkg"`), kill it immediately:
```bash
pkill -9 -f "git.*chromium"; pkill -9 -f "makepkg.*electron"
```

### 4d. Omarchy updates
```bash
omarchy-update-available 2>/dev/null
```
If updates are available, run:
```bash
omarchy-update-git 2>/dev/null && omarchy-migrate 2>/dev/null
```

## Phase 5: Post-update verification

Run these checks in parallel:
- `systemctl --failed --no-pager` for failed units
- `tail -20 /var/log/pacman.log` for errors
- `pacman -Qdt` for orphaned packages (offer to remove if safe)
- `du -sh ~/.cache/yay/` and warn if over 10GB
- `bash ~/.config/omarchy/hooks/post-update` to re-apply customizations
- `grep "^MODULES" /etc/mkinitcpio.conf` must show `i915`, not nvidia
- `grep "^IgnorePkg" /etc/pacman.conf` to verify electron blocks are current
- Verify ai-usage overlay is working: `~/.local/libexec/ai-usage/ai-usage.sh 2>/dev/null | jq -r .text`

## Phase 6: Summary report

Present a final report with:
- Packages updated (count + names)
- Any warnings or issues found
- Whether a reboot is recommended
- Disk space before/after
- Cache cleanup recommendations

Log the summary:
```bash
cat >> ~/.claude/logs/system-updates.log << EOF
--- System Update: $(date -Iseconds) ---
[include: package list, issues, status]
EOF
```

## Rules

- NEVER build electron/chromium from source. Always use -bin variants.
- Always use `command yay` to bypass shell wrappers.
- If a build stalls or takes excessive memory, kill it immediately.
- Always create a btrfs snapshot before major updates.
- If mkinitcpio fails, fix MODULES array before finishing.
- When new electron versions appear in updates, pre-install the -bin variant AND add to IgnorePkg.
- Remove stale pacman locks only after verifying no package manager is running.
- Log everything to `~/.claude/logs/system-updates.log`.
