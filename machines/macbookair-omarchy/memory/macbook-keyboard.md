---
name: MacBook Air 2015 Keyboard — SPI vs USB Mode
description: MacBook Air 2015 keyboard has two firmware modes (USB/hid_apple vs SPI/applespi); SPI mode broken on kernel 6.19; SMC reset restores USB mode
type: project
originSessionId: c956b914-80a2-4cc7-b346-99cd5d940423
---
MacBook Air 2015 (MacBookAir7,2) built-in keyboard operates in two distinct modes stored in firmware NVRAM. On kernel 6.19, SPI mode is completely broken — the bus locks up and the keyboard is dead even at the LUKS/login password screen.

**Why:** Apple firmware switches between USB mode (handled by `hid_apple`) and SPI mode (handled by `applespi`) based on NVRAM state. Something between 2026-04-02 and 2026-04-11 switched the firmware to SPI mode, which times out on kernel 6.19 from the very start of boot.

**How to apply:** If keyboard stops working at boot (password screen, not just after login), this is the likely cause. SMC reset is the only real fix.

## Diagnosis

Boot log comparison:

**Working (USB mode)** — shows in `journalctl -b -N`:
```
applespi spi-APP000D:00: USB interface already enabled
# Then hid_apple loads normally
```

**Broken (SPI mode)** — shows in `journalctl -b`:
```
applespi spi-APP000D:00: Timed out waiting for command response
applespi spi-APP000D:00: Timed out... (repeats)
# No hid_apple, keyboard dead
```

Verify current mode:
```bash
lsmod | grep hid_apple   # present = USB mode (working)
lsmod | grep applespi    # present = SPI mode active
dmesg | grep applespi    # check for "USB interface already enabled" vs timeouts
```

## Fix: SMC Reset (Definitive)

Forces firmware NVRAM back to USB keyboard mode.

1. **Shut down completely** (not sleep, not restart)
2. Hold simultaneously on built-in keyboard:
   - **Left Shift** + **Left Control** + **Left Option** + **Power button**
3. Hold for **10 seconds**
4. Release all keys
5. Press Power to boot normally

After boot, verify:
- `lsmod | grep hid_apple` — should show `hid_apple`
- Keyboard works at LUKS/login screen on next cold boot

## Palliative: applespi-reload.service

Created 2026-04-11 at `/etc/systemd/system/applespi-reload.service`:
```ini
[Unit]
Description=Reload applespi kernel module — fixes SPI timeout on boot (Kernel 6.19+)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe -r applespi
ExecStart=/bin/sleep 1
ExecStart=/usr/bin/modprobe applespi

[Install]
WantedBy=multi-user.target
```

**Limitation**: Does NOT fix the boot/password-screen issue. The SPI bus is already stuck at hardware level before this service runs. After SMC reset (USB mode), this service is harmless but unnecessary — can be disabled:
```bash
sudo systemctl disable --now applespi-reload.service
```

## Why Module Reload Doesn't Fix It

The SPI bus lock happens at a hardware/firmware level before the kernel driver even tries to communicate. Unloading and reloading `applespi` module still gets the same stuck bus — the driver has no way to unstick the hardware state. Only the SMC reset clears the firmware's mode register.

## Trigger for Mode Switch

Unknown. Possible causes:
- Specific sleep/wake cycle with power connected
- A failed suspend that corrupted NVRAM
- Kernel 6.19 boot with applespi loaded writing bad state back to firmware

No reliable repro — just perform SMC reset when keyboard dies again.
