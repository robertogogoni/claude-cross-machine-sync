# Beeper Knowledge Base

## Overview

Beeper is a unified messaging app that bridges multiple chat networks into one interface. It uses Matrix as the backend protocol with bridges to various services.

**Binary:** `/opt/beeper/beepertexts`
**Config directory:** `~/.config/BeeperTexts/`
**Logs:** `~/.config/BeeperTexts/logs/`

---

## Connected Accounts (rob's setup)

| Network | Account ID | User |
|---------|------------|------|
| Matrix/Beeper | `hungryserv` | rob (robertogogoni@outlook.com) |
| Instagram | `local-instagram_ba_iHTRH8df6mnA6hnktZQKq7ckMHY` | Roberto Gogoni |
| WhatsApp | `local-whatsapp_ba_eX8MK3jZfmVnsVRnF_cNDxIvT0I` | Roberto Gogoni (+5511975120101) |

---

## Wayland/Hyprland Fix

### Problem
Beeper windows render **completely blank** on Wayland compositors (Hyprland, Sway, etc.)

### Cause
Electron apps default to XWayland rendering. On pure Wayland setups or with certain GPU configurations, this causes blank/white windows.

### Solution
Launch Beeper with native Wayland/Ozone flags:

```bash
/opt/beeper/beepertexts --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing
```

**Flags explained:**
- `--enable-features=UseOzonePlatform --ozone-platform=wayland` - Enable native Wayland rendering
- `--disable-gpu-compositing` - Prevents blank screen after sleep/wake/screensaver cycles

### What DOESN'T Work
- `~/.config/beepertexts-flags.conf` - Beeper bundles its own Electron runtime and doesn't read this file
- `~/.config/electron-flags.conf` - Same reason
- `ELECTRON_OZONE_PLATFORM_HINT=wayland` env var - Not respected by bundled Electron

### Permanent Fix (Automatic)

The `update-beeper` script now handles this automatically! When running on Wayland, it:
1. Tests Beeper startup with native Wayland flags
2. Creates `~/.local/share/applications/beeper.desktop` override with Wayland flags

**Current desktop override location:** `~/.local/share/applications/beeper.desktop`

### Manual Fix Options (if needed)

**Option 1: Desktop file override**
```bash
mkdir -p ~/.local/share/applications
cp /usr/share/applications/beeper.desktop ~/.local/share/applications/
# Edit Exec line to include flags
```

**Option 2: Shell alias**
```bash
alias beeper='/opt/beeper/beepertexts --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing'
```

**Option 3: Wrapper script**
```bash
# /usr/local/bin/beeper-wayland
#!/bin/bash
exec /opt/beeper/beepertexts --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing "$@"
```

---

## Update Script

**Repository:** `~/repos/update-beeper/`
**Installed to:** `~/.local/bin/update-beeper`

### Usage
```bash
update-beeper           # Check and update if newer version available
update-beeper --check   # Check only, don't install
update-beeper --force   # Force reinstall even if up to date
update-beeper --changelog  # Open changelog in browser
```

### Features
- Automatic version checking (Beeper API vs installed vs AUR)
- Self-healing with retries for download/extraction failures
- Automatic rollback on failed updates
- Pre/post verification of permissions and startup
- **Wayland support:** Automatically sets up desktop override with native Wayland flags
- Backup management (keeps last 3 versions in `/opt/beeper-backups/`)

### Systemd Timer (automatic updates)
```bash
# Enable automatic update checks
systemctl --user enable --now update-beeper.timer
```

---

## MCP Integration

Beeper exposes an MCP server for Claude Code integration.

### Available Tools
- `mcp__beeper__search` - Search chats and messages
- `mcp__beeper__search_chats` - Search by title/participants
- `mcp__beeper__search_messages` - Search message content (literal word matching, NOT semantic)
- `mcp__beeper__get_chat` - Get chat details
- `mcp__beeper__list_messages` - List messages with pagination
- `mcp__beeper__send_message` - Send messages (supports markdown, replies)
- `mcp__beeper__focus_app` - Focus Beeper window, optionally navigate to chat
- `mcp__beeper__get_accounts` - List connected accounts
- `mcp__beeper__archive_chat` - Archive/unarchive chats
- `mcp__beeper__set_chat_reminder` / `clear_chat_reminder` - Reminder management

