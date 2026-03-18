# Key Insights & Rationale

Central document capturing the WHY behind every major decision in this ecosystem.
Cross-references existing docs for the HOW.

---

## 1. Why Git as the Sync Transport

**Decision:** Use a git repo instead of Syncthing, rsync, or cloud storage.

**Rationale:**
- Git gives version history, rollback, and diff visibility for free
- Commit tags (`[universal]`, `[machine:name]`) make changes searchable by scope
- Conflicts are visible and resolvable (unlike silent overwrites in cloud sync)
- Works offline, syncs when ready
- GitHub Actions can validate configs on push

**Trade-off accepted:** Git is heavier than rsync for large binary files. Mitigated with Git LFS for episodic memory JSONL files (100MB+).

**See:** [cross-machine-sync.md](../learnings/cross-machine-sync.md), [machine-sync-patterns.md](../learnings/machine-sync-patterns.md)

---

## 2. Why Three-Tier Classification (Universal/Platform/Machine)

**Decision:** Every config file is classified into one of three tiers before syncing.

**Rationale:**
- A Chrome flag like `--num-raster-threads=4` works great on a 4-thread CPU but is wrong for a 2-thread one. That's machine-specific.
- A systemd timer works on any Linux machine but not Windows. That's platform-specific.
- A skill definition like `debugging/SKILL.md` works identically everywhere. That's universal.
- Without classification, bootstrapping a new machine would deploy configs that break it.

**The classification rule is simple:**
- Contains hardcoded paths (`/home/username`) or hardware values (scale factor, thread count)? **Machine.**
- Uses OS-specific tools (systemd, pacman, PowerShell)? **Platform.**
- Everything else? **Universal.**

**See:** [ADR-008](decisions/architecture-decisions.md), [repo-structure diagram](diagrams/repo-structure.md)

---

## 3. Why Memory Has Three Layers (Files, Cortex, Profile)

**Decision:** CLI memories exist as flat markdown files, are indexed in a Cortex vector DB, and compiled into a bridge profile for Desktop.

**Rationale:**
- **Flat files** are the source of truth because they're human-readable, diffable, and work without any runtime dependency. If Cortex crashes, files still work.
- **Cortex DB** adds semantic search (FTS5 + vector embeddings). You can query "what do I know about Beeper?" and get ranked results across all memories. Flat files can't do this.
- **Memory profile** solves the CLI-Desktop gap. Desktop has no access to CLI memory files natively. The compiled profile is served via MCP so Desktop can call `get_user_profile`.

**Why not just use Cortex for everything?** Cortex requires Node.js + SQLite + embeddings model. If any dependency breaks, all memory is lost. Flat files are the resilient fallback. Cortex is the intelligence layer on top.

**Why not just share the files directly via filesystem MCP?** Desktop would need to read 16 separate files with YAML frontmatter, parse and prioritize them. The compiled profile does this once, producing a clean 337-line document optimized for LLM consumption.

**See:** [memory-sync-bridge.md](../learnings/memory-sync-bridge.md), [memory-architecture diagram](diagrams/memory-architecture.md), [ADR-001](decisions/architecture-decisions.md)

---

## 4. Why Hookify Rules Use Keywords Instead of AI Classification

**Decision:** The 5 hookify rules match simple keyword patterns (e.g., "bug", "error", "crash" triggers debugging), not AI-powered intent detection.

**Rationale:**
- Keywords run in <1ms. AI classification adds 200ms+ latency to every prompt.
- False positives are cheap (skill suggestion you can ignore). False negatives are expensive (miss a debugging opportunity).
- The keyword approach was validated first. The AI intent detection (documented in [cli-intelligence-patterns.md](../learnings/cli-intelligence-patterns.md)) is a planned upgrade, not a replacement.
- 5 rules covering the most common patterns catch ~80% of cases. Diminishing returns beyond that.

**See:** [skill-enforcement-hooks.md](../learnings/skill-enforcement-hooks.md), [hookify-rules-flow diagram](diagrams/hookify-rules-flow.md)

---

## 5. Why Episodic Memory is Stored Raw (JSONL), Not Summarized

**Decision:** 1,402 conversation files are stored as raw JSONL with companion summary text files, not condensed.

**Rationale:**
- Raw data preserves context that summaries lose. A summary might say "fixed Beeper crash" but the raw conversation has the exact error message, stack trace, and the three approaches that didn't work.
- Storage is cheap (Git LFS handles large files). Information loss is expensive.
- The conversation-index SQLite DB provides searchability without needing to read raw files.
- Summaries are generated alongside (not instead of) raw data.

**Trade-off accepted:** The repo is larger (~200MB with LFS). But disk is cheap and git clone with LFS only downloads files when accessed.

---

## 6. Why Chrome Canary Instead of Stable Chrome

**Decision:** Chrome Canary is the default browser on all machines, not Chrome Stable or Chromium.

**Rationale:**
- Bleeding-edge features: Canary gets chrome://flags experiments months before stable
- The user's workflow relies on experimental features (Vertical Tabs, WebGPU, Vulkan exploration, AI history features)
- Canary has a separate profile from Stable, so it can be configured aggressively without risking a stable fallback
- On Arch Linux (rolling release), the "stable vs unstable" distinction matters less since everything updates continuously

**Trade-off accepted:** Occasional crashes from untested code. Mitigated by Chrome's crash recovery (restores tabs) and the fact that important work happens in Claude Code CLI, not in browser tabs.

**See:** [chrome-performance-tuning.md](../learnings/chrome-performance-tuning.md), [project_chrome_canary memory](../machines/samsung-laptop/memory/)

---

## 7. Why the Samsung Laptop's NVIDIA GPU is Disabled

