---
+name: MacBook Air 2015 Keyboard — SPI vs USB Mode
+description: MacBook Air 2015 keyboard/trackpad boot failure after Limine — UIEN(1) forces USB mode; durable fix requires acpi_call inside the Limine UKI plus resume and boot fallbacks
+type: project
+originSessionId: c956b914-80a2-4cc7-b346-99cd5d940423
---
+MacBook Air 2015 (MacBookAir7,2) built-in keyboard and trackpad can disappear immediately after the Limine post screen if firmware boots in SPI mode. On kernel 6.19, the SPI path is broken on this machine (`applespi ... SPI transfer timed out`), but the same hardware works immediately in USB mode after the ACPI call `\_SB.PCI0.SPI1.SPIT.UIEN 0x01`.
+
+**Why:** Apple firmware stores two keyboard interface modes in NVRAM: USB (`hid_apple`) and SPI (`applespi`). Linux in SPI mode gets the device but the transfers never complete because the GSPI path never becomes healthy on this machine. macOS uses the USB path. Linux can force the firmware back to USB mode with `UIEN(1)` through `acpi_call`.
+
+**Most important lesson:** On this Omarchy install, Limine boots a UKI at `/boot/EFI/Linux/omarchy_linux.efi`, not a classic `/boot/initramfs-linux.img`. That means a boot fix is only real if the required module and config are embedded inside the UKI's `.initrd`, not just present under `/etc` in the live root filesystem.
+
+---
+
+## Root Cause (Fully Diagnosed 2026-04-11)
+
+### ACPI Mode Control Methods (in `\_SB.PCI0.SPI1.SPIT`)
+- `UIST()` returns 1 if USB is enabled, 0 if SPI mode is active.
+- `SIST()` returns 1 if SPI is enabled.
+- `UIEN(1)` switches to USB mode.
+- `SIEN(1)` switches to SPI mode.
+
+### Why SPI Fails
+1. The broken state shows `UIST() = 0x0` and repeated `applespi spi-APP000D:00: SPI transfer timed out` errors.
+2. IRQ 21 for the GSPI controller never increments, so SPI transfers never complete.
+3. `UIEN(1)` immediately restores keyboard and trackpad function, proving the hardware still works in USB mode.
+4. Reloading `applespi` after `UIEN(1)` reports `USB interface already enabled`, which confirms the firmware mode change.
+5. This is not just a transient driver bug. The SPI path is unusable on this machine, while USB mode is healthy.
+
+### What Was Wrong With the First "Permanent" Fix
+The machine already had `/etc/modprobe.d/apple-keyboard-usb.conf` and the resume hook on disk, but boot still failed. The missing piece was early boot: the embedded UKI initramfs did not contain `acpi_call`, so the `install applespi ...` hook could not actually switch the keyboard before `applespi` probed.
+
+This was diagnosed by extracting the UKI initrd and inspecting it directly:
+
+```bash
+sudo objcopy --dump-section .initrd=/tmp/omarchy-linux.initrd /boot/EFI/Linux/omarchy_linux.efi
+lsinitcpio /tmp/omarchy-linux.initrd | rg 'apple-keyboard-usb\.conf|acpi_call\.ko'
+```
+
+Do not trust the ESP file timestamp alone. On this system, the UKI mtime on `/boot` was misleading; the embedded `.initrd` contents were the source of truth.
+
+---
+
+## Hardened Persistent Fix (Installed 2026-04-11)
+
+### 1. `/etc/modprobe.d/apple-keyboard-usb.conf`
+Hooks `applespi` loading. Before `applespi` probes, it loads `acpi_call` and runs `UIEN(1)`.
+
+```sh
+install applespi /sbin/modprobe --ignore-install acpi_call 2>/dev/null; \
+  echo "\_SB.PCI0.SPI1.SPIT.UIEN 0x01" > /proc/acpi/call 2>/dev/null; \
+  /sbin/modprobe --ignore-install applespi "$@"
+```
+
+### 2. `/etc/mkinitcpio.conf.d/apple-keyboard-acpi-call.conf`
+Pins `acpi_call` into the initramfs so the modprobe hook works during early boot inside the Limine UKI.
+
+```sh
+MODULES+=(acpi_call)
+```
+
+This was the missing durability piece. `usbhid` is builtin and `hid_apple` was already available; `acpi_call` was the module missing from the embedded initrd.
+
+### 3. `limine-update` rebuilds `/boot/EFI/Linux/omarchy_linux.efi`
+After changing the keyboard boot config, rebuild the UKI with:
+
+```bash
+sudo limine-update
+```
+
+Verify the rebuilt UKI contains both the hook and the module:
+
+```bash
+sudo objcopy --dump-section .initrd=/tmp/omarchy-linux.initrd /boot/EFI/Linux/omarchy_linux.efi
+lsinitcpio /tmp/omarchy-linux.initrd | rg 'etc/modprobe.d/apple-keyboard-usb\.conf|usr/lib/modules/.*/acpi_call\.ko\.zst'
+```
+
+### 4. `/etc/systemd/system-sleep/apple-keyboard-usb.sh`
+Re-fires `UIEN(1)` after every suspend/hibernate resume. This is the correct resume mechanism because `/etc/systemd/system-sleep/*` runs on the `post` phase after waking.
+
+```bash
+#!/bin/bash
+case "$1" in
+    post)
+        /sbin/modprobe acpi_call 2>/dev/null
+        echo "\_SB.PCI0.SPI1.SPIT.UIEN 0x01" > /proc/acpi/call 2>/dev/null
+        ;;
+esac
+```
+
+### 5. `/etc/systemd/system/apple-keyboard-usb-fallback.service`
+Boot-time safety net. After normal module loading, it reasserts `UIEN(1)` before the graphical or multi-user targets fully come up.
+
+Important behavior: this is a `oneshot` unit, so `inactive (dead)` after boot is success, not failure.
+
+### 6. `/etc/systemd/system/apple-keyboard-uki-rebuild.path`
+Watches the keyboard boot config files and triggers `/etc/systemd/system/apple-keyboard-uki-rebuild.service`, which simply runs `limine-update`.
+
+Watched files:
+- `/etc/modprobe.d/apple-keyboard-usb.conf`
+- `/etc/mkinitcpio.conf.d/apple-keyboard-acpi-call.conf`
+- `/etc/modules-load.d/acpi_call.conf`
+
+This was tested by touching one of the watched files and confirming a real UKI rebuild completed successfully.
+
+### 7. `/etc/modules-load.d/acpi_call.conf`
+Still useful for the normal live system after root is mounted.
+
+```sh
+acpi_call
+```
+
+### 8. Kernel and package update persistence
+Kernel and mkinitcpio updates are already covered by the existing pacman hook at `/etc/pacman.d/hooks/90-mkinitcpio-install.hook`, which runs `limine-mkinitcpio-install`. That means future kernel updates should rebuild the Limine UKI automatically.
+
+---
+
+## Disabled / Rejected Approaches
+
+- `applespi-reload.service` is disabled. Reloading the module does not fix a firmware-level SPI mode problem.
+- `apple-keyboard-usb-resume.service` is disabled. With `WantedBy=suspend.target`, it fires on the way into suspend, not after resume.
+- Firmware flashing is not the right first fix here. The problem has been reproducibly fixed in software by forcing USB mode and fixing the UKI build path.
+
+---
+
+## Manual Recovery (if keyboard dies again)
+
+No SMC reset is needed. Run:
+
+```bash
+sudo modprobe acpi_call
+echo "\_SB.PCI0.SPI1.SPIT.UIEN 0x01" | sudo tee /proc/acpi/call
+```
+
+Verify:
+
+```bash
+echo "\_SB.PCI0.SPI1.SPIT.UIST" | sudo tee /proc/acpi/call && sudo cat /proc/acpi/call
+lsusb | grep '05ac:0291'
+lsmod | grep hid_apple
+journalctl -k --no-pager | rg 'applespi|hid_apple|acpi_call'
+```
+
+Expected:
+- `UIST` should report `0x1`
+- Apple keyboard/trackpad USB device should appear in `lsusb`
+- `hid_apple` should be active
+
+---
+
+## Key Learnings To Reuse
+
+- If boot behavior disagrees with `/etc`, inspect the actual UKI contents, not the live root filesystem.
+- On Limine UKI systems, `/boot/EFI/Linux/*.efi` may be the real initramfs carrier.
+- A correct `modprobe.d` hook is not enough if the referenced helper module is absent from the embedded initrd.
+- A `systemd-sleep` hook is the right tool for post-resume recovery.
+- A `.path` unit is a simple way to keep UKI rebuilds aligned with config drift.
+
+## Versions
+- Kernel: `6.19.11-arch1-1`
+- `acpi_call`: `/usr/lib/modules/6.19.11-arch1-1/updates/dkms/acpi_call.ko.zst`
