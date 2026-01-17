# Keyboard Layout Update Plan

## Goal

Configure the system keyboard layout to allow typing Brazilian Portuguese characters (specially `ç`, `á`, `ã`, etc.) on a US physical keyboard (which lacks the dedicated `ç` key).

## Proposed Changes

We will modify `/home/rob/.config/hypr/input.conf` to change the keyboard layout settings.

### `/home/rob/.config/hypr/input.conf`

We will update the `kb_layout` and `kb_variant` directives.

#### [MODIFY] input.conf

- Change `kb_layout = us,br` to `kb_layout = us`
- Add `kb_variant = intl`
- This sets the layout to **US International**, which provides:
  - `ç` via `'` + `c` (or `AltGr` + `,`)
  - Accents via dead keys (`'` + `e` = `é`, `~` + `a` = `ã`, etc.)

_Alternative considered: `br(nativo-us)`, but `us(intl)` is more standard for US ANSI keyboards._

## Verification Plan

### Manual Verification

1. **Reload Hyprland**: Run `hyprctl reload` to apply changes.
2. **Interactive Test**: Run the user's existing script:

    ```bash
    /home/rob/.gemini/antigravity/scratch/verify_keyboard.py
    ```

    - Verify `ç` works (by typing `'` then `c`).
    - Verify accents work (`á`, `ã`, `â`).
