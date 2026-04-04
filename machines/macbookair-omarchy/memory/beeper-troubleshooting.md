# Beeper Troubleshooting & System Performance

Last updated: 2026-03-10

## Beeper Blank Screen — Recurring Issue

**Problem**: Beeper (Electron app) goes blank/white on Wayland/Hyprland. Has recurred across Jan 16, 21, 23, 27, 28.

### Root Causes (Multiple)

1. **GPU compositing failure** — Electron's GPU renderer crashes on Intel integrated graphics under Wayland
2. **Memory pressure** — 8GB RAM system runs out of memory when Chrome + Beeper + other apps are open. Renderer gets OOM-killed. Swap fills up.
3. **Wayland surface buffer issues** — Native Wayland mode has intermittent blank frames

### Fix Stack (Layered)

| Layer | Fix | Status |
|-------|-----|--------|
| **Wrapper script** | `~/bin/beeper-wayland` — launches with correct flags | Active |
| **Desktop entry** | `~/.local/share/applications/beeper-wayland.desktop` | Active |
| **System desktop hidden** | `~/.local/share/applications/beepertexts.desktop` with `NoDisplay=true` | Active |
| **Hyprland autostart** | `~/.config/hypr/autostart.conf` — `exec-once = ~/bin/beeper-wayland` | Active |
| **sysctl tuning** | `/etc/sysctl.d/99-performance.conf` — memory management | Active |
| **ananicy-cpp** | Process prioritization — installed via pacman | Active |

### Wrapper Script (`~/bin/beeper-wayland`)

Final version uses XWayland for stability:
```bash
#!/bin/bash
# Beeper Wrapper - XWayland mode for stability
# Wayland native has surface buffer issues causing blank screens
export ELECTRON_OZONE_PLATFORM_HINT=x11

exec /opt/beeper/beepertexts \
  --ozone-platform=x11 \
  --disable-gpu-compositing \
  "$@"
```

### Flags Tried (History)

| Flag | Result |
|------|--------|
| `--disable-gpu-compositing` | Helps but not enough alone |
| `--enable-features=UseOzonePlatform --ozone-platform=wayland` | Native Wayland — blank screen returns after minutes |
| `--use-gl=angle --use-angle=swiftshader` | Software rendering — still blanked |
| `--ozone-platform=x11` (XWayland) | Most stable, but uses X11 compat layer |
| Combined: x11 + disable-gpu-compositing | **Current winner** |

### Quick Fix When It Happens

```bash
pkill -9 beepertexts
sleep 1
~/bin/beeper-wayland &
```

Note: `killall -9 beepertexts` works better than `pkill -f beeper` (exit code 144 issue with pkill).

### Desktop Entry Override Pattern

User-level `.desktop` files in `~/.local/share/applications/` override system ones in `/usr/share/applications/`. To hide a system entry, create a user-level copy with `NoDisplay=true`.

**Duplicate icons fix**: Had 3 desktop files causing 2 icons. Fixed by adding `NoDisplay=true` to the user beeper.desktop override.

## System Performance Optimizations (8GB RAM)

### sysctl Tuning (`/etc/sysctl.d/99-performance.conf`)

```ini
# Reduce swappiness for better responsiveness
vm.swappiness = 10

# Faster memory reclaim
vm.vfs_cache_pressure = 100

# Optimized dirty page writeback for SSD
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10

# Prevent memory overcommit issues
vm.overcommit_memory = 0

# Network optimizations
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
```

### Installed Performance Tools

| Package | Purpose |
|---------|---------|
| `ananicy-cpp` | Process prioritization (auto-nice daemon) |
| `earlyoom` | OOM prevention — kills low-priority processes before system freezes |

### Memory Management Tips

- Close Chrome when not needed (biggest RAM consumer)
- Beeper + Chrome + Stremio together = guaranteed OOM
- Check memory: `free -h`, check swap: `swapon --show`
- ZRAM compressed swap is active

## Removed Software

### Cloudflare WARP / Zero Trust Client (removed 2026-01-21)

```bash
sudo pacman -Rns --noconfirm warp-cli
```
- Freed ~107MB
- Service stopped, data directory cleaned
- No longer on the system

## Rob's Communication Persona Model

Beeper chat skill at `~/.claude/skills/beeper-chat/SKILL.md` contains a "Rob model" — patterns extracted from 100+ messages for few-shot style transfer:

