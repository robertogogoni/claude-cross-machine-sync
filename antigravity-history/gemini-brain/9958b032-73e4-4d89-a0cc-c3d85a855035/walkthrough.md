# Verification: Caps Lock and 'ç' Fix

I have applied the following fixes:

1. **Caps Lock**: Removed the default override that converted Caps Lock into a Compose key.
2. **'ç' Character**: Created a `.XCompose` file and updated environment variables to mapped `' + c` to `ç`.

## 1. Restart Hyprland

To ensure all environment variables (`XT_IM_MODULE`) and input configs are reloaded, you must restart your session.

- **Log out** and log back in.
- *Or*, if you can't log out, try reloading Hyprland (`hyprctl reload`), though environment variables usually require a full session restart.

## 2. Verify Caps Lock

1. Open a terminal or text editor.
2. Press **Caps Lock**.
3. Verify the LED on your keyboard passes.
4. Type some letters. **THEY SHOULD BE UPPERCASE.**
5. Press Caps Lock again to disable.

## 3. Verify 'ç' (Cedilla)

1. Open a GTK app (like a terminal, Gedit, or browser).
2. Type `'` (single quote key, usually next to Enter). nothing should appear yet (dead key).
3. Type `c`.
4. **Result**: `ç` should appear.
    - *If `ć` (c-acute) appears*: The `.XCompose` file is not being read. Check if `GTK_IM_MODULE` is correctly applied.
    - *fallback*: Use `AltGr` + `,` if the dead key combination fails, though our goal is to fix the dead key combo.

## Troubleshooting

If it still doesn't work after a restart:

- Check active env vars: `env | grep IM_MODULE`
- Check if `.XCompose` permissions are correct: `ls -l ~/.XCompose` (should be user-readable).
