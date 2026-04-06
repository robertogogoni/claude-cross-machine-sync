---
name: Chrome Canary configuration
description: Chrome Canary 148 with performance-tuned flags, native messaging for Claude extension, dom-storage-sqlite disabled (broke X.com)
type: project
---

Chrome Canary 148.0.7766.0 is the default browser everywhere (XDG, MIME, $BROWSER env).

**Performance flags** (`~/.config/chrome-canary-flags.conf`):
- `--disable-features=Vulkan,WebContentsForceDark,HistoryEmbeddings,HistoryEmbeddingsAnswers,BrowsingHistoryActorIntegrationM1,BrowsingHistoryActorIntegrationM2,BrowsingHistorySimilarVisitsGrouping`
- `--enable-gpu-rasterization --enable-zero-copy --num-raster-threads=4`
- `--force-device-scale-factor=0.75` (Chrome only, NOT in electron-flags.conf)

**Claude Chrome extension** (v1.0.62, ID: fcoeoabgfenejglbffodgkkbkcdhcgfn):
- Native messaging host symlinked: `~/.config/google-chrome-canary/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json` -> Chrome's copy
- Survives Claude Code updates via symlink chain
- Needs CLI session restart to connect (bridge initializes at session start)

**Extensions:** 46 installed, audit completed 2026-03-18. 6 performance hotspots identified (Vercel, cat-catch, RSSHub Radar inject into all pages). 20 ghost entries from uninstalled extensions.

**Dangerous flags (disabled after investigation 2026-04-04):**
- `dom-storage-sqlite` — experimental SQLite localStorage backend, breaks X.com and other heavy SPAs. KEEP DISABLED.
- `render-document` — still enabled but risky, monitor for breakage on other sites.

**How to apply:**
- Enterprise policy protected by PreToolUse hook
- Electron-flags.conf (`~/.config/electron-flags.conf`) is GLOBAL for all Electron apps (no scale factor there, only Wayland flags)
- Verify at chrome://policy and chrome://flags
