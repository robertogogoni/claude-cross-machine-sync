# Remap Acute Accent to Cedilla

The user wants to replace the acute accent (´) key with the cedilla (ç) character, as they do not use the acute accent.

## Proposed Changes

### Configuration Analysis

First, need to check `envs.conf`, `input.conf` and equaly import `.XCompose`.

### Proposed Changes

1. **Create Custom XKB Layout**:
    * Create directory `~/.config/xkb/symbols`.
    * Create file `~/.config/xkb/symbols/us_custom` with content:

        ```xkb
        default partial alphanumeric_keys
        xkb_symbols "cedilla" {
            include "us(intl)"
            name[Group1]= "English (US, cedilla)";
            key <AC11> { [ ccedilla, Ccedilla, apostrophe, quotedbl ] };
        };
        ```

    * Current `key <AC11>` in `us(intl)` is `[ dead_acute, dead_diaeresis, apostrophe, quotedbl ]`.
    * New mapping: Direct press -> `ç`/`Ç`. `AltGr` -> `'`/`"`.

2. **Update Hyprland Config**:
    * Modify `/home/rob/.config/hypr/input.conf`:
        * Set `kb_layout = us_custom`
        * Set `kb_variant = cedilla` (or just leave variant empty if we define it as default/basic in the string, but better to target the variant/symbol name).
        * Actually, if the file is `us_custom`, and symbol is `cedilla`, syntax is `kb_layout = us_custom` and `kb_variant = cedilla`? No, usually `layout` is the file, `variant` is the block inside.
        * Since we can't easily edit `/usr/share/X11/xkb/symbols/us`, we'll make a new file `us_custom`.
        * So `kb_layout = us_custom`.
        * `kb_variant = cedilla` (matches `xkb_symbols "cedilla"`).

3. **Update Environment**:
    * Ensure `XKB_DEFAULT_LAYOUT` etc are consistent if needed, but Hyprland handles `input` block.

## Verification Plan

1. Restart Hyprland/Reload config (or use `hyprctl reload`).
2. Open a text editor.
3. Press `'` key (AC11). Explain it should type `ç`.
4. Press `Shift + '`. Expect `Ç`.
5. Press `AltGr + '`. Expect `'`.
