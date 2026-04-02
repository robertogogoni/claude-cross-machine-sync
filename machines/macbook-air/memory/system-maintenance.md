# System Maintenance — MacBook Air (Arch Linux)

Last run: 2026-03-02

## Diagnostic Commands Cheatsheet

```bash
# Failed services
systemctl --failed && systemctl --user --failed

# Journal errors (24h)
journalctl --priority=0..3 --since "24 hours ago" --no-pager -q

# Coredumps (7 days)
coredumpctl list --since "7 days ago"

# Disk usage
df -h / /home /boot
sudo btrfs filesystem usage /

# Orphaned packages
pacman -Qtdq

# Available updates
checkupdates

# Package cache size
sudo du -sh /var/cache/pacman/pkg/

# Journal size
journalctl --disk-usage

# Broken symlinks in /etc
find /etc -xtype l 2>/dev/null
```

## Filesystem Layout (btrfs)

| Subvolume | Mount | Purpose |
|-----------|-------|---------|
| `/@` | `/` | Root |
| `/@home` | `/home` | User data |
| `/@pkg` | `/var/cache/pacman/pkg` | Package cache |
| `/@log` | `/var/log` | Logs |

Options: `rw,noatime,compress=zstd:3,ssd,space_cache=v2,discard=async`

Boot: FAT32 (`/dev/sda1`) at `/boot` with `fmask=0077,dmask=0077` (root-only)

## Active Maintenance Timers

| Timer | Frequency | Purpose |
|-------|-----------|---------|
| `snapper-timeline` | hourly | btrfs snapshots |
| `snapper-cleanup` | hourly | snapshot cleanup |
| `paccache` | weekly (Mon) | clean old package cache |
| `reflector` | weekly (Mon) | update mirrorlist |
| `pamac-cleancache` | biweekly | pamac cache cleanup |
| `systemd-tmpfiles-clean` | daily | clean /tmp |
| `plocate-updatedb` | daily | update file index |
| `man-db` | daily | update man page cache |

User timers:
| Timer | Frequency | Purpose |
|-------|-----------|---------|
| `omarchy-battery-monitor` | 30s | battery alerts |
| `beeper-health` | 5min | beeper health check |
| `chrome-canary-permissions` | 5min | fix chrome perms |
| `beeper-mcp-renewal` | 6h | renew MCP token |
| `update-beeper` | 12h | check beeper updates |
| `beeper-check` | daily | beeper version check |

## Known Harmless Errors (suppress/ignore)

| Error | Source | Why | Fix |
|-------|--------|-----|-----|
| `Failed to find module 'nvidia_uvm'` | systemd-modules-load | nvidia-utils installed but no NVIDIA GPU | Blacklisted in `/etc/modprobe.d/no-nvidia.conf` |
| `Failed to set default system config for hci0` | bluetoothd | Apple Bluetooth adapter quirk | Harmless, service runs fine |
| `Duplicate name 'org.freedesktop.Notifications'` | dbus-broker | KDE notifications service file conflict | Cosmetic, no impact |
| `ERROR @wl_cfg80211_scan` | kernel (Broadcom wifi) | Intermittent Broadcom driver scan error | Self-recovers |
| `gkr-pam: couldn't unlock the login keyring` | sddm-helper | GNOME Keyring unlock at SDDM login | Not using GNOME Keyring |

## Optimization Actions Performed (2026-02-26)

### 1. Purged coredumps: 566MB -> 4KB
```bash
sudo find /var/lib/systemd/coredump/ -type f -delete
```

### 2. Trimmed journal: 1.1GB -> 196MB
```bash
sudo journalctl --vacuum-size=200M
```
Permanent limit set:
- File: `/etc/systemd/journald.conf.d/size.conf`
- Content: `[Journal]\nSystemMaxUse=200M`

### 3. Cleaned 58 stale pacman download dirs
```bash
sudo rm -rf /var/cache/pacman/pkg/download-*
```
These are leftover partial downloads from interrupted pacman operations.

