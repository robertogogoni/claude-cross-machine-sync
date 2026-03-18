---
name: Samsung laptop hardware profile
description: Full hardware specs for user's Samsung 270E5J laptop — CPU, GPU, RAM, storage, drivers, and tuning applied
type: user
---

## Samsung 270E5J Laptop

- **CPU:** Intel i7-4510U (Haswell, 2C/4T, 2.0GHz)
- **RAM:** 8GB (with 3.8GB zram swap)
- **iGPU:** Intel HD 4400 (Haswell-ULT) — active, i915 driver
- **dGPU:** NVIDIA GeForce 710M/720M — dormant (no kernel module loaded, saves battery)
- **Storage:** 1TB HDD (spinning, ST1000LM024)
- **WiFi:** Qualcomm Atheros QCA9565
- **Network:** systemd-networkd + iwd (NOT NetworkManager)
- **Display:** 1366x768 (AU Optronics 0x22EC), 15.6", ~100 DPI, 60Hz, eDP-1
- **OS:** Arch Linux, Hyprland (Omarchy), kernel 6.19.8
- **Shell:** bash

## Drivers & Tuning Applied (2026-03-17)

- **Vulkan:** vulkan-intel (ANV, Vulkan 1.2 — "incomplete" warning is normal for Haswell)
- **VA-API:** libva-intel-driver (i965) — set via `LIBVA_DRIVER_NAME=i965` in envs.conf and .bashrc
- **I/O scheduler:** BFQ (persistent via udev rule at `/etc/udev/rules.d/60-ioschedulers.rules`)
- **Services:** earlyoom (OOM killer), thermald (Intel thermal management)
- **Power:** No TLP/auto-cpufreq — thermald + kernel schedutil handles Haswell

## Why NVIDIA is Disabled

The 710M is Kepler-era, weaker than the Intel iGPU for desktop. nvidia-utils is installed but kernel module is not loaded. Enabling it would waste battery with no benefit. Do NOT suggest installing nvidia/nvidia-prime/bumblebee.