### Search Tips
- Message search is **literal word matching**, not semantic
- Use single words: `query="dinner"` not `query="dinner plans tonight"`
- Multiple words = AND matching (all must appear)
- Use `chatIDs` parameter to narrow search scope
- Use `scope="participants"` in search_chats to find by member names

### MCP Connection Issues
If MCP tools return "fetch failed":
1. Beeper app might be starting up - wait a few seconds
2. App crashed - restart Beeper
3. Window is blank - apply Wayland fix above

---

## Troubleshooting

### Blank Windows on Startup
See "Wayland/Hyprland Fix" section above.

### Blank Windows After Sleep/Wake/Screensaver
The `--disable-gpu-compositing` flag fixes this issue. Ensure your desktop file includes it:
```bash
Exec=beeper --no-sandbox --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing %U
```
Run `update-beeper` to automatically apply this fix.

### MCP Not Responding
```bash
# Check if Beeper is running
pgrep -a beepertexts

# Restart Beeper
pkill -9 -f beepertexts
/opt/beeper/beepertexts --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing &
```

### Check Logs
```bash
# Browser/main process logs
tail -f ~/.config/BeeperTexts/logs/browser/*.log

# Renderer logs
tail -f ~/.config/BeeperTexts/logs/renderer/*.log

# Platform worker (bridges)
tail -f ~/.config/BeeperTexts/logs/platform_worker-1/*.log
```

---

## Bridge Architecture

Beeper uses "bridges" to connect to external services. Each bridge runs as part of the platform worker.

**Supported bridges:**
- hungryserv (Matrix/Beeper native)
- whatsapp, local-whatsapp
- instagram, local-instagram
- telegram, local-telegram
- signal, local-signal
- discord (discordgo)
- slack (slackgo)
- facebook (facebookgo), local-facebook
- twitter, local-twitter
- linkedin, local-linkedin
- bluesky (local-bluesky)
- google messages (gmessages, local-gmessages)
- google chat (googlechat)
- google voice (local-gvoice)
- imessagecloud

"local-" prefixed bridges run entirely on the local machine (better privacy, requires phone/app running).

---

## Update-Beeper Project

### Repository
- **GitHub:** https://github.com/robertogogoni/update-beeper
- **Local:** `~/repos/update-beeper/`
- **Installed to:** `~/.local/bin/update-beeper`

### Architecture

```
update-beeper/
├── update-beeper          # Main script (~900 lines)
├── beeper-version         # Quick version status checker
├── install.sh             # One-line installer
├── CHANGELOG.md           # Keep a Changelog format
├── README.md              # Comprehensive docs with ASCII art
├── systemd/               # Timer and service files
│   ├── update-beeper-user.service
│   └── update-beeper-user.timer
└── .github/
    ├── workflows/
    │   ├── lint.yml              # ShellCheck linting
    │   └── update-version-badge.yml  # Daily version fetch
    └── badges/
        └── beeper-version.json   # shields.io endpoint
```

### Key Constants (update-beeper:7-27)
```bash
BEEPER_API="https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop"
INSTALL_DIR="/opt/beeper"
BACKUP_DIR="/opt/beeper-backups"
WAYLAND_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-compositing"
MIN_APPIMAGE_SIZE=150000000  # 150MB
```

### Version Badge System
- GitHub Action runs daily at 6 AM UTC
- Fetches latest version by following Beeper API redirect
- Writes to `.github/badges/beeper-version.json`
- shields.io endpoint badge reads this JSON
- README shows both Beeper Latest and AUR version badges

---

## Code Quality Patterns Learned

### 1. Subshell Pattern for Directory Safety
**Problem:** `cd` inside functions changes the working directory for the entire script.

**Bad:**
```bash
cleanup_old_backups() {
    cd "$BACKUP_DIR"           # ❌ Leaks directory change
    ls -t | tail -n +4 | xargs -r rm -rf
}
```

**Good:**
```bash
cleanup_old_backups() {
    (cd "$BACKUP_DIR" && ls -t | tail -n +4 | xargs -r sudo rm -rf)  # ✅ Isolated
}
```

The parentheses `()` create a subshell - any `cd` inside only affects that subshell.

### 2. Conditional Messages Based on Environment
**Problem:** Showing "Configuring Wayland..." on X11 confuses users.

