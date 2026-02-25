# wayland-cedilla-fix — Open Source Project Design

**Design Document**
**Date**: 2026-02-25
**Status**: Approved for Implementation
**Author**: Claude Code + Roberto Gogoni

---

## Overview

An open-source tool to fix the cedilla (ç) problem on Wayland compositors. When using the US International keyboard layout with `en_US` locale on Linux/Wayland, typing `' + c` produces ć (c-acute) instead of ç (c-cedilla). This is a 15+ year bug that affects Portuguese and other Latin-language speakers.

**Project name**: `wayland-cedilla-fix`
**Tagline**: Fix ç cedilla on Wayland — one command, all apps
**Repository**: `github.com/robertogogoni/wayland-cedilla-fix`
**License**: MIT

### Why This Project

| Existing Tool | Stars | Limitation |
|---|---|---|
| [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix) | 538 | GNOME/X11 only, no Wayland support |
| [win_us_intl](https://github.com/raelgc/win_us_intl) | 308 | GTK/KDE focused, partial Wayland |
| [Arch forum thread](https://bbs.archlinux.org/viewtopic.php?id=301265) | — | Manual steps, Hyprland-only, no automation |

**Gap**: No automated solution exists for Wayland compositors (Hyprland, Sway, river, labwc). Users must manually edit 7+ config files across 4 subsystems. This project fills that gap.

---

## Scope

**In scope (Wayland-first)**:
- Hyprland, Sway, river, labwc, and generic wlroots compositors
- fcitx5 as the input method framework
- Chromium, Brave, Chrome, and Electron app Wayland IME flags
- XCompose override for the cedilla mapping
- AUR package for Arch-based distros

**Out of scope (v1)**:
- X11-only desktops (GNOME on X11, i3, etc.) — covered by gnome-cedilla-fix
- IBus configuration — fcitx5 is the recommended IM for Wayland
- Non-cedilla compose overrides

---

## Architecture

### The 3-Layer Fix

The cedilla problem on Wayland requires fixing three independent layers:

```
Layer 1: Compositor           Layer 2: IM Framework         Layer 3: Applications
─────────────────────         ─────────────────────         ─────────────────────
Enable dead keys              Configure fcitx5              Enable Wayland IME
(kb_variant = intl)           + session env vars            (--enable-wayland-ime)
                              + XCompose override
```

All three must be configured for the fix to work globally across GTK3, GTK4, Qt, Electron, and Chromium apps.

### Detection Matrix

| Component | Detection Method | Config Target |
|---|---|---|
| **Hyprland** | `hyprctl version` or `$HYPRLAND_INSTANCE_SIGNATURE` | `~/.config/hypr/input.conf` + `hypr/envs.conf` |
| **Sway** | `swaymsg -t get_version` or `$SWAYSOCK` | `~/.config/sway/config` |
| **river** | `$XDG_CURRENT_DESKTOP` + process check | env vars only |
| **labwc** | process check | `~/.config/labwc/environment` |
| **Generic wlroots** | `$WAYLAND_DISPLAY` fallback | env vars + XCompose only |
| **fcitx5** | `command -v fcitx5` | `~/.config/fcitx5/profile` |
| **Chromium** | `command -v chromium` | `~/.config/chromium-flags.conf` |
| **Brave** | `command -v brave` | `~/.config/brave-flags.conf` |
| **Chrome** | check common paths | `~/.config/chrome-flags.conf` |
| **Electron** | `command -v electron` | `~/.config/electron-flags.conf` |

### Files Modified

| File | Action | Content |
|---|---|---|
| `~/.XCompose` | create/merge | `include "%L"` + `<dead_acute> <c> : "ç"` override |
| Compositor input config | merge | `kb_variant = intl` (dead keys) |
| Compositor env config | merge | `XMODIFIERS`, `QT_IM_MODULE`, `GTK_IM_MODULE`, `INPUT_METHOD`, `SDL_IM_MODULE` |
| `~/.config/environment.d/cedilla.conf` | create | Session-level IM env vars + `XCOMPOSEFILE` |
| `~/.config/fcitx5/profile` | replace | Switch to `keyboard-us-intl` |
| `~/.config/{browser}-flags.conf` | merge | `--enable-wayland-ime` |
| `~/.config/electron-flags.conf` | create/merge | `--enable-wayland-ime` + `--ozone-platform-hint=wayland` |

---

## Deliverable: Single Shell Script

### Repository Structure

```
wayland-cedilla-fix/
├── cedilla-fix.sh          # The script (install + uninstall + verify)
├── README.md               # Docs with badges, GIF, compatibility table
├── PKGBUILD                # AUR package
├── LICENSE                 # MIT
└── .github/
    └── ISSUE_TEMPLATE.md   # Bug report template
```

### Script Modes

```bash
cedilla-fix.sh              # Interactive install (default)
cedilla-fix.sh --check      # Verify current state, diagnose issues
cedilla-fix.sh --uninstall  # Revert all changes from backups
cedilla-fix.sh --dry-run    # Show plan, change nothing
cedilla-fix.sh --force      # Skip confirmation (for scripting)
cedilla-fix.sh --help       # Usage info
```

### Script Internal Structure

```
cedilla-fix.sh
├── Constants & colors
├── Utility functions
│   ├── print_header()          # Box-drawing banner
│   ├── spinner()               # Braille dot animation
│   ├── progress_dots()         # Progressive dot fill animation
│   ├── print_step()            # Staggered line reveal
│   ├── backup_file()           # Safe backup to timestamped dir
│   └── merge_line()            # Idempotent line merge into config
├── Detection functions
│   ├── detect_compositor()     # Hyprland/Sway/river/labwc/generic
│   ├── detect_im()             # fcitx5/ibus/none
│   ├── detect_session()        # Wayland/X11
│   ├── detect_locale()         # en_US/pt_BR/etc
│   ├── detect_keyboard()       # Current variant (intl or basic)
│   └── detect_browsers()       # Which Chromium/Electron apps installed
├── Install functions
│   ├── install_xcompose()      # Create/merge ~/.XCompose
│   ├── install_compositor()    # Compositor-specific dead keys + env vars
│   ├── install_environment()   # environment.d session vars
│   ├── install_fcitx5()        # Profile switch (kill -9 + write + start)
│   └── install_browsers()      # --enable-wayland-ime for each browser
├── Verify functions
│   ├── verify_compose()        # xkbcli compile-compose check
│   └── verify_keyboard()       # Keyboard variant check
├── Uninstall function
│   └── uninstall()             # Restore from backup dir
└── Main
    ├── parse_args()
    ├── run_detection()
    ├── show_plan()
    ├── confirm_or_exit()
    ├── run_install()
    ├── run_verify()
    └── print_success()
```

### Backup Strategy

All modified files backed up before changes:

```
~/.local/share/wayland-cedilla-fix/backup/<timestamp>/
├── .XCompose
├── hypr/input.conf
├── hypr/envs.conf
├── environment.d/fcitx.conf
├── fcitx5/profile
├── chromium-flags.conf
├── brave-flags.conf
└── electron-flags.conf
```

Uninstall restores from the most recent backup. Multiple install runs create separate backup snapshots.

### Merge Strategy (backup + merge)

For each config file:
1. Back up original to backup dir
2. Check if our lines already exist (idempotent)
3. If not present, append/insert at the correct location
4. Never overwrite user customizations — only add what's missing

---

## CLI Experience Design

### Header (Box-Drawing, ASCII-Only Content)

Uses `printf` with dynamic centering. Content inside box is ASCII-only to prevent alignment issues across terminals:

```bash
local w=54
local title="wayland-cedilla-fix  v${VERSION}"
local sub="Fix cedilla on Wayland -- one command, all apps"
printf "  ╔%${w}s╗\n" | tr ' ' '═'
printf "  ║%*s%s%*s║\n" $(( (w - ${#title}) / 2 )) "" "$title" $(( (w + 1 - ${#title}) / 2 )) ""
printf "  ║%*s%s%*s║\n" $(( (w - ${#sub}) / 2 )) "" "$sub" $(( (w + 1 - ${#sub}) / 2 )) ""
printf "  ╚%${w}s╝\n" | tr ' ' '═'
```

### Motion Elements

**1. Braille spinner** — while background work runs:
```bash
spinner() {
    local pid=$1 msg=$2
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${YELLOW}%s${RESET} %s" "${frames:i%10:1}" "$msg"
        i=$((i + 1))
        sleep 0.08
    done
}
```

**2. Staggered detection reveal** — each line appears one at a time with spinner while checking, then result snaps in with ~150ms spacing between items.

**3. Progressive dots during apply** — dots fill left-to-right at 60ms while background task runs:
```bash
progress_dots() {
    local pid=$1 label=$2 max=13
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % (max + 1) ))
        printf "\r  %s   %-*s" "$label" "$max" "$(printf '%*s' "$i" '' | tr ' ' '·')"
        sleep 0.06
    done
    printf "\r  %s   %-*s ${GREEN}done ✓${RESET}\n" "$label" "$max" "·············"
}
```

**4. Final success reveal** — 400ms pause after last verify, then success block appears line-by-line at 100ms intervals.

### Timing Rules

- Never add fake `sleep` to inflate perceived work
- Animation only runs while real background work happens
- Fast steps (10ms file writes) flash and resolve instantly
- Slow steps (fcitx5 restart ~500ms-2s) show natural spinner progression

### Graceful Degradation

```bash
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    HAS_COLOR=1   # ANSI colors
    HAS_MOTION=1  # spinners, dots, staggered reveals
else
    HAS_COLOR=0   # plain text: "ok" / "WARN" / "FAIL"
    HAS_MOTION=0  # no animation, static output
fi
```

Respects [NO_COLOR](https://no-color.org) standard. When piped or redirected, outputs clean static text suitable for logging.

### Full Output Mockup

```
  ╔══════════════════════════════════════════════════════╗
  ║          wayland-cedilla-fix  v1.0.0                 ║
  ║   Fix cedilla on Wayland -- one command, all apps    ║
  ╚══════════════════════════════════════════════════════╝

  Detecting system...

  ▸ Compositor     Hyprland 0.48.1            ✓
  ▸ Input method   fcitx5 5.1.12              ✓
  ▸ Session        Wayland                    ✓
  ▸ Locale         en_US.UTF-8                ✓
  ▸ Keyboard       us (no dead keys!)         ⚠ needs fix

  ── Plan ──────────────────────────────────────────────
  The following changes will be applied:

   1. ~/.XCompose           create   dead_acute + c → ç
   2. hypr/input.conf       modify   kb_variant → intl
   3. hypr/envs.conf        modify   add fcitx5 env vars
   4. environment.d/        modify   add GTK_IM_MODULE
   5. fcitx5/profile        modify   switch to us-intl
   6. chromium-flags.conf   modify   add --enable-wayland-ime
   7. electron-flags.conf   create   add --enable-wayland-ime

  Backups saved to ~/.local/share/wayland-cedilla-fix/backup/

  Apply changes? [Y/n]

  ── Applying ──────────────────────────────────────────

  [1/7] XCompose override          ············· done ✓
  [2/7] Hyprland dead keys         ············· done ✓
  [3/7] Input method env vars      ············· done ✓
  [4/7] Session env vars           ············· done ✓
  [5/7] fcitx5 profile             ············· done ✓
  [6/7] Chromium Wayland IME       ············· done ✓
  [7/7] Electron Wayland IME       ············· done ✓

  ── Verify ────────────────────────────────────────────

  ▸ xkbcli compose check   dead_acute + c → ç    ✓
  ▸ Keyboard variant        us-intl (dead keys)   ✓

  ══════════════════════════════════════════════════════
  ✓ Done! Log out and back in, then test: ' + c → ç

  Uninstall anytime:  cedilla-fix.sh --uninstall
  Verify anytime:     cedilla-fix.sh --check
  ══════════════════════════════════════════════════════
```

---

## GitHub Discoverability

### Repository Description

> Fix ç cedilla on Wayland compositors (Hyprland, Sway, river, labwc). One command to make ' + c produce ç instead of ć across all apps.

### Topics (18 tags)

| Category | Tags |
|---|---|
| The problem | `cedilla`, `c-cedilla`, `dead-keys`, `compose-key`, `xcompose` |
| Platform | `wayland`, `linux`, `wlroots`, `arch-linux` |
| Compositors | `hyprland`, `sway`, `river`, `labwc` |
| IM framework | `fcitx5`, `input-method` |
| Language/users | `portuguese`, `brazilian-portuguese`, `us-international` |
| Type | `keyboard`, `configuration`, `installer` |

### README Strategy

- One-liner install at the very top
- Animated GIF of the install experience
- Before/after demonstration
- Compatibility table (compositors, distros, browsers)
- Technical explanation of the 3-layer fix
- Troubleshooting section
- Links to gnome-cedilla-fix and Arch forum thread

### Cross-Promotion

- Comment on [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix) issues mentioning Wayland support
- Answer/link from [Arch forum thread](https://bbs.archlinux.org/viewtopic.php?id=301265)
- Submit to Awesome Hyprland / Awesome Sway lists

---

## AUR Package

```bash
pkgname=wayland-cedilla-fix
pkgver=1.0.0
pkgrel=1
pkgdesc="Fix cedilla (c) on Wayland compositors - one command, all apps"
arch=('any')
url="https://github.com/robertogogoni/wayland-cedilla-fix"
license=('MIT')
depends=('bash' 'xkeyboard-config')
optdepends=(
    'fcitx5: recommended input method for full Wayland coverage'
    'xorg-xkbcli: post-install compose table verification'
)
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/v${pkgver}.tar.gz")

package() {
    install -Dm755 "${srcdir}/${pkgname}-${pkgver}/cedilla-fix.sh" \
        "${pkgdir}/usr/bin/cedilla-fix"
    install -Dm644 "${srcdir}/${pkgname}-${pkgver}/LICENSE" \
        "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
```

Users install with `yay -S wayland-cedilla-fix`, then run `cedilla-fix` to apply.

---

## Technical Considerations

### fcitx5 Profile Persistence

fcitx5 saves its in-memory state on graceful shutdown, overwriting the profile file. The script must:
1. `kill -9` fcitx5 (SIGKILL, no shutdown handler)
2. Write the new profile
3. Start fcitx5 fresh

### Idempotent Merge

Running the script multiple times must be safe. Each merge function checks if the target line already exists before adding it. Pattern: `grep -qF "$line" "$file" || echo "$line" >> "$file"`.

### XCompose Include

The `include "%L"` directive loads the system locale's default compose table, then our overrides take precedence. This preserves all other compose sequences while only changing dead_acute + c/C.

### GTK4 Limitation

GTK4 has no cedilla IM module (`im-cedilla.so` exists only for GTK3). The fcitx5 + XCompose approach works for GTK4 because fcitx5 intercepts key events at the Wayland text-input protocol level, before the toolkit processes them.
