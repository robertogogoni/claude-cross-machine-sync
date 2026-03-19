---
name: System packages installed
description: Packages installed for Samsung laptop hardware — GPU drivers, power management, media codecs, utilities, dev tools, apps
type: project
---

## 2026-03-17 — Hardware audit baseline

**Intel GPU:** vulkan-intel, libva-intel-driver, vulkan-tools, mesa-utils, libva-utils
**Power/Thermal:** thermald (enabled), powertop
**System stability:** earlyoom (enabled) — kills at 10% free RAM
**Media codecs:** gst-plugins-good, gst-plugins-bad, gst-plugins-ugly, gst-libav
**Utilities:** htop, lsof, unrar, p7zip, ntfs-3g, dosfstools, bluez-utils, acpi
**Dev tooling:** uv (Python UV — enables uvx MCP servers: git, sqlite, fetch)

**Why:** Hardware audit found missing Vulkan driver (needed for Chrome Vulkan flag), no VA-API (CPU doing video decode), no power management on a laptop, no OOM protection with 8GB RAM, incomplete media codecs.

## 2026-03-19 — Telegram Desktop setup

**App:** telegram-desktop-bin 6.6.2-1 (AUR, static binary)
**Image support:** qt6-imageformats (WebP, AVIF, TIFF, MNG for stickers/media)
**Spellcheck:** hunspell-en_us, hunspell-pt-br (AUR)
**UI scaling fix:** Custom .desktop at ~/.local/share/applications/org.telegram.desktop.desktop with QT_SCALE_FACTOR=0.8 (static Qt ignores system env vars)

**Already present (no install needed):** ffmpeg, full GStreamer stack, qt6-multimedia, qt6-wayland, qt6-svg, noto-fonts-emoji, pipewire, libnotify, mako, libappindicator-gtk3, xdg-desktop-portal-hyprland, v4l-utils, grim, slurp, libcanberra, sound-theme-freedesktop, noto-fonts (full set), xdg-user-dirs

**Why:** User installed telegram-desktop-bin from AUR. Static binary needed its own scaling override and additional Qt image format plugins.

## General notes

`powertop --auto-tune` can be run for max battery savings. Don't suggest installing nvidia/nvidia-prime — the dGPU is intentionally dormant.