### 4. Fixed /boot permissions (security)
Problem: FAT32 ignores `chmod`. Must use fstab mount masks.
```bash
# /etc/fstab: changed fmask=0022,dmask=0022 -> fmask=0077,dmask=0077
# Then: sudo umount /boot && sudo mount /boot
# NOTE: `mount -o remount` does NOT pick up fstab mask changes for vfat!
#       Must do full unmount/mount cycle.
```

### 5. Blacklisted nvidia_uvm module
File: `/etc/modprobe.d/no-nvidia.conf`
```
blacklist nvidia_uvm
install nvidia_uvm /bin/true
```

### 6. Reset failed beeper-check service
```bash
systemctl --user reset-failed beeper-check.service
```
Exit code 28 = curl timeout reaching Beeper update server. Timer will retry.

## Optimization Actions Performed (2026-03-02)

### 7. Resolved stuck git rebase in omarchy source
```bash
cd ~/.local/share/omarchy && git rebase --skip
```
Local commit a6aef583 conflicted with upstream. See [omarchy-update-pipeline.md](omarchy-update-pipeline.md).

### 8. Removed self-managed Claude Code binary (~652MB freed)
```bash
rm ~/.local/bin/claude  # symlink to self-managed
rm -rf ~/.local/share/claude/  # old versioned binaries (2.1.55, 2.1.56, 2.1.59)
```
Now using AUR `claude-code` package only. See [omarchy-update-pipeline.md](omarchy-update-pipeline.md).

### 9. Moved custom scripts to safe location
```bash
cp ~/.local/share/omarchy/bin/omarchy-scale-switcher ~/.local/bin/
cp ~/.local/share/omarchy/bin/omarchy-smart-screensaver ~/.local/bin/
```

### 10. Deregistered stale beeper-v4-bin pacman tracking
Direct-installed Beeper was newer than pacman DB entry, causing yay conflicts.
Fixed via update-beeper v1.6.0 `deregister_pacman_tracking()`. See [update-beeper.md](update-beeper.md).

## Important Gotchas

### vfat /boot permissions
`chmod` has NO effect on FAT32 partitions. Permissions are set via `fmask`/`dmask` in fstab at mount time. And `mount -o remount` does NOT apply new fmask/dmask — you must `umount` then `mount`.

### nvidia-utils without NVIDIA GPU
Package `nvidia-utils` (590.48.01) is installed despite no NVIDIA hardware. Likely a dependency chain. Module blacklisted rather than removing the package to avoid breaking deps.

### pacman -Rdd removes files AND DB entry
`pacman -Rdd --noconfirm <pkg>` is NOT "database-only removal". It removes the package files too. To remove only the DB entry, move files aside first, then run -Rdd, then restore files. See [update-beeper.md](update-beeper.md).

### dmesg requires root
`dmesg` returns "Operation not permitted" for non-root users. Use `sudo dmesg` or check `journalctl -k` instead.

### Dual Claude Code installations
If both AUR (`/usr/bin/claude`) and self-managed (`~/.local/bin/claude`) exist, they compete. The AUR wrapper sets `DISABLE_AUTOUPDATER=1`. Keep only one — currently AUR. Set `"autoUpdates": false` in `~/.claude.json`.

### omarchy source git conflicts
Never commit directly to `~/.local/share/omarchy/`. It's a git repo pulled by `omarchy-update-git`. Local commits cause rebase conflicts. Custom scripts go in `~/.local/bin/`.

## Disk Baseline (2026-02-26 post-cleanup)

| Metric | Value |
|--------|-------|
| Root `/` | 72G/111G (66%) |
| `/boot` | 98M/2G (5%) |
| Journal | 196MB (capped 200MB) |
| Coredumps | ~0 |
| Pacman cache | 4.7MB |
| `~/Downloads` | 13GB (manual cleanup candidate) |
| Free space | ~37GB |
