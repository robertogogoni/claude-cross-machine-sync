# Auto Memory

## Topic Files (detailed references)

| File | Topic |
|------|-------|
| [cortex-project.md](cortex-project.md) | Cortex v3.0 architecture, adapters, hooks, CLI, benchmarks, roadmap |
| [github-repos.md](github-repos.md) | All GitHub repos, local clones, widgets, README audit, Actions workflows |
| [omarchy-update-pipeline.md](omarchy-update-pipeline.md) | Omarchy update chain, git rebase recovery, claude-code AUR setup, post-update hooks |
| [update-beeper.md](update-beeper.md) | update-beeper v1.8.0, desktop validation, icon install, two-tier strategy, pacman desync |
| [tty-toolchain.md](tty-toolchain.md) | VHS, asciinema, agg, gifsicle, gifski, ffmpeg — install & gotchas |
| [keyboard-cedilla.md](keyboard-cedilla.md) | fcitx5 cedilla configuration for pt-BR on Arch/Wayland |
| [system-maintenance.md](system-maintenance.md) | Arch system health checks, cleanup commands, known errors, fstab gotchas |
| [vercel-cloud-services.md](vercel-cloud-services.md) | Vercel projects (8), cloud MCP auth (Gmail/Calendar/Supabase), Supabase projects |
| [beeper-troubleshooting.md](beeper-troubleshooting.md) | Beeper blank screen fixes, wrapper script, sysctl tuning, persona model, ecosystem intelligence, beeper-kb |
| [feedback_always_voyage.md](feedback_always_voyage.md) | Always use Voyage API key for beeper-kb — never FTS-only mode |
| [hive-project.md](hive-project.md) | Hive — Beeper Intelligence Platform: 9 packages, 41 MCP tools, ~26 CLI commands, 586 tests, HTTP gateway, Beeper widget, Chrome extension. GitHub: robertogogoni/hive |

## Session Patterns & Gotchas

### Bash Tool: Never Pipe Daemon Output
When starting daemons (fcitx5, waybar, etc.) from the Bash tool, NEVER pipe their output (`cmd 2>&1 | tail`). This creates pipe deadlocks because the daemon stays alive indefinitely. Always redirect: `cmd > /dev/null 2>&1` or `cmd 2>/dev/null`.

### Stuck Session Recovery
- Kill stuck subprocesses (`tail`, `bash`) via PID without killing the Claude session
- `pstree -p <claude-pid>` shows the full tree of children
- Look for `bash -> tail` or `bash -> sleep` patterns

### pacman -Rdd Removes Files Too
`pacman -Rdd` is NOT database-only removal. It deletes package files AND the DB entry. To remove only tracking: move files aside → pacman -Rdd → restore files.

### Claude Code: Official Standalone Distribution Only
As of 2026-04-02, Claude Code is installed via the official standalone installer (`curl -fsSL https://claude.ai/install.sh | sh`). Binary lives at `~/.local/bin/claude` → `~/.local/share/claude/versions/<ver>`. Self-updates via `claude update`. AUR `claude-code` and npm global installs were removed. `"autoUpdates": true` in `~/.claude.json`.

### omarchy Source is READ-ONLY
Never commit to `~/.local/share/omarchy/`. It's git-managed by `omarchy-update-git`. Local commits cause rebase conflicts that block all future updates. Custom scripts → `~/.local/bin/`.

### VHS stdout Gotcha
Never redirect stdout to `/dev/null` in VHS tape commands. VHS captures terminal visual output — suppressed stdout = empty GIF.

### GIF Delta Encoding
GIF89a uses delta frames. Coalesce before extracting individual frames: `convert -coalesce demo.gif frame_%03d.png`

### PEP 668 on Arch Linux
Arch marks Python as "externally managed". Use `pipx install <pkg>` for CLI tools, venvs for libraries.

### vfat /boot: chmod Does Nothing
FAT32 ignores Unix permissions. Use `fmask`/`dmask` in `/etc/fstab`. `mount -o remount` does NOT apply new masks — must full `umount` then `mount`.

### dmesg Requires Root
Use `sudo dmesg` or `journalctl -k`.

### Beeper API Pagination: Use `cursor`, Not `before`
Beeper Desktop API pagination uses `cursor` parameter from previous response. Using `before=<sortKey>` returns the same 20 messages repeatedly. API always returns 20 per page regardless of `limit`. Room IDs need URL encoding (`!` → `%21`, `:` → `%3A`). Port can shift — check with `ss -tlnp | grep beeper` (currently 23374, was 23373).

