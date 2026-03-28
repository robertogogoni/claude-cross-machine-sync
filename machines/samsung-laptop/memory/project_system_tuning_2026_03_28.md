---
name: System performance tuning applied 2026-03-28
description: VM tunables for zram, disk swap overflow, nvidia fix, mkinitcpio fix applied to Samsung laptop
type: project
---

Comprehensive system health fixes applied 2026-03-28:

**Memory/Swap:**
- zram-optimized VM tunables in `/etc/sysctl.d/90-zram-tuning.conf`: swappiness=150, vfs_cache_pressure=150, page-cluster=0, watermark_boost_factor=0, watermark_scale_factor=125
- 4GB disk swap overflow at `/swap/swapfile` (btrfs subvolume, priority 10, zram priority 100). Added to fstab.

**NVIDIA GPU fix:**
- nvidia-open-dkms removed (GF117M/GeForce 710M not supported by open driver, needs GSP)
- Blacklisted nvidia/nvidia_drm/nvidia_modeset/nvidia_uvm/nouveau in `/etc/modprobe.d/nvidia.conf`
- mkinitcpio.conf MODULES changed from nvidia stack to `i915` (Intel HD 4400 is the actual GPU)
- Initramfs regenerated successfully

**Disk cleanup:**
- Removed 104.6GB of stale yay build caches (electron25: 101GB, electron24: 331MB, nodejs-lts-hydrogen: 2.7GB)

**Why:** System was hitting 100% zram swap with only 303MB free RAM, caused by Chrome Canary (34 renderers, 6.4GB), a stalled Chromium source build, and suboptimal VM defaults.

**How to apply:** These are persistent system configs. On kernel updates, verify mkinitcpio still has `i915` not nvidia. Monitor Chrome memory usage (primary resource hog).
