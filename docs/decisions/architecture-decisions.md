# Architecture Decision Records

## ADR-001: Memory System Architecture (Three Layers)
**Date:** 2026-03-18
**Status:** Active

### Context
Claude Code CLI, Claude Desktop, and claude.ai web don't share memories natively. The user works across all three interfaces.

### Decision
Three-layer memory architecture:
1. **CLI Memory files** (source of truth) at `~/.claude/projects/<project>/memory/`
2. **Cortex DB** (vector-searchable) at `~/.claude-cortex/memories.db` with FTS5 + embeddings
3. **Memory Profile** (compiled bridge) at `~/.claude/memory-profile.md` served via MCP

### Consequences
- CLI is the write layer, Desktop/web are read-only consumers
- SessionEnd hook auto-syncs layer 1 to layer 3
- Cortex (layer 2) needs periodic re-sync when CLI memories change significantly
- Desktop can read CLI memories via `get_user_profile` MCP tool

---

## ADR-002: Chrome Canary Native Messaging via Symlink
**Date:** 2026-03-18
**Status:** Active

### Context
Claude Code auto-generates native messaging host manifests for Chrome and Chromium but not Chrome Canary.

### Decision
Symlink Chrome Canary's manifest to Chrome's copy instead of copying.

### Consequences
- Self-healing: Claude Code updates regenerate Chrome's manifest, Canary picks it up via symlink
- No manual maintenance needed on Claude Code updates
- If user installs regular Chrome, both share the same manifest

---

## ADR-003: Electron Flags Separation
**Date:** 2026-03-18
**Status:** Active

### Context
Chrome Canary uses `--force-device-scale-factor=0.75` for the 1366x768 display, but this flag applied globally to all Electron apps broke Claude Desktop rendering.

### Decision
- `~/.config/chrome-canary-flags.conf` contains Chrome-specific flags (scale factor, GPU rasterization, disabled features)
- `~/.config/electron-flags.conf` contains only Wayland flags (no scale factor)

### Consequences
- Chrome gets machine-specific scaling, all Electron apps get correct Wayland rendering
- New Electron apps automatically get Wayland support without configuration
- Scale factor changes only need updating in one file

---

## ADR-004: Claude Desktop via AUR (claude-desktop-bin)
**Date:** 2026-03-18
**Status:** Active

### Context
4 AUR packages available. Machine has 7.7 GB RAM.

### Decision
`claude-desktop-bin` over AppImage, native rebuild, or abandoned wrapper.

### Rationale
- AppImage bundles its own Electron (~200 MB extra RAM)
- Native (Rust rewrite) is at v0.14, 4 months stale
- `claude-desktop-bin` extracts official Anthropic binary, most maintained, highest community votes

---

## ADR-005: Keyring Auto-unlock for SDDM Auto-login
**Date:** 2026-03-18
**Status:** Active

### Context
SDDM auto-login bypasses PAM password prompt, leaving gnome-keyring locked. Electron apps can't persist credentials without an unlocked keyring.

### Decision
Add `exec-once` to Hyprland autostart that pipes empty password to gnome-keyring-daemon.

### Consequences
- Keyring unlocks on every boot even without password
- All apps (Claude Desktop, Warp, GitHub CLI) can persist credentials
- Trade-off: physical access to the machine grants keyring access (acceptable for personal dev laptop)

---

## ADR-006: Chrome Performance Flags Strategy
**Date:** 2026-03-18
**Status:** Active

### Context
Chrome Canary auto-enrolls in field trial experiments via `--field-trial-handle`. Several experiments are performance-negative on Intel HD 4400 (Haswell).

### Decision
Override field trials via `--disable-features` in chrome-canary-flags.conf rather than setting chrome://flags individually.

### Rationale
- `--disable-features` in conf file takes precedence over field trials
- Survives Chrome updates (field trials change, conf file stays)
- Centralized in one file, easy to audit
- chrome://flags experiments clear on major version updates

---

## ADR-007: Custom Instructions Design (Account-wide)
**Date:** 2026-03-18
**Status:** Active

### Context
Research shows specific rules get ~89% compliance vs ~35% for vague ones. Instructions over 50 lines see compliance drop.

### Decision
Custom instructions structured as: Identity (who) -> How I think (mental model) -> How I work (behavioral rules) -> Technical profile -> Never do -> Extended context (MCP reference).

### Key design choices
- "How I think" section is most impactful (changes Claude's solution structure)
- MCP reference is conditional ("if available") for cross-machine degradation
- Under 45 lines for optimal compliance
- Anti-patterns (Never do) section is minimal and specific

---

## ADR-008: Repo Classification Strategy
**Date:** 2026-03-18
**Status:** Active

### Decision
Three-tier classification for all configs:
- **Universal** (`universal/`): Works on any machine, no hardcoded paths or platform deps
- **Platform** (`platform/<os>/`): OS-specific (systemd, pacman, Wayland)
- **Machine** (`machines/<name>/`): Hardware-specific (display scale, GPU flags, CPU thread counts)

### Classification rules
- If it contains hardcoded paths (`/home/<user>`): machine-specific
- If it uses OS-specific tools (pacman, systemd): platform-specific
- If it uses only `$HOME` and standard tools: universal
- Memory files classified by content, not by format