**Decision:** The NVIDIA GeForce 710M/720M is intentionally kept dormant (no kernel module loaded).

**Rationale:**
- The 710M is Kepler-era (2013), weaker than the Intel HD 4400 for desktop compositing
- Loading nvidia kernel module would consume ~100-200MB RAM on a memory-constrained 8GB system
- It would require nvidia-prime/bumblebee/optimus switching, adding complexity for zero benefit
- Battery life would decrease (discrete GPU draws power even when idle if the module is loaded)
- Wayland (Hyprland) has better Intel support than NVIDIA support

**See:** [user_machine_samsung memory](../machines/samsung-laptop/memory/user_machine_samsung.md)

---

## 8. Why DPI Scaling Instead of Fractional Scaling

**Decision:** Use integer scale factor (1x) + DPI overrides instead of fractional scaling (0.75x).

**Rationale:**
- Fractional `QT_SCALE_FACTOR=0.75` makes Qt render at 75% resolution, then the compositor upscales the buffer. This causes sub-pixel artifacts and fuzzy text.
- DPI override (`QT_WAYLAND_FORCE_DPI=80`) makes Qt render at full native 1366x768 but computes smaller widget/font sizes. Zero blur, compact UI.
- The difference is where the math happens: fractional scaling = buffer resampling (lossy). DPI scaling = layout calculation (lossless).

**See:** [project_display_scaling memory](../machines/samsung-laptop/memory/project_display_scaling.md)

---

## 9. Why Separate electron-flags.conf from chrome-canary-flags.conf

**Decision:** Chrome-specific flags (scale factor, disabled features, raster threads) live in `chrome-canary-flags.conf`. Only Wayland flags live in `electron-flags.conf`.

**Rationale:**
- `electron-flags.conf` is read by ALL Electron apps launched via the system `electron` binary (Claude Desktop, Stremio, etc.)
- Putting `--force-device-scale-factor=0.75` there caused Claude Desktop to render at 75% inside a 100%-sized window, creating grey padding
- Chrome Canary has its own flags file and never reads `electron-flags.conf`
- The Wayland flags (`UseOzonePlatform`, `ozone-platform=wayland`, `wayland-ime`) are genuinely universal across all Electron apps

**Lesson learned the hard way:** This was discovered when Claude Desktop showed a small viewport with grey borders after the initial install.

**See:** [electron-wayland.md](../learnings/electron-wayland.md), [ADR-003](decisions/architecture-decisions.md)

---

## 10. Why Custom Instructions Reference MCP Conditionally

**Decision:** The account-wide custom instructions say "If memory-sync MCP is available, call get_user_profile" rather than always calling it.

**Rationale:**
- Custom instructions are stored server-side on the Anthropic account and apply to ALL machines
- The memory-sync MCP server only exists on machines where it's been deployed
- On a new machine (or mobile, or web), calling a nonexistent MCP tool would fail or confuse Claude
- The conditional phrasing lets Claude use the tool when available and skip it gracefully when not
- The basic preferences in the instruction text still provide useful context even without the MCP

**See:** [custom-instructions-optimization.md](../learnings/custom-instructions-optimization.md), [ADR-007](decisions/architecture-decisions.md)

---

## 11. Why Warp AI and Antigravity History Are Preserved

**Decision:** 1,708 Warp Terminal AI queries and 14 Antigravity/Gemini sessions are extracted and version-controlled.

**Rationale:**
- These represent months of problem-solving across GPT-5 and Gemini models. The solutions, failed approaches, and discovered patterns are valuable even if the tools themselves change.
- Warp stores queries in SQLite which could be wiped on updates. Extracting to CSV preserves them.
- Antigravity sessions are plain markdown in `~/.gemini/` which is not backed up by default.
- Cross-referencing AI history across tools reveals patterns: what kinds of problems go to which AI, where each model excels.

**See:** [ai-data-extraction.md](../learnings/ai-data-extraction.md), [ai-history-map diagram](diagrams/ai-history-map.md)

---

## 12. Why Bootstrap Uses Hardware Detection, Not Manual Config

**Decision:** `bootstrap.sh` auto-detects hardware (CPU, GPU, chassis type, hostname) instead of asking the user to select a machine profile.

**Rationale:**
- Manual selection is error-prone (user might pick wrong profile) and requires prior knowledge of available profiles
- Hardware detection via `/sys/class/dmi/id/` is deterministic and instant
- The detected hardware maps to a machine entry in `registry.yaml`, which determines which configs to deploy
- New machines auto-register as "pending" and get universal configs immediately, machine-specific configs after first export

**See:** [machine-sync-patterns.md](../learnings/machine-sync-patterns.md)

---

## Evolution Timeline

```
2026-01-17  Project created. Manual sync via git clone + cp.
            Extracted Warp AI + Antigravity history.

2026-01-18  Added hookify rules for skill enforcement.
            Created episodic memory plugin integration.

2026-01-23  Designed auto-categorization (universal/platform/machine).
            Built sync daemons for Linux + Windows.

2026-01-24  Designed CLI intelligence patterns.
            Skill activator v4 with AI intent detection.

2026-01-28  Designed unified Cortex vector database.

2026-02-02  Fixed Beeper package conflicts.
            Fixed GitHub profile widget permissions.

2026-02-15  Designed Beeper Extended v2 + Knowledge Base.

2026-02-25  Created wayland-cedilla-fix (AUR package).

2026-03-17  Samsung laptop: system packages, GPU drivers,
            display scaling fix, power management.

2026-03-18  Samsung laptop: Chrome performance tuning,
            Claude Desktop install, MCP sync (13+13),
            memory-sync bridge, custom instructions,
            full repo reorganization with 58 files.
            Added 11 diagram sets, 8 ADRs, comprehensive docs.
```
