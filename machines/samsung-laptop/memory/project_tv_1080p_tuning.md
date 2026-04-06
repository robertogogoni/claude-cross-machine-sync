---
name: TV 1080p rendering tuning
description: Waybar per-output config working, smoothness issue unresolved at 3.1M pixels on HD 4400
type: project
---

## What was done (2026-04-04)

### Waybar per-output config (WORKING)
- Split config.jsonc into JSON array with two bar objects targeting eDP-1 and HDMI-A-1
- Laptop bar: 26px height, 12px font (original sizing)
- TV bar: 38px height, 15px font, extra padding on workspace buttons
- Shared module definitions in modules.jsonc via `include`
- CSS targeting via `window#waybar.tv *` (waybar applies `name` field as CSS class)
- Blue accent border-bottom on both bars for wallpaper separation

### GPU/compositor changes (APPLIED)
- Blur disabled globally (was eating full-screen shader pass per frame at 3.1M pixels)
- Shadow range bumped from 2 to 6 for TV distance visibility
- GPU min freq set to 600 MHz (persistent via /etc/tmpfiles.d/gpu-min-freq.conf)
- Faster animation durations in looknfeel.conf

### Font rendering (REVERTED to original)
- Tried hintfull + rgba subpixel: WRONG for TV. Made text look "stone-cut" and "washy"
- Reverted to hintslight + grayscale: correct for TV panels at 35 PPI
- TV panels don't have standard RGB subpixel layouts, rgba causes color fringing

## Smoothness issue (UNRESOLVED)
Despite blur off, faster animations, GPU floor at 600 MHz, the TV still feels slightly laggy.

Suspects not yet investigated:
1. `AQ_NO_MODIFIERS=1` forces LINEAR DRM buffers (no tiling) -- kills GPU memory access patterns
2. `AQ_NO_ATOMIC=1` legacy DRM path may not handle vsync properly between dual displays
3. HD 4400 may simply be at its ceiling: 3.1M pixels @ 60fps over shared DDR3L bandwidth
4. eDP at 60.04 Hz vs HDMI at 60.00 Hz -- slight refresh rate mismatch could cause frame drops
5. TV's own image processing (motion smoothing, game mode settings) adding latency

## UPDATE 2026-04-05: Root cause found

**The TV was on Sports mode (not Game)** with full post-processing pipeline active.
Fixed via jailbreak Luna API: set pictureMode=game + pcMode.hdmi1=true.
User confirmed "way better." See project_edid_research.md for full details.

**How to apply:** ALL COMPLETE as of 2026-04-05. TV-side picture settings fixed. GPU-side: custom EDID deployed, AQ_NO_ATOMIC removed, AQ_NO_MODIFIERS removed. System verified clean boot with 1080p from kernel.
