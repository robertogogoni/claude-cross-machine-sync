# System Persistence Status

**Date**: 2025-11-11  
**System**: Omarchy 3.1.7 on MacBook Air (Early 2015)

## ✅ All Configurations are Boot-Persistent

### Systemd Services (Auto-start on Boot)
- ✅ `cpupower-performance.service` - CPU always at max performance
- ✅ `kbd-backlight-restore.service` - Keyboard backlight set to 50% on boot
- ✅ `earlyoom.service` - Out-of-memory prevention
- ✅ `irqbalance.service` - CPU interrupt distribution
- ✅ `ollama.service` - AI runtime
- ✅ `paccache.timer` - Weekly package cache cleanup
- ✅ `reflector.timer` - Weekly mirror list updates

### System Configuration Files
- ✅ `/etc/sysctl.d/99-swappiness.conf` - Swappiness set to 10
- ✅ `/etc/systemd/zram-generator.conf` - Compressed RAM swap (3.8GB)
- ✅ `/etc/modprobe.d/hid_apple.conf` - Apple keyboard/trackpad options

### Hyprland Configuration Files
- ✅ `~/.config/hypr/input.conf` - Touchpad gestures and input settings
- ✅ `~/.config/hypr/bindings.conf` - Keyboard shortcuts (F5/F6 backlight)
- ✅ `~/.config/hypr/envs.conf` - Wayland environment variables
- ✅ `~/bin/kbd-backlight` - Keyboard backlight OSD script

## 🔧 Recent Fixes Applied

### 1. Hyprland input.conf Syntax Fix
**Issue**: Deprecated `windowrule = scrolltouchpad` syntax  
**Fix**: Removed deprecated windowrule, added `scroll_factor` to input block  
**Status**: ✅ Fixed and reloaded successfully

### 2. Configuration Validation
**Check**: All config files validated with `hyprctl reload`  
**Result**: ✅ No errors, configuration valid

## ⚠️ Requires Reboot

### Kernel Module Parameters (Not Yet Active)
The following setting in `/etc/modprobe.d/hid_apple.conf` requires a reboot:
- `swap_opt_cmd=1` - Swaps Alt/Command keys for PC keyboard layout

**Current Status**:
- `fnmode=2` ✅ Already active (F-keys work as F1-F12 by default)
- `swap_opt_cmd=1` ⚠️ Not active yet (currently at 0)

**To Apply**: Run `systemctl reboot`

## 🛠️ Verification Scripts

### Check All Persistence Settings
```bash
~/bin/check-persistence
```
Shows status of all services, config files, and runtime values.

### Check Current System Status
```bash
~/bin/sysstatus
```
Shows CPU, memory, swap, backlight, and top processes.

## 📋 What Happens After Reboot

All optimizations will automatically restore:
1. **CPU Performance** - All cores at maximum frequency
2. **Memory** - Swappiness=10, zram active
3. **Keyboard Backlight** - Restored to 50% brightness
4. **Apple Keyboard** - Alt/Command keys swapped *(NEW)*
5. **Services** - All optimization services running
6. **Hyprland** - All customizations and keybindings active

## 🎯 Post-Reboot Verification

After rebooting, run:
```bash
~/bin/check-persistence
```

Everything should show ✅ with no ✗ or ⚠️ markers.

## 📝 Notes

- All services are enabled for automatic start
- All configuration files are in system/user config directories
- Hyprland config has no errors or warnings
- Ready for reboot - no data loss risk
- Reboot recommended to apply Alt/Command key swap

---

**System Ready**: All optimizations are persistent and will survive reboot.  
**Action Required**: Reboot to apply final kernel module parameter.
