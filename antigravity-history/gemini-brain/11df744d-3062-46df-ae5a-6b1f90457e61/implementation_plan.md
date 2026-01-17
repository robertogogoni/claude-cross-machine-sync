# Input Method & Layout Fix Plan

## Goal Description

Resolve the "Wayland Diagnose" warning regarding `GTK_IM_MODULE` and ensure the 'ç' character functions correctly on the user's keyboard layout.

## User Review Required
>
> [!IMPORTANT]
> The fix involves modifying environment variables and keyboard layout settings which might affect other input behaviors.

## Proposed Changes

### Configuration

#### [MODIFY] [envs.conf](file:///home/rob/.config/hypr/envs.conf)

- Remove `GTK_IM_MODULE,xim` - Causes the warning and legacy behavior.
- Remove `QT_IM_MODULE,xim` - Best to use native Wayland support.

#### [MODIFY] [input.conf](file:///home/rob/.config/hypr/input.conf)

- No changes immediately. Will verify if `us(intl)` meets user needs or if `kb_variant` needs changing to `br` (if they have an ABNT keyboard) or if they need `AltGr` instructions.

## Verification Plan

### Manual Verification

- **Warning Check**: Reboot/Reload -> Warning should be gone.
- **'ç' Check**:
  - Try `AltGr + ,` (Native `us-intl` cedilla).
  - Try `' + c` (Native `us-intl` acute-c).
  - If user needs `' + c` -> `ç`, we may need to explore `GTK_IM_MODULE=cedilla` (re-adding logic if warning permits) or other locale hacks *after* fixing the warning.
