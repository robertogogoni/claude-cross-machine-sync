# Verification Walkthrough

## 1. Reload Hyprland

- Please reload your Hyprland configuration or restart your session.
- **Check**: Verify that the "Wayland Diagnose" warning **does not** appear.

## 2. Test 'ç' Character

You are using the `us-intl` layout.

- Open a text editor.
- **Method 1 (Standard)**: Press `AltGr` + `,`.
- **Method 2 (Your Preference)**: Press `'` (single quote) then `c`.
  - **Result**: Should be `ç` (cedilla).

> [!NOTE]
> If you still get `ć` (acute), please let me know. We might need to forcefully set `GTK_IM_MODULE=cedilla`, but that may bring back the warning.