**Solution:**
```bash
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    echo "Setting up Wayland desktop override..."
    setup_wayland_desktop_override
fi
```

### 3. Self-Healing Update Pipeline
**Pattern:** Verify → Retry with targeted fix → Rollback

```
Download → Verify size (>150MB)
    ↓ fail → clear temp, retry
Extract → Verify critical files exist
    ↓ fail → clear extract dir, retry
Install → Verify permissions
    ↓ fail → fix permissions, retry
Startup → Verify runs for 10s
    ↓ fail → clear Electron cache, retry
All retries exhausted → Automatic rollback
```

### 4. Critical Files to Verify
After Electron app extraction, always verify:
- Main binary (`beepertexts`)
- V8 snapshots (`snapshot_blob.bin`, `v8_context_snapshot.bin`)
- Version file (`resources/app/package.json`)

---

## Electron + Wayland Deep Dive

### Why Standard Electron Flags Don't Work
Beeper uses a **bundled Electron runtime** (not system Electron). This means:
- `~/.config/electron-flags.conf` - ignored (looks for system Electron)
- `~/.config/beepertexts-flags.conf` - ignored (not a recognized config)
- `ELECTRON_OZONE_PLATFORM_HINT` env var - ignored by bundled Electron

### The Desktop File Override Strategy
XDG spec says `~/.local/share/applications/` takes precedence over `/usr/share/applications/`.

1. Copy system desktop file to user directory
2. Modify `Exec=` line to include flags
3. Run `update-desktop-database` to refresh

### GPU Compositing Issue
**Symptom:** Beeper renders fine, but goes blank after sleep/wake/screensaver.

**Root cause:** GPU compositing uses GPU context that gets invalidated on sleep. Upon wake, Electron tries to use stale GPU state.

**Solution:** `--disable-gpu-compositing` forces CPU rendering. Slightly higher CPU usage but stable across power state changes.

---

## Beeper Developer Community

### Chat Details
- **Name:** Beeper Developer Community
- **Chat ID:** `!VRvJRVNZDbRuKAsKvK:beeper.com`
- **Purpose:** Developer discussions, tool sharing, API questions

### Announcement Tips (from experience)
- Keep messages short and casual
- Lead with the problem ("Frustrated with...")
- Include GitHub link
- Avoid em dashes (--) and LLM-sounding phrases
- Add a follow-up message with key features

### Messages Sent
1. Initial: Frustrated with Beeper updates on Arch → GitHub link
2. Follow-up: Works alongside AUR, auto-rollback, Wayland native

---

## API Endpoints

### Beeper Desktop Download
```
https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop
```
Returns a redirect to the actual AppImage URL. Extract version from redirect URL:
```bash
DOWNLOAD_URL=$(curl -Ls -o /dev/null -w "%{url_effective}" "$BEEPER_API")
VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'Beeper-\K[0-9]+\.[0-9]+\.[0-9]+')
```

### Changelog
```
https://www.beeper.com/changelog/desktop
```

---

## Debugging Commands

```bash
# Check installed version
/opt/beeper/beepertexts --version 2>/dev/null || \
    grep -o '"version": "[^"]*"' /opt/beeper/resources/app/package.json

# Check if Beeper is running
pgrep -a beepertexts

# Kill Beeper
pkill -9 -f beepertexts

# Launch with debug output
/opt/beeper/beepertexts --enable-logging --v=1 2>&1 | tee beeper.log

# Check desktop file being used
XDG_UTILS_DEBUG_LEVEL=2 xdg-mime query default x-scheme-handler/beeper

# Verify Wayland flags in active desktop file
grep "^Exec=" ~/.local/share/applications/beeper.desktop
```

---

## Session Learnings (2026-01-16)

### Problems Solved
1. **Blank windows on Wayland** → Ozone platform flags
2. **Blank after sleep/wake** → `--disable-gpu-compositing`
3. **Directory leaks in bash** → Subshell pattern
4. **AUR always behind** → Direct API download
5. **Built-in updater broken on Arch** → Bypass entirely

### Key Insights
- Electron apps bundling their own runtime ignore system-level Electron configs
- XDG desktop file hierarchy is powerful for per-user overrides
- GPU compositing issues manifest differently (blank vs crash vs artifacts)
- shields.io endpoint badges are great for dynamic version display

