# Session: Samsung Laptop Deep Setup & Optimization
**Date:** 2026-03-18
**Machine:** Samsung 270E5J (omarchy-samsung)
**Duration:** ~3 hours
**Scope:** Performance tuning, Claude Desktop install, MCP sync, memory bridge, custom instructions

---

## 1. Performance Diagnosis

### Problem
User reported slow page loads in Chrome Canary.

### Root Causes Found (5 layers)

| Layer | Finding | Severity |
|-------|---------|----------|
| **Memory** | Chrome Canary using 4,445 MB (56% of 7.7 GB total). 782 MB in zram swap. | CRITICAL |
| **Extensions** | 46 extensions installed. 6 inject into ALL pages with webRequest hooks. | CRITICAL |
| **Chrome flags** | Vulkan forced on Intel HD 4400 (marginal support). WebContentsForceDark re-rendering every page. 5 AI history features burning CPU. | HIGH |
| **CPU** | Load average 2.44 on 4 logical cores. One renderer at 8.9% CPU alone. | MODERATE |
| **Disk** | Spinning HDD (ST1000LM024), not SSD. Random I/O 100-1000x slower. | MODERATE |

### What was NOT the problem
- **Network:** DNS <1ms (systemd-resolved cache), ping 2.6-4.3ms, download 73 Mbps
- **Thermal:** 59-61C, no throttling
- **CPU governor:** schedutil (optimal for Haswell)

---

## 2. Chrome Canary Tuning

### Flags changed (`~/.config/chrome-canary-flags.conf`)

| Action | Flag | Rationale |
|--------|------|-----------|
| DISABLED | `Vulkan` | Intel HD 4400 has marginal Vulkan support. OpenGL is faster. MESA warns "incomplete." |
| DISABLED | `WebContentsForceDark` | Re-renders every page to invert colors. Adds CSS recalculation to every paint. |
| DISABLED | `HistoryEmbeddings` | TensorFlow Lite XNNPACK model running in background for AI history search. |
| DISABLED | `HistoryEmbeddingsAnswers` | Paired with HistoryEmbeddings. |
| DISABLED | `BrowsingHistoryActorIntegrationM1` | More AI history processing. |
| DISABLED | `BrowsingHistoryActorIntegrationM2` | More AI history processing. |
| DISABLED | `BrowsingHistorySimilarVisitsGrouping` | History clustering overhead. |
| ENABLED | `--enable-gpu-rasterization` | Offloads page rasterization from CPU to GPU. |
| ENABLED | `--enable-zero-copy` | Eliminates extra memory copies for GPU textures. |
| ADDED | `--num-raster-threads=4` | Uses all 4 logical cores for raster (was 2). |

### Key insight: field trials vs chrome://flags
The disabled features were NOT user-set flags. They came from Chrome Canary's server-side field trials (`--field-trial-handle`). The `--disable-features` flag in the conf file takes precedence and cleanly overrides them.

### Results (before/after Chrome restart)

| Metric | Before | After |
|--------|--------|-------|
| Chrome processes | 26 | 14 |
| System RAM used | 4.0 GB | 3.0 GB |
| RAM available | 3.6 GB | 4.6 GB |

### Extension Audit Results

- **46 extensions** total, **20 ghost entries** (uninstalled but registry not cleaned)
- **8 already disabled** by user
- **6 performance hotspots** (inject into ALL pages):
  - AdGuard AdBlocker (justified, core ad blocker)
  - Claude extension (needed for automation)
  - Browser MCP (needed for MCP automation)
  - cat-catch (media downloader, disable when not downloading)
  - RSSHub Radar (feed detection, toggle on-demand)
  - Vercel (webRequest on all pages, only useful on Vercel sites)
- **5 redundancy groups**: 3 bookmark managers, 4 extension inspectors, 9 GitHub enhancers, 2 markdown tools, 2 AI chatbot tools

---

## 3. Claude Desktop Installation

