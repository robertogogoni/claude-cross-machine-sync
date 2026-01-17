# Keyboard Layout Fix & GUI Dashboard

I have addressed the layout mismatch and installed the requested GUI tool.

## Changes Made

1. **Hyprland Layout Swap**:
    - Modified `~/.config/hypr/input.conf` to set `us` (United States) as the primary layout.
    - `br` (ABNT2) is now secondary, accessible via `Alt+Shift`.
2. **GUI Dashboard Installed**:
    - Installed **Input Remapper** (`input-remapper-git`), a comprehensive GUI for visualising and configuring input devices.

## How to Verify

### 1. Reload Hyprland

Your new layout settings should apply automatically if you reload Hyprland. You can usually do this with the default binding `Super + M` (or checking your specific config) or by logging out and back in.

### 2. Run Verification Script

Run the script again to confirm your keys now map correctly to your US keyboard:

```bash
python3 /home/rob/.gemini/antigravity/scratch/verify_keyboard.py
```

### 3. Launch GUI Dashboard

Open the new dashboard to visualize your inputs:

- **Menu**: Search for "Input Remapper".
- **Terminal**: Run `input-remapper-gtk`.

This tool allows you to:

- Select your keyboard device.
- View key codes in real-time.
- Remap keys graphically.
