# wayland-cedilla-fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a public GitHub repository with a polished, animated Bash installer that fixes cedilla (ç) on Wayland compositors.

**Architecture:** Single self-contained Bash script (~500-700 lines) with animated CLI output, compositor auto-detection, safe backup+merge config strategy, and uninstall support. Distributed as a GitHub repo with AUR package.

**Tech Stack:** Bash 4+, ANSI escape codes, printf formatting, background processes for animation, GitHub CLI (gh) for repo management.

---

### Task 1: Create GitHub Repository

**Files:**
- Create: GitHub repo `wayland-cedilla-fix`
- Create: `LICENSE` (MIT)

**Step 1: Create the repository with gh CLI**

```bash
gh repo create robertogogoni/wayland-cedilla-fix \
  --public \
  --description "Fix ç cedilla on Wayland compositors (Hyprland, Sway, river, labwc). One command to make ' + c produce ç instead of ć across all apps." \
  --license mit \
  --clone
```

**Step 2: Set repository topics for discoverability**

```bash
gh repo edit robertogogoni/wayland-cedilla-fix \
  --add-topic cedilla \
  --add-topic c-cedilla \
  --add-topic dead-keys \
  --add-topic compose-key \
  --add-topic xcompose \
  --add-topic wayland \
  --add-topic linux \
  --add-topic wlroots \
  --add-topic arch-linux \
  --add-topic hyprland \
  --add-topic sway \
  --add-topic river \
  --add-topic labwc \
  --add-topic fcitx5 \
  --add-topic input-method \
  --add-topic portuguese \
  --add-topic brazilian-portuguese \
  --add-topic us-international
```

**Step 3: Verify repo exists and topics are set**

```bash
gh repo view robertogogoni/wayland-cedilla-fix --json name,description,repositoryTopics
```

---

### Task 2: Script Skeleton — Constants, Colors, Args

**Files:**
- Create: `cedilla-fix.sh`

Write the script header, version constant, ANSI color setup with NO_COLOR support, tty detection for motion, and argument parser supporting `--help`, `--check`, `--uninstall`, `--dry-run`, `--force`.

This is the foundation everything else builds on. The color/motion detection must come first because every subsequent function uses these variables.

Key details:
- `#!/usr/bin/env bash` with `set -euo pipefail`
- VERSION="1.0.0"
- Colors: RED, GREEN, YELLOW, BLUE, BOLD, RESET — all empty strings when NO_COLOR or non-tty
- HAS_MOTION: 1 when interactive tty + color, 0 otherwise
- BACKUP_DIR: `~/.local/share/wayland-cedilla-fix/backup/$(date +%Y%m%d-%H%M%S)`
- DRY_RUN, FORCE, MODE variables set by arg parser
- `usage()` function printing help text
- `die()` function for fatal errors with red output
- `warn()` function for yellow warnings
- `info()` function for normal output

**Step: Commit skeleton**

```bash
git add cedilla-fix.sh
git commit -m "feat: script skeleton with colors, args, and tty detection"
```

---

### Task 3: Animation Functions — Header, Spinner, Dots

**Files:**
- Modify: `cedilla-fix.sh`

Add the four animation primitives that drive the CLI experience:

**print_header()** — Box-drawing banner with dynamic centering:
- Fixed box width (w=54)
- `printf` with calculated padding for center-alignment
- ASCII-only content inside box (no emoji, no special chars)
- Falls back to plain text when HAS_MOTION=0

**spinner()** — Braille dot animation while background work runs:
- Takes PID and message as args
- 10-frame braille cycle: `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`
- 80ms per frame via `sleep 0.08`
- `\r` carriage return to overwrite line
- Checks `kill -0 $pid` to know when background task finishes
- Yellow spinner color while running

**progress_dots()** — Progressive dot fill during apply steps:
- Takes PID, label, step number, and total steps as args
- Dots fill left-to-right at 60ms intervals
- Max 13 dots
- Resolves to "done ✓" in green when PID exits
- Falls back to immediate "done" print when HAS_MOTION=0

