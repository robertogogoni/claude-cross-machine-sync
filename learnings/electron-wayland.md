# Electron Apps on Wayland

Patterns for fixing Electron applications on Wayland compositors (Hyprland, Sway, etc.)

---

## The Problem

Electron apps default to XWayland rendering. This causes:
- **Blank/white windows** on startup
- **Blank screen after sleep/wake**
- **Poor HiDPI scaling**
- **Input lag** compared to native Wayland

---

## Solution: Ozone Platform Flags

### Full Flag Set
```bash
--enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing
```

### Flag Breakdown

| Flag | Purpose |
|------|---------|
| `--enable-features=UseOzonePlatform` | Enables Ozone abstraction layer |
| `--ozone-platform=wayland` | Uses Wayland backend instead of X11 |
| `--disable-gpu-compositing` | Prevents blank screen after sleep/wake |

### When to Use Each
- **Startup issues:** `--enable-features=UseOzonePlatform --ozone-platform=wayland`
- **Sleep/wake issues:** Add `--disable-gpu-compositing`
- **Both issues:** Use all three flags

---

## Application Methods

### Method 1: Desktop File Override (Recommended)

XDG spec: `~/.local/share/applications/` takes precedence over `/usr/share/applications/`

```bash
mkdir -p ~/.local/share/applications
cp /usr/share/applications/app.desktop ~/.local/share/applications/

# Edit Exec line to include flags
sed -i 's|^Exec=app |Exec=app --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing |' \
    ~/.local/share/applications/app.desktop

# Refresh database
update-desktop-database ~/.local/share/applications
```

### Method 2: Electron Flags Config (System Electron Only)

**Only works if app uses system Electron, not bundled!**

```bash
# ~/.config/electron-flags.conf
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--disable-gpu-compositing
```

Some apps read `~/.config/appname-flags.conf` - check app docs.

### Method 3: Shell Alias
```bash
alias app='/opt/app/binary --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing'
```

### Method 4: Environment Variable
```bash
# Sometimes works
export ELECTRON_OZONE_PLATFORM_HINT=wayland
```

---

## Why Bundled Electron Ignores Configs

Many Electron apps (Beeper, Discord, Slack, VS Code) bundle their own Electron runtime rather than using system Electron.

**System Electron:**
```
/usr/lib/electron/electron
Reads: ~/.config/electron-flags.conf
```

**Bundled Electron:**
```
/opt/appname/appname (wrapper)
/opt/appname/electron (bundled)
Ignores: ~/.config/electron-flags.conf
Ignores: ~/.config/appname-flags.conf (usually)
```

For bundled apps, use **desktop file override** method.

---

## Known Apps & Solutions

| App | Bundled? | Solution |
|-----|----------|----------|
| Beeper | Yes | Desktop file override |
| Discord | Yes | Desktop file override |
| Slack | Yes | Desktop file override |
| VS Code | Yes | `~/.config/code-flags.conf` (exception) |
| Obsidian | Yes | Desktop file override |
| Spotify | Yes | Desktop file override |
| Signal | Varies | Desktop file override |

---

## GPU Compositing Deep Dive

### What It Does
GPU compositing uses the graphics card to composite (combine) rendered layers. This is faster but requires GPU context.

### Why It Breaks on Sleep/Wake
1. System enters sleep
2. GPU driver releases context
3. System wakes
4. Electron tries to use stale GPU context
5. Rendering fails → blank window

### The Tradeoff
| | GPU Compositing ON | GPU Compositing OFF |
|---|---|---|
| Performance | Faster rendering | Slightly more CPU |
| Power | Uses GPU | CPU only |
| Stability | May break on sleep | Stable |
| Animations | Smoother | Still smooth |

For most apps, `--disable-gpu-compositing` is worth the tradeoff.

---

## Debugging

### Check Current Rendering Backend
```bash
# Launch with verbose logging
APP_PATH --enable-logging --v=1 2>&1 | grep -i ozone

# Look for:
# "Using Ozone/Wayland" = native Wayland
# "Using Ozone/X11" = XWayland
```

### Check if Wayland Session
```bash
echo $WAYLAND_DISPLAY  # Non-empty = Wayland
echo $XDG_SESSION_TYPE # "wayland" or "x11"
```

### Test Flags Without Permanent Change
```bash
/opt/app/binary --enable-features=UseOzonePlatform --ozone-platform=wayland
```

---

## Hyprland-Specific

### Window Rules
If Electron app still misbehaves, add Hyprland window rules:

```ini
# ~/.config/hypr/hyprland.conf
windowrulev2 = float, class:^(appname)$, title:^(popup)$
windowrulev2 = noblur, class:^(appname)$
```

### Check Window Class
```bash
hyprctl clients | grep -A5 "class:"
```

---

*Last updated: 2026-01-16*
