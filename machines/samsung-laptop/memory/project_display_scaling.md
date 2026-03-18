---
name: Display scaling — DPI-based crisp rendering
description: 1366x768 display scaling fix applied 2026-03-17 — integer scales + DPI override replaces fractional scaling for pixel-perfect UI
type: project
---

## Display Scaling Configuration (2026-03-17)

Fixed a scaling conflict that caused blurry and oversized UI on the 1366x768 panel.

### The Problem

Hyprland loads `envs.conf` (line 16) then `monitors.conf` (line 17). monitors.conf had `GDK_SCALE=2` (retina preset) which **overrode** envs.conf's `GDK_SCALE=1`. Combined with fractional `QT_SCALE_FACTOR=0.75`, this caused:
- GTK apps: 2 x 0.75 = 1.5x effective scale (fractional = blurry)
- Qt apps: 0.75x fractional scale (sub-pixel blur)

### The Fix

**monitors.conf** — switched from 2x retina to 1x preset:
```
env = GDK_SCALE,1
monitor=,preferred,auto,1
```

**envs.conf** — replaced fractional scaling with DPI-based sizing:
```
env = GDK_SCALE,1          # integer (no compositor resampling)
env = GDK_DPI_SCALE,0.85   # GTK: 85% size via DPI, not buffer scaling
env = QT_SCALE_FACTOR,1    # integer (pixel-perfect)
env = QT_AUTO_SCREEN_SCALE_FACTOR,0
env = QT_WAYLAND_FORCE_DPI,80  # Qt: ~83% size (80/96) via DPI override
```

### Why DPI-Based is Better Than Fractional Scaling

- **Fractional `QT_SCALE_FACTOR`** (e.g. 0.75): Qt renders at 75% resolution, compositor upscales the buffer — causes sub-pixel artifacts and fuzzy text
- **DPI override** (e.g. `QT_WAYLAND_FORCE_DPI=80`): Qt renders at full native 1366x768 but computes smaller widget/font sizes — zero blur, compact UI

**Why:** User's panel is 1366x768 (~100 native DPI). The retina preset was a default from Omarchy, not matched to this hardware.

**How to apply:** If user connects an external HiDPI monitor, monitors.conf will need per-output rules. The 1x preset only suits low-res panels. Backup exists at `monitors.conf.bak.*`.
