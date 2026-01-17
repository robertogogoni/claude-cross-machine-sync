# MacBook SPI Driver - Kernel Upgrade Monitoring Plan

**Date Created:** December 19, 2025  
**Current Status:** Kernel 6.17.9 with macbook12-spi-driver-dkms 0+git.315-1

## Current Situation

- **Kernel Version:** 6.17.9-arch1-1
- **Driver Version:** macbook12-spi-driver-dkms 0+git.315-1 (built Sept 12, 2025)
- **Driver Source:** marc-git/macbook12-spi-driver (AUR package)
- **Issue:** Driver fails to compile with kernel 6.11+ due to kernel API changes

## Known Issues with Recent Kernels

### Kernel 6.11+ Build Failures
<cite index="11-8,24-1">The driver fails to build with kernel 6.11+ due to incompatible pointer types in platform driver removal functions</cite>. Specific errors include:
- `apple-ib-tb.c`: incompatible pointer type for `.remove` function
- `apple-ib-als.c`: incompatible pointer type for `.remove` function  
- `apple-ibridge.c`: missing `owner` member in struct acpi_driver

### Kernel 6.0+ Issues
<cite index="24-2,24-4">Since Linux 6.0, there have been persistent issues building this driver</cite>, including:
- Incomplete type errors with `struct efivar_entry`
- Missing function declarations for `efivar_entry_set_safe`

## Sources to Monitor

### 1. AUR Package Page
- **URL:** https://aur.archlinux.org/packages/macbook12-spi-driver-dkms
- **What to check:** Package updates, comments section for build success reports
- **Frequency:** Weekly

### 2. GitHub Repositories

#### Primary Fork (Currently Broken for 6.11+)
- **marc-git/macbook12-spi-driver** (touchbar-driver-hid-driver branch)
- URL: https://github.com/marc-git/macbook12-spi-driver
- What to check: Commits, issues, pull requests for kernel 6.11+ fixes

#### Active Working Fork (6.12 Compatible)
- **Heratiki/macbook12-spi-driver**
- URL: https://github.com/Heratiki/macbook12-spi-driver
- <cite index="21-6,21-14">This fork reportedly works with kernel 6.12.10-arch1-1</cite>
- Status: Compiles successfully but may require specific initialization steps

#### Other Important Forks
- **roadrunner2/macbook12-spi-driver** (original touchbar driver author)
  - URL: https://github.com/roadrunner2/macbook12-spi-driver
  - Check PR #70 for community fixes: https://github.com/roadrunner2/macbook12-spi-driver/pull/70

- **PatrickVerner/macbook12-spi-driver**
  - Has patches for kernels 5.9, 5.13, 5.14
  - May have additional compatibility fixes

### 3. Community Forums

#### Arch Linux Forums
- **Recent thread:** https://bbs.archlinux.org/viewtopic.php?id=309376
- <cite index="23-2,23-9">User successfully got touchbar working with kernel 6.12 LTS using Heratiki's fork</cite>
- Search terms: "macbook12-spi-driver", "macbook touchbar", "kernel 6.18"

#### Reddit
- r/archlinux
- r/linux
- Search: "macbook spi driver arch"

### 4. Maintainer Status
<cite index="11-6,11-21">The AUR package maintainer no longer has hardware to test and is seeking new maintainer</cite>. This means updates may be slower.

## Upgrade Criteria - When It's Safe to Upgrade

**DO NOT upgrade to kernel 6.18+ until ALL of the following are met:**

### Critical Requirements
1. ✅ **Confirmed Working Build**
   - At least 3 independent users report successful driver compilation AND operation
   - Reports must be from Arch Linux specifically (not other distros)
   - Reports must be on kernel 6.18 or newer

2. ✅ **Available Patch/Fix**
   - Either AUR package is updated with patches for 6.18+
   - OR a working fork exists with documented installation instructions
   - Patches must address the known API changes (platform driver removal, efivar changes)

3. ✅ **Keyboard/Touchpad Functionality**
   - Users confirm keyboard input works reliably
   - Touchpad/trackpad is functional
   - Basic functionality doesn't require manual intervention after each boot

### Recommended (but not blocking)
- ⚠️ Touchbar functionality confirmed (if you have touchbar model)
- ⚠️ Ambient light sensor working
- ⚠️ Driver maintainer actively responding to issues

## Current Working Alternative: Heratiki Fork

If you need to upgrade before official fix, consider Heratiki's fork:

