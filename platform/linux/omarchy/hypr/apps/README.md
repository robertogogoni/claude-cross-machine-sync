# User-Maintained App Configurations

This directory contains app-specific window rules that override Omarchy defaults.

## Why This Exists

Omarchy's default app configs (`~/.local/share/omarchy/default/hypr/apps/`) were using
old Hyprland v1 syntax (`windowrule`) which is incompatible with Hyprland v0.53.0+ when
used with v2 matchers like `class:`, `tag:`, `title:`, etc.

By maintaining our own copies here, we:
- ✅ Use correct `windowrulev2` syntax for Hyprland v0.53.0+
- ✅ Prevent Omarchy updates from reverting our fixes
- ✅ Can customize app behavior without touching Omarchy defaults
- ✅ Override any Omarchy settings (user configs are sourced last)

## Files Updated (2026-01-01)

All files converted from `windowrule` → `windowrulev2`:
- 1password.conf
- bitwarden.conf
- browser.conf
- davinci-resolve.conf
- jetbrains.conf
- localsend.conf
- pip.conf
- qemu.conf
- retroarch.conf
- steam.conf
- system.conf
- terminals.conf
- webcam-overlay.conf

Commented out incompatible `layerrule` syntax:
- hyprshot.conf
- walker.conf

## How It Works

1. Omarchy defaults are sourced first (from `~/.local/share/omarchy/default/`)
2. Your user configs override them (from `~/.config/hypr/apps/`)
3. Sourced via `~/.config/hypr/apps.conf` at the end of `hyprland.conf`

## Maintenance

- **Adding new apps**: Create a `.conf` file here and add a `source` line in `apps.conf`
- **Removing apps**: Delete the `.conf` file and remove the `source` line from `apps.conf`
- **Updating Omarchy**: Your configs here won't be affected by Omarchy updates
- **Syncing Omarchy changes**: If Omarchy adds new app configs, manually copy them here

## Syntax Reference

### Correct (Hyprland v0.53.0+)
```conf
windowrulev2 = float, class:myapp
windowrulev2 = tag +mytag, title:MyWindow
```

### Incorrect (will cause errors)
```conf
windowrule = float, class:myapp        # ❌ class: requires windowrulev2
windowrule = tag +mytag, title:MyWindow # ❌ title: requires windowrulev2
```

### Simple rules (no matchers) can still use v1
```conf
windowrule = float, myapp              # ✅ OK - no matcher used
```

## Troubleshooting

If errors appear again:
1. Check `hyprctl configerrors` to see which file has issues
2. Verify all rules with matchers (`class:`, `tag:`, `title:`) use `windowrulev2`
3. Ensure `~/.config/hypr/apps.conf` is sourced in `hyprland.conf`
4. Run `hyprctl reload` after making changes
