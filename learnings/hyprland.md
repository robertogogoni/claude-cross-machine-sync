# hyprland — Auto-Captured Learnings

Automatically extracted by Cortex during Claude Code sessions.

---


## 2026-03-17 20:09 — decision

Display scaling fix for 1366x768 Samsung laptop: Replaced fractional scaling (QT_SCALE_FACTOR=0.75, GDK_SCALE=2 override) with DPI-based integer rendering (QT_SCALE_FACTOR=1 + QT_WAYLAND_FORCE_DPI=80, GDK_SCALE=1 + GDK_DPI_SCALE=0.85). Key finding: Hyprland sources envs.conf before monitors.conf, so monitors.conf's GDK_SCALE=2 was silently overriding envs.conf's GDK_SCALE=1. DPI-based sizing renders at native resolution with smaller logical sizes — zero blur vs fractional scaling which resamples buffers.

*Tags: hyprland, scaling, display, wayland, qt, gtk, dpi | Quality: 5*

---

## 2026-03-17 20:09 — decision

Display scaling fix for 1366x768 Samsung laptop: Replaced fractional scaling (QT_SCALE_FACTOR=0.75, GDK_SCALE=2 override) with DPI-based integer rendering (QT_SCALE_FACTOR=1 + QT_WAYLAND_FORCE_DPI=80, GDK_SCALE=1 + GDK_DPI_SCALE=0.85). Key finding: Hyprland sources envs.conf before monitors.conf, so monitors.conf's GDK_SCALE=2 was silently overriding envs.conf's GDK_SCALE=1. DPI-based sizing renders at native resolution with smaller logical sizes — zero blur vs fractional scaling which resamples buffers.

*Tags: hyprland, scaling, display, wayland, qt, gtk, dpi | Quality: 5*

---

## 2026-03-17 20:09 — decision

Display scaling fix for 1366x768 Samsung laptop: Replaced fractional scaling (QT_SCALE_FACTOR=0.75, GDK_SCALE=2 override) with DPI-based integer rendering (QT_SCALE_FACTOR=1 + QT_WAYLAND_FORCE_DPI=80, GDK_SCALE=1 + GDK_DPI_SCALE=0.85). Key finding: Hyprland sources envs.conf before monitors.conf, so monitors.conf's GDK_SCALE=2 was silently overriding envs.conf's GDK_SCALE=1. DPI-based sizing renders at native resolution with smaller logical sizes — zero blur vs fractional scaling which resamples buffers.

*Tags: hyprland, scaling, display, wayland, qt, gtk, dpi | Quality: 5*

---