### Installation Steps (from Arch forums)
```bash
# Switch to LTS kernel first
sudo pacman -S linux-lts linux-lts-headers

# Clone Heratiki's fork
git clone https://github.com/Heratiki/macbook12-spi-driver.git
cd macbook12-spi-driver

# Build the driver
make

# Manually install (as DKMS may not work)
sudo cp *.ko /usr/lib/modules/$(uname -r)/updates/dkms/

# Update initramfs modules
# Edit /etc/mkinitcpio.conf and add:
# MODULES=(applespi intel_lpss_pci spi_pxa2xx_platform apple_ib_tb)

sudo mkinitcpio -P
sudo reboot
```

**Note:** <cite index="21-4,21-5,21-12,21-13">May require complete shutdown (not just reboot) and USB unbind/bind commands to activate touchbar</cite>.

## Upgrade Process (When Safe)

### Pre-Upgrade Checklist
- [ ] Verify all criteria above are met
- [ ] Create backup of current working system
- [ ] Document current DKMS module locations
- [ ] Have USB keyboard/mouse ready as fallback
- [ ] Test in VM if possible first

### Step-by-Step Upgrade

1. **Check available kernel versions**
   ```bash
   yay -Ss linux
   ```

2. **Update driver package first** (if AUR updated)
   ```bash
   yay -S macbook12-spi-driver-dkms
   ```

3. **OR switch to working fork** (if using alternative)
   - Follow specific fork's installation instructions
   - May need to remove AUR package first

4. **Upgrade kernel**
   ```bash
   sudo pacman -Syu
   # Or specifically: sudo pacman -S linux
   ```

5. **Rebuild driver**
   ```bash
   sudo dkms status
   sudo dkms install -m macbook12-spi-driver -v <version> -k <kernel-version>
   ```

6. **Update initramfs**
   ```bash
   sudo mkinitcpio -P
   ```

7. **Reboot and test**
   ```bash
   sudo reboot
   ```

8. **Verify driver loaded**
   ```bash
   lsmod | grep -E "applespi|apple_ib"
   dmesg | grep -i spi
   ```

### Rollback Plan (If Upgrade Fails)

1. **Boot into previous kernel** (GRUB menu)
   - Advanced options → Select 6.17.9 kernel

2. **Make previous kernel default temporarily**
   ```bash
   # Edit /etc/default/grub
   GRUB_DEFAULT=saved
   
   # Set specific kernel
   sudo grub-set-default "Advanced options>Linux 6.17.9"
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

3. **Downgrade kernel if needed**
   ```bash
   # Check kernel package cache
   ls /var/cache/pacman/pkg/linux-*
   
   # Downgrade
   sudo pacman -U /var/cache/pacman/pkg/linux-6.17.9-arch1-1-x86_64.pkg.tar.zst
   ```

4. **Hold kernel version**
   ```bash
   # Add to /etc/pacman.conf
   IgnorePkg = linux linux-headers
   ```

## Weekly Monitoring Checklist

Run this check every week:

```bash
# Check for driver updates
yay -Ss macbook12-spi-driver-dkms

# Check current kernel version
uname -r

# Check available kernel updates
checkupdates | grep linux

# Review AUR comments (manual)
# Visit: https://aur.archlinux.org/packages/macbook12-spi-driver-dkms

# Check GitHub for activity (manual)
# - marc-git repo: commits in last 7 days?
# - Heratiki repo: new commits?
# - PR #70: new comments?
```

## Fallback Options

If the fix takes too long (>6 months):

### Option 1: Stay on LTS Kernel
- Switch to `linux-lts` package
- More stable, slower updates
- May have working driver longer

### Option 2: Use Heratiki Fork
- As documented above
- Requires manual building
- May lack some features

### Option 3: Use External Keyboard/Touchpad
- USB or Bluetooth input devices
- Disable internal devices in BIOS if causing issues
- Not ideal but keeps system up-to-date

## Important Notes

- **Keyboard/touchpad are essential** - don't upgrade until confirmed working
- <cite index="11-6,11-7,11-21,11-22">Package maintainer no longer has test hardware and is seeking new maintainer</cite>
- The driver is out-of-tree and depends on kernel internal APIs that change
- Most active development happens in various forks, not upstream
- Test upgrades on Friday so you have weekend to fix issues

## Last Checked
- **Date:** December 19, 2025
- **Kernel 6.18 Status:** Not yet released, no compatibility information available
- **Latest Working Kernel:** 6.17.9 (official AUR), 6.12.10 (Heratiki fork)