### Style Rules
```
LAUGH:    "lol" or "Lol", emoji reactions, NEVER "kkkkk"
TERMS:    "brother", "meu brother", "maninho" (never "bro" or "mano")
LENGTH:   2-5 words typical
CAPS:     Extended for hype: "ASAAAAAAP", "RULEIAAAA"
MIX:      EN+PT same sentence OR same thought in both languages
VIBE:     Quick reactive friend, not explainer
REACT:    Use emoji reactions heavily — often instead of text
```

### Connections Registry
- Location: `connections/` in `claude-cross-machine-sync` repo
- Contains profiles for people Claude has helped communicate with
- Includes communication preferences, context, and style notes

## Beeper Ecosystem Intelligence (2026-04-03)

### beeper-kb Knowledge Base
- Location: `~/repos/beeper-kb/` | MCP server in `~/.claude.json`
- **4,188 docs, 4,188 vectors** across 4 source types (docs: 58, github: 34, matrix-chat: 3,710, seed: 386)
- Data: `~/.beeper-kb/` (SQLite + FAISS)
- Port: **23374** (not 23373 — Beeper Desktop shifted ports)
- Auth token: extracted from `~/.config/Claude/Claude Extensions/local.dxt.beeper.beepermcp-remote/.mcp-auth/mcp-remote-0.0.1/e05f01523d80585f44047a268665720f_tokens.json`
- Deep harvest script: `~/repos/beeper-kb/scripts/deep-harvest.ts` (auto-detects port, reads MCP token, cursor-based pagination)

### Key Beeper API Details
- Base URL: `http://localhost:23374/v1/`
- Auth: Bearer token or OAuth 2.0 with PKCE
- Pagination: uses `cursor` parameter (NOT `before` — `before` returns same page!)
- Pass sortKey of last item as cursor value for next page
- Room IDs need URL encoding: `!` → `%21`, `:` → `%3A`
- API always returns 20 messages per page, ignores limit parameter
- Response has `items` and `hasMore` fields (no cursor field in response)
- Port auto-detect: `ss -tlnp | grep beepertexts` → match `0.0.0.0:PORT` (not 127.0.0.1)

### Strategic Intelligence
- **ai-bridge RENAMED to agentremote** — Beeper pivoting to AI agent platform
- 3 agent bridges (Codex, OpenClaw, OpenCode) near testing (Mar 6)
- AI Chats "coming very soon" (Batuhan, Mar 4)
- Translations built but unreleased (in nightly ~2 months)
- Webhooks still #1 request, not available
- Headless mode being worked on (no timeline)
- WebSocket events (GET /v1/ws) added Feb 13, undocumented

### Desktop Versions
- v4.2.692 (current install, Apr 2)
- v4.2.630 (Mar 9): Settings search, iMessage Tahoe fix, faster chat catchup
- v4.2.623: CRASH-LOOP bug ("Restart required"), fixed in nightly (Mar 7)
- v4.2.605 (Mar 3): Sidebar redesign (Space Bar)
- Nightly URL: `beeper.com/download/nightly/now`

### Harvested Chat Rooms
| Room | Messages Harvested | Date Range | KB Docs |
|------|-------------------|------------|---------|
| Beeper Developer Community | 4,603 (full harvest) | Aug 2025 – Apr 2026 | 3,710 |
| Self-hosted bridges on Beeper | prior harvest | Feb 2023 – Feb 2026 | 2 |

### Seeded Docs (Apr 2026 deep harvest)
- awesome-beeper: tools catalog, bridges, SDK examples, features, automation (5 docs, 35 chunks)
- update-beeper: changelog v1.0–v1.9, architecture/roadmap, pacman conflict fix (3 docs, 28 chunks)
- 448 unique authors in Dev Community, 3,134 conversation chunks from 4,603 messages

### Voyage AI Embeddings
- Key: paid tier (stored in `~/.claude.json` beeper-kb MCP config)
- Model: voyage-3, 1024 dimensions
- Batch settings: 32/batch, 200ms delay (paid tier — NOT 4/batch 21s free tier)
- Full re-embed (4,188 docs): ~30 seconds, 169K tokens
- ALWAYS use Voyage — never FTS-only mode (user directive)

### Key People
- **batuhan**: Lead Beeper dev, agentremote author, main info source
- **tulir**: Bridge maintainer (mautrix), mautrix-go architecture decisions
- **Jason L.**: Primary community support in Self-hosted bridges
- **David (mackid1993)**: iMessage v2 bridge author (Rust/RustPush)
- **Ludvig (lrhodin)**: Primary developer of Rust iMessage bridge
