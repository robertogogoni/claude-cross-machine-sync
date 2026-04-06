---
name: System crash fix and display upgrade 2026-04-04
description: Hyprland crash loop fixed (aquamarine UAF), hypridle disabled, TV 1080p upgrade pending reboot with AQ_NO_ATOMIC
type: project
---

## What happened

Overnight crash loop (6 boots, 2 hard crashes) caused by two chained issues:

### 1. Hyprland SEGV in SDRMConnector::disconnect() (FIXED)
- DPMS off triggered aquamarine use-after-free: CLogger destroyed before DRM connector tried to log through it
- Fix: Rebuilt aquamarine from main branch (commit e926559, includes PR #244 UAF fix)
- Installed at `/usr/lib/libaquamarine.so.9` (soname compatible, drop-in replacement)
- **Pinned in `/etc/pacman.conf` IgnorePkg** to prevent regression until upstream releases > v0.10.0

### 2. Memory pressure cascade (MITIGATED)
- journald hit memory pressure → watchdog timeout → SIGKILL → couldn't restart → cascading failures
- upower (omarchy-battery-monitor) segfaulted when D-Bus died
- Fix: Created `/etc/systemd/journald.conf.d/resilient.conf` (SystemMaxUse=256M, RuntimeMaxUse=64M)

### 3. hypridle disabled (USER REQUEST)
- User doesn't want idle lock, DPMS, or suspend
- TV (LG via HDMI) doesn't wake from DPMS off (HDMI CEC/DPMS impedance mismatch)
- hypridle: stopped, disabled, AND masked (`~/.config/systemd/user/hypridle.service` → `/dev/null`)

## TV 1080p upgrade (PENDING REBOOT)

### Root cause of 1080p failure
NOT a TMDS clock issue. Haswell source max is 300 MHz, TV sink max 150 MHz, 1080p needs 148.5 MHz — passes validation.

**Actual bug**: aquamarine atomic test-commit sends old primary plane dimensions (1360x768) when testing new CRTC mode (1920x1080). Kernel's `intel_plane_check_clipping()` rejects because primary plane must cover entire CRTC.

Kernel error: `[PLANE:50:primary B] plane (1360x768+0+0) must cover entire CRTC (1920x1080+0+0)`

### Staged fix (requires reboot)
- `~/.config/hypr/envs.conf`: Added `AQ_NO_ATOMIC=1` (uses legacy DRM path, bypasses atomic test-commit)
- `~/.config/hypr/monitors.conf`: Changed to `monitor=HDMI-A-1,1920x1080@60,auto-left,1`

### Rollback if 1080p fails after reboot
```bash
sed -i '/AQ_NO_ATOMIC/d' ~/.config/hypr/envs.conf
sed -i 's|1920x1080|1360x768|' ~/.config/hypr/monitors.conf
systemctl reboot
```

### Session restart constraint
- SDDM with autologin (User=robthepirate, Session=hyprland-uwsm)
- `hyprctl dispatch exit` drops to TTY with no graphical recovery (SDDM autologin only fires at boot)
- Must use `systemctl reboot` to safely restart the graphical session

## Related upstream issues
- aquamarine #244 (UAF fix, merged)
- aquamarine #59, Hyprland #6953, #8758 (atomic test-commit plane size bug)
- Potential to file new aquamarine issue with kernel trace evidence

**Why:** Track what was done and how to rollback if needed.
**How to apply:** All items COMPLETED as of 2026-04-05. TV boots at 1080p via custom EDID. AQ_NO_ATOMIC removed. Crash loop not recurring (verified clean boot 2026-04-05). Rollback commands above still valid if regression occurs.