### Package choice: `claude-desktop-bin` (AUR)
Selected over 3 alternatives:
- `claude-desktop-appimage` rejected: bundles own Electron (~200 MB extra RAM on memory-constrained machine)
- `claude-desktop-native` rejected: community Rust rewrite at v0.14, 4 months stale, missing features
- `claude-desktop` rejected: abandoned, zero votes

### Wayland configuration
Created `~/.config/electron-flags.conf` (applies to ALL Electron apps):
```
--enable-features=UseOzonePlatform,WaylandWindowDecorations
--ozone-platform=wayland
--enable-wayland-ime
```

**Critical lesson:** Do NOT put `--force-device-scale-factor=0.75` in electron-flags.conf. That flag is Chrome-only (in chrome-canary-flags.conf). Putting it in electron-flags.conf caused Claude Desktop to render at 75% inside a 100%-sized window frame, creating grey padding.

### Auto-updater
- systemd user timer: daily check with 1h random delay
- `Persistent=true`: if machine is off at scheduled time, runs on next boot
- Desktop notification on successful update via notify-send
- Logs to `~/.local/share/claude-desktop/update.log`

### Credential persistence
- gnome-keyring auto-unlock added to Hyprland autostart
- Required because SDDM auto-login bypasses PAM keyring unlock (no password provided to PAM)
- `exec-once = echo -n "" | gnome-keyring-daemon --replace --unlock --components=pkcs11,secrets`

---

## 4. MCP Server Sync

### Before: CLI had 11 servers, Desktop had 7. Only 5 overlapped.

### After: Both have 13 servers each (12 overlapping).

| Server | CLI | Desktop | Added to |
|--------|-----|---------|----------|
| context7 | had | missing | Desktop |
| playwright | had | missing | Desktop |
| filesystem | had | missing | Desktop |
| time | had | missing | Desktop |
| github | had | missing | Desktop |
| memory | missing | had | CLI |
| memory-sync | new | new | Both |
| beeper | had | n/a | CLI only |
| cortex | had | n/a | CLI only |
| chrome (superpowers) | n/a | had | Desktop only |

### git MCP removed from CLI
Home directory (`/home/robthepirate`) is not a git repo. The MCP server requires an actual repository path. CLI has full git access via Bash and the github MCP handles GitHub API operations.

---

## 5. Chrome Extension (claude-in-chrome) Setup

### Problem
The native messaging host manifest only existed for regular Chrome and Chromium, not Chrome Canary.

### Fix
Symlinked Chrome Canary's manifest to Chrome's copy:
```
~/.config/google-chrome-canary/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json
  -> ~/.config/google-chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json
```

### Why symlink instead of copy
Claude Code auto-generates and maintains the Chrome/Chromium manifests on update. The symlink means Chrome Canary always gets the same manifest, including path updates when the binary version changes. The native host script at `~/.claude/chrome/chrome-native-host` has a hardcoded version path that Claude Code regenerates on self-update.

### Connection architecture
```
Chrome extension -> native messaging -> chrome-native-host binary -> Unix socket
Claude Code CLI -> connects to socket -> sends MCP commands -> native host relays to extension
```

### Known limitation
The bridge initializes at Claude Code CLI session start. If the socket doesn't exist yet (Chrome not running), it caches "not connected" and won't retry. Restart the CLI session to reconnect.

---

## 6. Memory Sync System

### Problem
CLI memories (16 files) are not accessible from Claude Desktop. Desktop Chat/Cowork conversations have no awareness of user context stored in CLI.

### Solution: Three-layer architecture
```
CLI Memory Files (source of truth)
    |
    v  (SessionEnd hook)
claude-memory-sync script
    |
    v
~/.claude/memory-profile.md (337 lines, compiled)
    |
    v  (memory-sync MCP server)
Both CLI and Desktop can call: get_user_profile, sync_memories
```

