# Keyboard Layout Standardization Plan

The goal is to revert the keyboard configuration to standard, well-supported layouts: "US International" and "Portuguese (Brazil) ABNT2". This will allow the user to switch between them as needed and rely on standard behavior without custom hacks or complex remappings.

## User Review Required

> [!IMPORTANT]
> This plan will remove the custom `us_custom` layout and `.XCompose` modifications made in previous sessions.
> It will enable **two** layouts: `us(intl)` and `br` (ABNT2).
> You will be able to switch between them using **Alt + Shift**.
>
> **US International Behavior:**
>
> - `ç` is typed by pressing `'` (dead key) then `c`, OR `AltGr` + `,`
> - Accents (é, ã, etc.) work via dead keys (`'`, `~`, `^`, etc.)
>
> **ABNT2 Behavior (`br` layout):**
>
> - Standard mapping for physical Brazilian keyboards (dedicated `ç` key).

## Proposed Changes

### Hyprland Configuration (`/home/rob/.config/hypr/input.conf`)

#### [MODIFY] [input.conf](file:///home/rob/.config/hypr/input.conf)

- Change `kb_layout` to `us,br`
- Change `kb_variant` to `intl,` (US gets 'intl' variant, BR gets default)
- Add `kb_options = grp:alt_shift_toggle` to allow switching layouts
- Remove references to `us_custom`

### Custom Configuration Cleanup

#### [DELETE] [.XCompose](file:///home/rob/.XCompose)

- Remove the `.XCompose` file to disable the custom "acute + c" hack, restoring standard behavior.

## Verification Plan

### Manual Verification

1. **Reload Hyprland**: Save the config (Hyprland usually auto-reloads, but a restart might be safer for input rules).
2. **Test US International**:
    - Open a text editor.
    - Press `'` then `c` -> Should produce `ç`.
    - Press `AltGr` + `,` -> Should produce `ç`.
    - Press `'` then `e` -> Should produce `é`.
3. **Test Layout Switching**:
    - Press `Alt` + `Shift`.
    - Verify layout has changed (if using a status bar, or by typing).
4. **Test ABNT2**:
    - Press the keys corresponding to standard ABNT2 positions (if user has compatible hardware).
