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
- `yay -Qua 2>/dev/null` for AUR updates pending
- Check for pacman lock: `ls /var/lib/pacman/db.lck 2>/dev/null`
- Check for failed systemd units: `systemctl --failed --no-pager`

Present a summary table of what will be updated. If memory is critically low (free + available < 1GB), warn the user and suggest closing applications first.

## Phase 2: Package review (CRITICAL)

Before running any update, review the pending packages for:

1. **Source-build blockers**: Any `electron*` package that is NOT a `-bin` variant MUST be skipped. Check `grep IgnorePkg /etc/pacman.conf` and verify the ignore list covers all electron versions in the update. If a new electron version (e.g., electron36) appears that isn't in IgnorePkg, ADD it before proceeding.

2. **Large AUR builds**: Flag any AUR package that builds from source and is known to be extremely large (chromium, electron, firefox, libreoffice, rust, gcc, llvm). Suggest `-bin` alternatives if available.

3. **Kernel updates**: If a kernel update is pending, note that a reboot will be needed and verify `/etc/mkinitcpio.conf` has the correct MODULES (should have `i915`, NOT nvidia modules).

4. **Breaking changes**: Check if any package has a major version bump that could break dependencies.

## Phase 3: Create snapshot

If btrfs snapshots are available:
```bash
sudo snapper create -d "pre-system-update $(date +%Y-%m-%d)" -c timeline 2>/dev/null || true
```

## Phase 4: Execute updates

Run in this order, stopping if any step fails:

### 4a. Keyring update
```bash
sudo pacman -Sy --noconfirm archlinux-keyring
```

### 4b. Official packages
```bash
sudo pacman -Syu --noconfirm
```

### 4c. AUR packages
```bash
yay -Sua --noconfirm --cleanafter
```

If yay prompts about replacing packages or conflicts, pause and explain the situation before proceeding.

### 4d. Omarchy updates (if available)
Check if omarchy updates are pending:
```bash
omarchy-update-available 2>/dev/null
```
If updates are available, run:
```bash
omarchy-update-git 2>/dev/null && omarchy-migrate 2>/dev/null
```

## Phase 5: Post-update verification

Run these checks in parallel:
- Verify no failed systemd units: `systemctl --failed`
- Verify mkinitcpio didn't break: check for errors in pacman log `tail -30 /var/log/pacman.log`
- Check for orphaned packages: `pacman -Qdt`
- Check yay cache size: `du -sh ~/.cache/yay/` and warn if over 10GB
- Run omarchy post-update hook if it exists: `~/.config/omarchy/hooks/post-update`
- Verify MODULES in `/etc/mkinitcpio.conf` still correct (i915, no nvidia)

## Phase 6: Summary report

Present a final report with:
- Packages updated (count + names)
- Any warnings or issues found
- Whether a reboot is recommended (kernel/driver updates)
- Disk space before/after
- Cache cleanup recommendations

## Rules

- NEVER build electron/chromium from source. Always use -bin variants.
- If a build stalls or takes excessive memory, kill it immediately.
- Always create a btrfs snapshot before major updates.
- If mkinitcpio fails, fix it before finishing (check MODULES array).
- Log everything: append a summary to `~/.claude/logs/system-updates.log` with timestamp.
