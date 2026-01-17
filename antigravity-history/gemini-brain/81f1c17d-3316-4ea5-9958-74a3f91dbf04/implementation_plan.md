# Trackpad and Magic Mouse Optimization Plan (Revision 1)

The previous attempt made the devices too sensitive and jittery. The user described capturing "micro-movements" and needing to move "unnaturally slow".

**Diagnosis**: The combination of `adaptive` acceleration and `0.0`/`0.2` sensitivity is amplifying high-DPI inputs from the Apple hardware. We need to dampen the signal and remove the acceleration curve to provide a stable, predictable 1:1 feel.

## User Review Required

> [!CAUTION]
> **Drastic Sensitivity Change**: I am switching the acceleration profile to `flat` and setting sensitivity to `-0.8` (Magic Mouse) and `-0.6` (Trackpad). This will significantly slow down the cursor closer to the original "dampened" feel but without the inconsistent acceleration curve, which should fix the "micro-movement" jitter.

## Proposed Changes

### Configuration Updates

#### [MODIFY] [input.conf](file:///home/rob/.config/hypr/input.conf)

- **Global/Trackpad**:
    - Change `accel_profile` from `adaptive` to `flat`.
    - Change `sensitivity` to `-0.6`.
- **Magic Mouse**:
    - Change `accel_profile` from `adaptive` to `flat`.
    - Change `sensitivity` to `-0.8` (even lower because mice often have higher DPI than trackpads).

### System Changes

No changes to the kernel module (`hid_magicmouse.conf`) for now, as the scrolling speed seemed okay, but the user's complaint focused on "action" (pointing). If scrolling is also too fast, I can lower `scroll_speed` in a future step.

## Verification Plan

### Manual Verification
1.  **Reload**: `hyprctl reload`.
2.  **Test**:
    -   Rest hand on mouse/trackpad: Cursor should stay still (no micro-jitter).
    -   Move standard distance: Cursor should cover a usable distance without flying off-screen.
    -   Precision: Try to click a small window button. It should be easy to "stop" exactly on target.
