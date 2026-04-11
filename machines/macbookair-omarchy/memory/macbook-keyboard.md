---
name: MacBook Air 2015 Keyboard — SPI vs USB Mode
description: MacBook Air 2015 keyboard ACPI mode control — UIEN(1) forces USB mode permanently, no SMC reset needed; full ACPI/GPIO mechanism documented
type: project
originSessionId: c956b914-80a2-4cc7-b346-99cd5d940423
---
MacBook Air 2015 (MacBookAir7,2) built-in keyboard operates in two distinct modes stored in firmware NVRAM. On kernel 6.19, SPI mode is completely broken — the SPI bus is stuck and IRQ 21 never fires. USB mode (after UIEN(1) call or SMC reset) works perfectly via hid_apple.

**Why:** Apple firmware has two keyboard interface modes: USB (handled by `hid_apple`) and SPI (handled by `applespi`). The DSDT `OSDW()` function intentionally gives Linux SPI resources and gives macOS empty resources — macOS always uses USB. SPI mode on Linux fails because IRQ 21 (GSPI controller at 00:15.4) never fires, meaning no SPI transfers complete. This is not a kernel regression — spi-pxa2xx files are identical between 6.18 and 6.19.

**How to apply:** The ACPI method `UIEN(1)` switches the keyboard to USB mode by toggling GPIO pins (GD26/GP26 for USB, GD13/GP13 for SPI). Calling it via `acpi_call` is all that's needed — no SMC reset required.

---

## Root Cause (Fully Diagnosed 2026-04-11)

### ACPI Mode Control Methods (in `\_SB.PCI0.SPI1.SPIT`)
- `UIST()` — returns 1 if USB enabled, 0 if SPI mode
- `SIST()` — returns 1 if SPI enabled
- `UIEN(1)` — switches to USB mode: calls SIEN(0) + sets GD26=1 (USB GPIO)
- `UIEN(0)` — disables USB: GP26=0, GD26=0
- `SIEN(1)` — enables SPI: UIEN(0) + GP13=1, GD13=0
- `ISOL(n)` — resets GPIO pins 87-90 for SPI interface

### Why SPI Fails
1. IRQ 21 (GSPI at `0000:00:15.4`) always shows 0 count — interrupt never fires
2. DMA controller at `0000:00:15.0` also shows 0 count
3. The keyboard hardware in SPI mode does not respond to SPI commands
4. IOMMU fix (commit `320302b`) IS present in 6.19.11 — not the cause
5. Driver files spi-pxa2xx.c / spi-pxa2xx-pci.c / intel-lpss.c identical between 6.18 and 6.19

### Trigger for Mode Switch
Likely a specific sleep/wake cycle. SMC (via NVRAM) switches the firmware, which changes which GPIO pins are active. Linux is not notified.

---

## Permanent Fix (Installed 2026-04-11)

### 1. `/etc/modprobe.d/apple-keyboard-usb.conf`
Hooks applespi loading. Before applespi probes, calls UIEN(1) to switch to USB mode. applespi detects UIST()=1 ("USB interface already enabled") and exits cleanly. hid_apple handles the keyboard.

```
install applespi /sbin/modprobe --ignore-install acpi_call 2>/dev/null; \
  echo "\_SB.PCI0.SPI1.SPIT.UIEN 0x01" > /proc/acpi/call 2>/dev/null; \
  /sbin/modprobe --ignore-install applespi "$@"
```

### 2. `/etc/systemd/system/apple-keyboard-usb-resume.service`
Re-fires UIEN(1) after every suspend/hibernate (the likely trigger for mode switches).

```ini
[Unit]
Description=Force Apple keyboard to USB mode after suspend
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/sbin/modprobe acpi_call
ExecStart=/bin/sh -c 'echo "\\_SB.PCI0.SPI1.SPIT.UIEN 0x01" > /proc/acpi/call'

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```
Enabled via: `systemctl enable apple-keyboard-usb-resume.service`

### 3. `/etc/modules-load.d/acpi_call.conf`
Ensures `acpi_call` module loads at boot (needed by the modprobe hook).

```
acpi_call
```

### Old workaround — removed
- `applespi-reload.service` — disabled 2026-04-11 (useless: module reload can't unstick SPI bus)

---

## Manual Fix (if keyboard dies again)

No longer need SMC reset! Just run:
```bash
sudo modprobe acpi_call
echo "\_SB.PCI0.SPI1.SPIT.UIEN 0x01" | sudo tee /proc/acpi/call
```

Verify:
```bash
# Check USB mode active:
echo "\_SB.PCI0.SPI1.SPIT.UIST" | sudo tee /proc/acpi/call && sudo cat /proc/acpi/call  # should be 0x1
lsusb | grep "05ac:0291"  # Apple Internal Keyboard / Trackpad

# Check kernel mode:
lsmod | grep hid_apple   # should be present
lsmod | grep applespi    # should be absent or loaded-but-idle
```

---

## Diagnosis Tools

```bash
# Check which mode keyboard is in:
sudo bash -c 'modprobe acpi_call; echo "\_SB.PCI0.SPI1.SPIT.UIST" > /proc/acpi/call && cat /proc/acpi/call'

# Check IRQ 21 (SPI controller — stays 0 in USB mode):
sudo cat /proc/interrupts | awk '$1=="21:"'

# Check SPI driver timeouts:
sudo dmesg | grep applespi | tail -5

# Full probe: SPI mode broken?
sudo dmesg | grep applespi | grep -v timeout | grep -v Error
```

## Versions
- acpi_call: `/lib/modules/6.19.11-arch1-1/updates/dkms/acpi_call.ko.zst`
- Kernel: 6.19.11-arch1-1 (all fixes present, SPI mode still broken at hardware level)