### Components
- **Sync script:** `~/.local/bin/claude-memory-sync` (bash, compiles .md files by type)
- **MCP server:** `~/.local/share/mcp-servers/memory-sync/server.cjs` (Node.js, exposes tools)
- **Hook:** SessionEnd in settings.json auto-triggers sync
- **Profile:** `~/.claude/memory-profile.md` (auto-generated, 337 lines)

### Sync is one-directional
CLI memories -> compiled profile -> Desktop reads. Desktop cannot write back to CLI memories.

---

## 7. Custom Instructions (Account-wide)

### Research findings
- Specific rules get ~89% compliance, vague ones ~35%
- Instructions should stay under 50 lines
- Anti-patterns (what NOT to do) are more impactful than positive instructions
- Background/context changes Claude's assumptions more than style preferences

### Key user identity corrections
- User is an **Agilist and Scrum Master**, NOT a software developer
- Codes in JS/TS/Python/Shell for tooling and automation, not enterprise apps
- Systems thinker, builder, community creator
- Located in Sao Paulo, Brazil (bilingual PT-BR/EN)

### Custom instructions reference memory-sync MCP conditionally
"If memory-sync MCP is available, call get_user_profile" ensures graceful degradation on machines without the MCP server.

### Pending: needs manual paste into claude.ai Settings -> Profile

---

## 8. System Dependencies Installed

| Package | Purpose | Command |
|---------|---------|---------|
| xdotool | Computer Use desktop automation (X11) | `sudo pacman -S xdotool` |
| scrot | Computer Use screenshots (X11 fallback) | `sudo pacman -S scrot` |
| python-pip | Python package manager | `sudo pacman -S python-pip` |
| python-secretstorage | Keyring access from Python | `sudo pacman -S python-secretstorage` |
| electron | Electron runtime for Claude Desktop | Via `claude-desktop-bin` dependency |
| Playwright chromium | Browser for playwright MCP | `npx -y playwright install chromium` |

Already present: grim, slurp, wl-clipboard, imagemagick, nodejs, uvx

---

## 9. Cortex DB Population

Inserted 16 memories into `~/.claude-cortex/memories.db`:
- 15 long_term memories (all CLI memory files)
- 1 episodic memory (this session summary)
- Categories: identity, preference, context, reference
- All scoped as global, transferable

---

## 10. Files Created/Modified This Session

### New files
| File | Purpose |
|------|---------|
| `~/.config/electron-flags.conf` | Wayland flags for all Electron apps |
| `~/.local/bin/claude-desktop-update` | Auto-updater script |
| `~/.config/systemd/user/claude-desktop-update.{service,timer}` | Systemd units |
| `~/.local/share/mcp-servers/memory-sync/server.cjs` | Memory-sync MCP server |
| `~/.local/bin/claude-memory-sync` | Memory compilation script |
| `~/.claude/memory-profile.md` | Compiled memory profile |
| `~/.config/google-chrome-canary/NativeMessagingHosts/...` | Symlink for native messaging |
| `~/.claude/projects/.../memory/project_claude_desktop.md` | Desktop setup memory |
| `~/.claude/projects/.../memory/project_custom_instructions.md` | Custom instructions memory |
| `~/.claude/projects/.../memory/feedback_no_dashes.md` | Writing style feedback |

### Modified files
| File | Change |
|------|--------|
| `~/.config/chrome-canary-flags.conf` | Added disable-features and GPU rasterization |
| `~/.config/hypr/autostart.conf` | Added keyring unlock |
| `~/.claude/settings.json` | Added SessionEnd hook for memory-sync |
| `~/.config/Claude/claude_desktop_config.json` | Added 5 MCP servers + memory-sync |
| `~/.claude/projects/.../memory/user_profile.md` | Updated role to Agilist/Scrum Master |
| `~/.claude/projects/.../memory/project_mcp_servers.md` | Updated to 13 CLI + 13 Desktop |
| `~/.claude/projects/.../memory/project_chrome_canary.md` | Updated with flag changes and extension audit |
| `~/.claude/projects/.../memory/MEMORY.md` | Updated index with new entries |
