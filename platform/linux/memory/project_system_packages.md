---
name: System packages installed 2026-03-17
description: Packages installed for Samsung laptop hardware — GPU drivers, power management, media codecs, utilities, dev tools
type: project
---

Installed on 2026-03-17 based on hardware audit:

**Intel GPU:** vulkan-intel, libva-intel-driver, vulkan-tools, mesa-utils, libva-utils
**Power/Thermal:** thermald (enabled), powertop
**System stability:** earlyoom (enabled) — kills at 10% free RAM
**Media codecs:** gst-plugins-good, gst-plugins-bad, gst-plugins-ugly, gst-libav
**Utilities:** htop, lsof, unrar, p7zip, ntfs-3g, dosfstools, bluez-utils, acpi
**Dev tooling:** uv (Python UV — enables uvx MCP servers: git, sqlite, fetch)

**Why:** Hardware audit found missing Vulkan driver (needed for Chrome Vulkan flag), no VA-API (CPU doing video decode), no power management on a laptop, no OOM protection with 8GB RAM, incomplete media codecs.

**How to apply:** These are now installed and running. `powertop --auto-tune` can be run for max battery savings. Don't suggest installing nvidia/nvidia-prime — the dGPU is intentionally dormant.