---

## Beeper Assistant Project (2026-01-16)

### Overview
Built an AI-powered chat assistant that:
1. Reads messages via Beeper MCP
2. Transcribes voice notes using Groq Whisper
3. Generates contextual responses in Rob's style
4. Sends messages autonomously

**Location:** `~/repos/beeper-assistant/`
**Skill:** `~/.claude/skills/beeper-chat/`

### Voice Transcription

**Script:** `~/repos/beeper-assistant/transcribe.py`

**Backends (in order):**
1. **Groq** - Fastest, free tier (`GROQ_API_KEY`)
2. **OpenAI** - Fallback (`OPENAI_API_KEY`)
3. **Local** - whisper.cpp (offline)

**Key fix:** Groq API requires file extension but Beeper stores audio without extensions.

Solution - detect mime-type and append extension:
```python
result = subprocess.run(['file', '--brief', '--mime-type', audio_path],
                      capture_output=True, text=True)
mime_type = result.stdout.strip()

ext_map = {
    'audio/ogg': '.ogg',
    'audio/opus': '.opus',
    'audio/mpeg': '.mp3',
    # ...
}

ext = ext_map.get(mime_type, '.ogg')
filename = Path(audio_path).name + ext

# Pass to API with extension
transcription = client.audio.transcriptions.create(
    file=(filename, audio_file.read()),
    model="whisper-large-v3-turbo",
)
```

### MCP Limitations Discovered

**`send_message` only supports text:**
```python
mcp__beeper__send_message(
    chatID="...",
    text="hello"  # NO attachment support
)
```

**No way to send voice notes via MCP currently.**

Workarounds being explored:
- Desktop automation (drag & drop)
- Direct Matrix bridge API
- WhatsApp Web direct integration

### Voice Note Locations

Beeper stores media at:
```
~/.config/BeeperTexts/media/localhostlocal-whatsapp/
```

Files have NO extensions - use `file --brief --mime-type` to detect format.

### Development Time

| Component | Time |
|-----------|------|
| update-beeper (full script) | ~2 hours |
| beeper-assistant (transcription + skill) | ~45 minutes |
| Voice emulation planning | ~30 minutes |

---

## Rob's Communication Model

Analyzed 50+ messages to build a persona model for AI responses.

### Patterns

| Pattern | Examples |
|---------|----------|
| Ultra-short | "Sad", "Chegou", "Good?" |
| Caps = hype | "RULEIA MUITO", "ASAAAAAAP" |
| "brother" | "meu brother", "you rock brother!!!" |
| "maninho" | "Valeu maninho" |
| EN+PT mix | "worth demais", "Mandou meu brother" |
| Multiple !!! | "you rock brother!!!" |
| Emoji reactions | ❤️ 😂 😢 (instead of text laughs) |

### Style Rules

```
LAUGH:    "lol" or emoji reactions, NEVER "kkkkk"
TERMS:    "brother", "meu brother", "maninho"
LENGTH:   2-5 words max typical
CAPS:     Extended: "ASAAAAAAP", "RULEIAAAA"
MIX:      EN+PT same sentence natural
VIBE:     Quick reactive friend, not explainer
```

### What NOT to do

- ❌ "kkkkk" (Brazilian laugh) - Rob doesn't use this
- ❌ Long explanations
- ❌ Markdown formatting
- ❌ Formal punctuation
- ❌ AI-style structured responses

---

## Voice Emulation Infrastructure (Planned)

### Pipeline

```
Claude → Text → ElevenLabs (Rob's voice) → Ogg Opus → Beeper → WhatsApp
```

### TTS Options

| Service | Quality | Samples | Cost |
|---------|---------|---------|------|
| ElevenLabs | Best | ~1 min | $5/mo |
| Play.ht | Good | ~30 sec | Free |
| Coqui XTTS | Decent | ~6 sec | Free |

### Audio Requirements (WhatsApp)

```
Format: Ogg Opus
Sample: 48000 Hz
Channels: Mono
Bitrate: ~32kbps
```

Conversion:
```bash
ffmpeg -i input.mp3 -c:a libopus -b:a 32k -ar 48000 -ac 1 output.ogg
```

### Blocker

Beeper MCP doesn't support sending attachments. Need workaround.

---

*Last updated: 2026-01-16*
