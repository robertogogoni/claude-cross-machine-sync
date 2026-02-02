# Beeper Package Conflict Fix

**Date**: 2026-02-02
**Problem**: System updates (`omarchy-update` / `yay -Syu`) fail with "file exists in filesystem" errors
**Root Cause**: Conflict between `update-beeper` script and `beeper-v4-bin` AUR package

## The Issue

When running system updates via `yay -Syu`, the following error occurs:

```
beeper-v4-bin: /opt/beeper/resources/app/build/main/get-machine-id-CVfpM0VY.mjs exists in filesystem
beeper-v4-bin: /opt/beeper/resources/app/build/main/http-DtFe5-ea.mjs exists in filesystem
... (75+ more file conflicts)
Errors occurred, no packages were upgraded.
```

### Why This Happens

1. **`beeper-v4-bin`** (AUR package) installs Beeper to `/opt/beeper` and registers files with pacman
2. **`update-beeper`** (custom script) downloads newer versions directly from Beeper API and overwrites the same files
3. Pacman detects the files have been modified outside its control
4. When yay tries to update `beeper-v4-bin`, pacman refuses to overwrite "foreign" files

## The Solution

### 1. Remove AUR Package (One-Time Fix)

```bash
# Remove the AUR package - files will be deleted but we have backups
sudo pacman -Rdd --noconfirm beeper-v4-bin

# Restore from backup (update-beeper maintains backups at /opt/beeper-backups/)
sudo cp -a /opt/beeper-backups/beeper-backup-YYYYMMDD-HHMMSS/* /opt/beeper/

# Or reinstall fresh with update-beeper
update-beeper --force
```

### 2. Prevent Future Conflicts

Modified `/home/rob/.local/share/omarchy/bin/omarchy-update-system-pkgs` line 12:

```bash
# Before:
yay -Sua --noconfirm --ignore gcc14,gcc14-libs

# After:
yay -Sua --noconfirm --ignore gcc14,gcc14-libs,beeper-v4-bin
```

### 3. Migration Script for Other Machines

Created `/home/rob/.local/share/omarchy/migrations/1770031300.sh` to automatically remove the AUR package during omarchy updates.

## Verification

```bash
# Verify AUR package is removed
pacman -Q beeper-v4-bin  # Should say "not found"

# Verify Beeper still works
/opt/beeper/beepertexts --version
# Or check package.json
grep '"version"' /opt/beeper/resources/app/package.json

# Verify files are unowned (managed by update-beeper)
pacman -Qo /opt/beeper/beepertexts  # Should say "No package owns"

# Test system update
yay -Sua --noconfirm  # Should work without beeper errors
```

## Why update-beeper Instead of AUR?

| Feature | update-beeper | beeper-v4-bin (AUR) |
|---------|---------------|---------------------|
| Update speed | Immediate (API) | Delayed (AUR lag) |
| Wayland fixes | Built-in | Manual |
| Auto-rollback | Yes | No |
| Self-healing | Yes | No |
| Sleep/wake fix | Yes | No |

## Related Files

- `/tmp/update-beeper-work/update-beeper` - The update script
- `/opt/beeper/` - Installation directory
- `/opt/beeper-backups/` - Automatic backups
- `/home/rob/.local/share/omarchy/bin/omarchy-update-system-pkgs` - Modified to ignore beeper-v4-bin
- `/home/rob/.local/share/omarchy/migrations/1770031300.sh` - Migration script

## Key Insight

**Pacman's `-Rdd` flag does NOT keep files** - it only skips dependency checks. To truly "orphan" files (keep them but remove pacman tracking), you would need to manually delete the package database entry, which is not recommended. The proper solution is to let pacman remove the package, then reinstall via the preferred method (update-beeper).