**run_with_spinner()** — Wrapper that runs a function in background and shows spinner:
- `"$@" &` to background the actual work
- Captures PID
- Calls spinner() with the PID
- Waits for PID and captures exit code
- Returns the exit code

**run_with_dots()** — Same wrapper but with progressive dots animation.

**Step: Test animations manually**

```bash
chmod +x cedilla-fix.sh
bash cedilla-fix.sh --help
```

Verify: header renders with box-drawing, help text prints with colors, no errors.

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: animation functions — header, spinner, progressive dots"
```

---

### Task 4: Detection Functions

**Files:**
- Modify: `cedilla-fix.sh`

Add all detection functions. Each returns a result string and sets global variables. Each is designed to run in the background so the spinner can animate while detection happens.

**detect_compositor()** — sets COMPOSITOR and COMPOSITOR_VERSION:
- Check `hyprctl version 2>/dev/null` → "hyprland"
- Check `swaymsg -t get_version 2>/dev/null` → "sway"
- Check `pgrep -x river` → "river"
- Check `pgrep -x labwc` → "labwc"
- Check `$WAYLAND_DISPLAY` → "generic-wayland"
- Fallback → "unknown"

**detect_im()** — sets IM_FRAMEWORK and IM_VERSION:
- Check `fcitx5 --version 2>/dev/null` → "fcitx5"
- Check `ibus version 2>/dev/null` → "ibus"
- Fallback → "none"

**detect_session()** — sets SESSION_TYPE:
- Check `$XDG_SESSION_TYPE` or `$WAYLAND_DISPLAY` → "wayland"
- Fallback → "x11" or "unknown"

**detect_locale()** — sets LOCALE:
- Read `$LANG` or output of `locale` command

**detect_keyboard()** — sets KB_VARIANT and KB_NEEDS_FIX:
- For Hyprland: parse `hyprctl -j devices` for active keyboard variant
- For Sway: parse `swaymsg -t get_inputs`
- If variant contains "intl" → already has dead keys, KB_NEEDS_FIX=0
- Otherwise → KB_NEEDS_FIX=1

**detect_browsers()** — sets BROWSERS array:
- Check for chromium, brave, google-chrome-stable, chrome-canary, electron
- Only include browsers that are actually installed

**run_detection()** — orchestrator that calls each detect function with staggered spinner reveal:
- Print "Detecting system..."
- For each detection: run in background, show spinner, then print result line
- 150ms pause between each line for stagger effect
- Color-code results: green ✓ for good, yellow ⚠ for needs fix

**Step: Test detection on this system**

```bash
bash cedilla-fix.sh --check
```

Verify: all 5 detection lines appear with correct values for this MacBook Air.

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: detection functions for compositor, IM, session, keyboard, browsers"
```

---

### Task 5: Backup and Merge Utilities

**Files:**
- Modify: `cedilla-fix.sh`

**backup_file()** — Safe backup of a single file:
- Takes source path as arg
- Creates BACKUP_DIR if not exists
- Copies file preserving relative path structure: `cp --parents`
- Prints backup path if verbose
- No-op if source file doesn't exist (nothing to back up)

**merge_line()** — Idempotent line insertion:
- Takes file path, line content, and optional marker comment as args
- `grep -qF "$line" "$file"` to check if already present
- If not present, append with marker comment
- Returns 0 if line was added, 1 if already existed

**merge_block()** — Idempotent multi-line block insertion:
- Takes file path, block content, and marker tag
- Checks for marker tag in file to detect previous installation
- If marker exists, replace the block between markers
- If not, append block with start/end markers

**ensure_dir()** — Create directory for a file path if needed:
- `mkdir -p "$(dirname "$file")"`

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: backup and merge utilities for safe config modification"
```

---

### Task 6: Install Functions — XCompose + Environment

**Files:**
- Modify: `cedilla-fix.sh`

**install_xcompose()** — Create or merge ~/.XCompose:
- If file doesn't exist: create with full content (include + overrides)
- If file exists but missing `include "%L"`: prepend it
- If file exists but missing dead_acute overrides: append them
- Always idempotent via grep checks

Content to ensure present:
```
include "%L"
<dead_acute> <c> : "ç" ccedilla
<dead_acute> <C> : "Ç" Ccedilla
```

**install_environment()** — Create/merge environment.d config:
- Target: `~/.config/environment.d/cedilla.conf`
- Content: INPUT_METHOD, GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS, SDL_IM_MODULE, XCOMPOSEFILE
- Uses merge_block() with cedilla markers

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: install functions for XCompose and environment.d"
```