### Cloud MCP Auth: Session Restart Required
Gmail, Google Calendar, Supabase MCP servers need browser OAuth. Auth is triggered at **session startup** by the connection manager. There's NO `claude mcp authenticate` command. Unauthenticated server tools don't appear in ToolSearch at all. Fix: exit session → restart → browser opens for OAuth.

### `claude doctor` Requires TTY
`claude doctor` uses Ink (React TUI framework) and fails with "Raw mode is not supported" when run from non-interactive shell or nested session. Run diagnostics manually instead (`claude mcp list`, `claude plugin list`, etc.).

### Chrome Canary Has Two Flag Layers
Flags come from TWO sources: (1) `chrome://flags` saved in `~/.config/google-chrome-canary/Local State` → `browser.enabled_labs_experiments` array, and (2) `~/.config/chrome-canary-flags.conf` → command-line flags injected by `/usr/bin/google-chrome-canary` wrapper. Editing Local State alone won't work — Chrome re-saves it on startup. Must edit BOTH, and Chrome must be fully dead before editing Local State. Diagnostic: `coredumpctl list | grep SIGILL` for CPU-incompatible JIT flags on Broadwell.

## Active Projects

### Cortex v3.0 — Memory OS for Claude Code
> Full reference: [cortex-project.md](cortex-project.md)
- **GitHub**: robertogogoni/cortex-claude | **Local**: `~/repos/cortex-claude/`
- **Installed**: `~/.claude/memory/` | **Version**: 3.0.0
- 7 MCP tools, 22 test files, 447+ tests passing
- Latest commit: `ef63180` — pushed 2026-03-09 (3 commits: phases F-K plans)

### wayland-cedilla-fix (v1.0.0 released, AUR live)
- **GitHub**: robertogogoni/wayland-cedilla-fix | **Local**: `~/wayland-cedilla-fix/`
- **AUR**: `wayland-cedilla-fix` — live at `aur.archlinux.org/packages/wayland-cedilla-fix`
- **AUR repo**: `~/repos/aur-wayland-cedilla-fix/` (separate git, remote: `ssh://aur@aur.archlinux.org/wayland-cedilla-fix.git`)
- SSH key for AUR: `~/.ssh/aur` (ed25519, configured in `~/.ssh/config`)
- 3-layer fix: compositor + fcitx5/XCompose + browser IME flags

### update-beeper (v1.8.0)
> Full reference: [update-beeper.md](update-beeper.md)
- **GitHub**: beeper-community/update-beeper | **Local**: `~/repos/update-beeper/`
- Two-tier updates (AUR → direct download) with pacman desync prevention
- Desktop shortcut validation, icon installation, stale cleanup (v1.8.0)
- Runs via systemd timer only (post-update hook removed 2026-04-02)

### awesome-beeper
- **GitHub**: robertogogoni/awesome-beeper | **Local**: `~/awesome-beeper/`
- Community Beeper docs with tools section (update-beeper, Beeper KB, Desktop API)

### datapub
- **GitHub**: robertogogoni/datapub (private) | **Local**: `~/repos/datapub/`
- Brazilian public document analysis (Assembleias Legislativas: AC, CE, GO, MS, PA)

### candle-craft-ux-vision (Supabase project)
- **GitHub**: robertogogoni/candle-craft-ux-vision (private)
- Uses `@supabase/supabase-js` with instance `hytdospixxjsncjrtzva.supabase.co`
- Needs Supabase MCP auth to manage DB from Claude Code

### Vercel Projects (8)
> Full reference: [vercel-cloud-services.md](vercel-cloud-services.md)
- 6 GitHub profile widgets (all READY)
- `chatgptbot` — production deploy ERROR, Probot app (serverless mismatch?)
- `memory` — ghost project, zero deployments (delete candidate)
- Duplicates: `github-trophies` vs `github-profile-trophy` (consolidate)

## System Info
- Machine: MacBook Air (2015), Arch Linux, Hyprland/Omarchy, user: rob
- Claude Code: v2.1.91 via official standalone installer (`~/.local/bin/claude` → `~/.local/share/claude/`)
- Claude Desktop: v1.2.234 (AUR `claude-desktop-bin`, with Cowork support)
- Claude Cowork Service: v1.0.40 (AUR, systemd user unit `claude-cowork.service` enabled)
- Beeper: v4.2.692 (direct install, pacman deregistered, desktop shortcut validated)
- Input method: fcitx5
- Node.js v25.1.0, Python 3.14.3, Go 1.26.1, Rust 1.94.1, Git 2.53.0, Docker 29.3.1
- Kernel: 6.19.9-arch1-1

# currentDate
Today's date is 2026-04-02.