---

### Task 7: Install Functions — Compositor-Specific

**Files:**
- Modify: `cedilla-fix.sh`

**install_compositor_hyprland()** — Hyprland-specific config:
- Parse `~/.config/hypr/input.conf` for `kb_variant`
- If `kb_variant` has empty first position (before comma), change to `intl`
- Use sed to do in-place replacement of the kb_variant line
- Merge fcitx5 env block into envs.conf (or hyprland.conf if envs.conf doesn't exist)

**install_compositor_sway()** — Sway-specific config:
- Check for `~/.config/sway/config` or `~/.config/sway/config.d/`
- Add `input type:keyboard { xkb_variant intl }` if not present
- Add `exec --no-startup-id` env var exports or use sway config.d drop-in

**install_compositor_generic()** — Fallback for river/labwc/unknown:
- For labwc: merge env vars into `~/.config/labwc/environment`
- For river/generic: only install environment.d vars (compositor config is manual)
- Print note about manual compositor configuration if needed

**install_compositor()** — Router:
- Calls the correct sub-function based on COMPOSITOR variable

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: compositor-specific install functions (Hyprland, Sway, generic)"
```

---

### Task 8: Install Functions — fcitx5 + Browsers

**Files:**
- Modify: `cedilla-fix.sh`

**install_fcitx5()** — Configure fcitx5 profile:
- Check if fcitx5 is installed; if not, print warning and skip
- `kill -9` any running fcitx5 (SIGKILL to prevent profile overwrite on shutdown)
- Write new profile with keyboard-us-intl as default
- Start fcitx5 daemon in background
- Handle the expected non-zero exit from daemon fork (not an error)

**install_browsers()** — Add --enable-wayland-ime to all detected browsers:
- For each browser in BROWSERS array:
  - Map browser name to flags file path
  - merge_line() for `--enable-wayland-ime`
  - For electron: also merge `--ozone-platform-hint=wayland`
- Skip browsers not in BROWSERS array (not installed)

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: install functions for fcitx5 profile and browser Wayland IME flags"
```

---

### Task 9: Plan Display, Confirmation, and Main Install Flow

**Files:**
- Modify: `cedilla-fix.sh`

**show_plan()** — Display the change plan:
- Build a dynamic list of numbered steps based on detection results
- Only show steps that are actually needed (skip already-configured items)
- Show action type: "create" or "modify"
- Show backup directory path
- If --dry-run: print plan and exit

**confirm_or_exit()** — Ask user to proceed:
- Print "Apply changes? [Y/n]"
- If --force: skip prompt, proceed
- Read single character, default Y
- If not Y/y: print "Aborted." and exit

**run_install()** — Execute all install steps with animation:
- Calculate total steps dynamically
- For each install function: run_with_dots() with step counter
- Each step: backup first, then install

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: plan display, confirmation prompt, and main install orchestration"
```

---

### Task 10: Verify and Success Functions

**Files:**
- Modify: `cedilla-fix.sh`

**verify_compose()** — Check XCompose table:
- Run `xkbcli compile-compose` and grep for cedilla mapping
- If xkbcli not installed: skip with warning
- Return pass/fail

**verify_keyboard()** — Check keyboard variant:
- For Hyprland: `hyprctl -j devices` check
- For Sway: `swaymsg -t get_inputs` check
- Verify variant contains "intl"

**run_verify()** — Orchestrator:
- Run each verify function with spinner
- Print pass/fail for each

**print_success()** — Final success block:
- 400ms pause for dramatic effect
- Print separator, success message, uninstall/verify hints
- Line-by-line reveal at 100ms intervals

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: verification functions and success output"
```

---

### Task 11: Uninstall and Check Modes

**Files:**
- Modify: `cedilla-fix.sh`

**uninstall()** — Revert from backups:
- Find most recent backup dir in `~/.local/share/wayland-cedilla-fix/backup/`
- If no backups exist: error and exit
- For each file in backup: restore to original location
- Restart fcitx5 with original profile
- Print what was restored

**check_mode()** — Diagnostic mode (--check):
- Run all detection functions
- Show current state with pass/fail indicators
- Check if XCompose has cedilla overrides
- Check if environment vars are set
- Check if browser flags include wayland-ime
- Suggest fixes for any issues found

**Wire up main()** — Connect all modes:
- `--check` → run_detection() + check_mode()
- `--uninstall` → uninstall()
- default → run_detection() + show_plan() + confirm_or_exit() + run_install() + run_verify() + print_success()

**Step: Test full install flow on this system**

```bash
bash cedilla-fix.sh --dry-run
```

Verify: full animated output, plan shows correctly, exits without changes.

**Step: Commit**

```bash
git add cedilla-fix.sh
git commit -m "feat: uninstall, check mode, and main flow wiring"
```

---

### Task 12: README.md

**Files:**
- Create: `README.md`

Write the full README with:

1. **Title + badges**: name, AUR badge (placeholder), license badge, stars badge
2. **One-liner install**: `curl -fsSL ... | bash` prominently
3. **The Problem**: brief explanation with before/after — what goes wrong and why
4. **Quick Start**: clone + run alternative
5. **How It Works**: the 3-layer fix explained simply
6. **Compatibility Table**: compositors (Hyprland ✓, Sway ✓, river ✓, labwc ✓), distros (Arch ✓, Fedora untested, Ubuntu untested), browsers (Chromium ✓, Brave ✓, Electron ✓)
7. **Usage**: all script modes with examples
8. **Troubleshooting**: common issues (fcitx5 not installed, XWayland apps, GTK4 note)
9. **Uninstall**: how to revert
10. **Credits**: links to gnome-cedilla-fix, Arch forum thread, fcitx5 wiki
11. **License**: MIT

**Step: Commit**

```bash
git add README.md
git commit -m "docs: comprehensive README with install, compatibility, troubleshooting"
```

---

### Task 13: AUR Package + Issue Template

**Files:**
- Create: `PKGBUILD`
- Create: `.github/ISSUE_TEMPLATE.md`

**PKGBUILD**: as specified in design doc. `arch=('any')`, depends on bash + xkeyboard-config, optdepends on fcitx5 and xorg-xkbcli. Package function installs script to `/usr/bin/cedilla-fix`.

**.github/ISSUE_TEMPLATE.md**: structured bug report asking for:
- Compositor and version
- fcitx5 version (if installed)
- Output of `cedilla-fix.sh --check`
- What happened vs what was expected

**Step: Commit**

```bash
git add PKGBUILD .github/ISSUE_TEMPLATE.md
git commit -m "feat: AUR PKGBUILD and GitHub issue template"
```

---

### Task 14: Push and Final Verification

**Step 1: Push all commits to GitHub**

```bash
git push origin main
```

**Step 2: Verify repository looks correct**

```bash
gh repo view robertogogoni/wayland-cedilla-fix --web
```

**Step 3: Test the one-liner install path**

```bash
curl -fsSL https://raw.githubusercontent.com/robertogogoni/wayland-cedilla-fix/main/cedilla-fix.sh -o /tmp/cedilla-fix-test.sh
bash /tmp/cedilla-fix-test.sh --dry-run
```

Verify: downloads cleanly, dry-run shows full animated output.

**Step 4: Tag v1.0.0 release**

```bash
git tag -a v1.0.0 -m "v1.0.0: Initial release — Hyprland, Sway, river, labwc support"
git push origin v1.0.0
gh release create v1.0.0 --title "v1.0.0" --notes "Initial release. Supports Hyprland, Sway, river, labwc. One command to fix cedilla on Wayland."
```
