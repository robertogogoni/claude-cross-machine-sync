# Troubleshooting Runbook

Operational guide for diagnosing and resolving failures in the Claude cross-machine sync environment. Every section follows the same structure: Problem, Symptoms, Diagnosis, Fix, Prevention.

---

## Table of Contents

1. [Chrome Extension "Not Connected" After Restart](#1-chrome-extension-not-connected-after-restart)
2. [MCP Server Failed to Connect](#2-mcp-server-failed-to-connect)
3. [Keyring Locked After Reboot](#3-keyring-locked-after-reboot-credentials-lost)
4. [Claude Desktop Shows Grey Area / Wrong Scaling](#4-claude-desktop-shows-grey-area--wrong-scaling)
5. [Chrome Canary Slow Page Loads](#5-chrome-canary-slow-page-loads)
6. [Memory Profile Out of Date](#6-memory-profile-out-of-date)
7. [Auto-Updater Not Running](#7-auto-updater-not-running)
8. [Native Messaging Host Broken After Claude Code Update](#8-native-messaging-host-broken-after-claude-code-update)
9. [Cortex DB Empty or Corrupted](#9-cortex-db-empty-or-corrupted)
10. [Bootstrap Fails on New Machine](#10-bootstrap-fails-on-new-machine)
11. [Git Sync Conflicts](#11-git-sync-conflicts)
12. [Extension Service Worker Dormant](#12-extension-service-worker-dormant)
13. [Settings.json Hook Blocks Legitimate File Edit](#13-settingsjson-hook-blocks-legitimate-file-edit)
14. [Beeper MCP Not Connecting](#14-beeper-mcp-not-connecting)
15. [Electron App Rendering in XWayland Instead of Native Wayland](#15-electron-app-rendering-in-xwayland-instead-of-native-wayland)

---

## 1. Chrome Extension "Not Connected" After Restart

### Problem
The Chrome MCP extension (Superpowers / Claude-in-Chrome) shows "not connected" or stops responding after a browser or system restart.

### Symptoms
- Extension popup says "Disconnected" or shows a red indicator
- `mcp__claude-in-chrome__*` tools return connection errors
- Claude Code reports "MCP server chrome is not available"

### Diagnosis
```bash
# Check if Chrome Canary is running at all
pgrep -fa "chrome.*canary" | head -5

# Check if the native messaging host process is alive
pgrep -fa "chrome_mcp\|native.messaging\|superpowers"

# Check if the native messaging host manifest exists
ls -la "$HOME/.config/google-chrome-canary/NativeMessagingHosts/" 2>/dev/null || ls -la "$HOME/.config/chromium/NativeMessagingHosts/" 2>/dev/null

# Check Chrome extension service worker status (look for errors in recent logs)
find "$HOME/.config/google-chrome-canary/Default/Service Worker" -name "*.log" -mmin -30 2>/dev/null | head -5

# Check if the expected socket/port is listening
ss -tlnp 2>/dev/null | grep -i "chrome\|mcp\|12345"
```

### Fix
```bash
# Step 1: Restart the extension's service worker
# In Chrome: navigate to chrome://extensions, find the MCP extension, click "Service Worker" link, or toggle off/on

# Step 2: If that fails, restart Chrome Canary entirely
pkill -f "chrome.*canary" && sleep 2 && google-chrome-canary &>/dev/null &

# Step 3: If the native host manifest is missing, reinstall it
# (adjust path to wherever your native host binary lives)
NATIVE_HOST_DIR="$HOME/.config/google-chrome-canary/NativeMessagingHosts"
mkdir -p "$NATIVE_HOST_DIR"
# Re-run the extension's install/setup script if available

# Step 4: Verify reconnection
sleep 3 && claude mcp list 2>/dev/null | grep -i chrome
```

### Prevention
- Pin the extension so the service worker stays active
- Add Chrome Canary to your login autostart
- Ensure the native messaging host manifest has correct absolute paths (no `~` or `$HOME`)

---

## 2. MCP Server Failed to Connect

### Problem
Any MCP server fails to start or drops its connection.

### Symptoms
- `claude mcp list` shows a server as "failed" or "disconnected"
- Tool calls to that server return timeout or connection refused errors
- Claude Code startup logs show MCP initialization failures

### Diagnosis
```bash
# List all MCP servers and their status
claude mcp list 2>&1

# Check if the server process is running (replace SERVER_NAME)
pgrep -fa "mcp\|server-memory\|sequential-thinking\|brave-search" | head -10

# Check if required binaries exist
which npx node uvx python3 2>/dev/null

# Check the MCP config for syntax errors
python3 -m json.tool "$HOME/.config/Claude/claude_desktop_config.json" > /dev/null 2>&1 && echo "JSON valid" || echo "JSON INVALID"

# Check if the server's port/socket is in use by something else
ss -tlnp 2>/dev/null | head -20

# Check for missing dependencies
npm ls -g @modelcontextprotocol/server-memory 2>/dev/null || echo "server-memory not installed globally"
```

### Fix
```bash
# Step 1: Validate and fix the config file
python3 -m json.tool "$HOME/.config/Claude/claude_desktop_config.json" > /dev/null 2>&1 || echo "Fix JSON syntax first"

# Step 2: Restart Claude Desktop to re-init all MCP servers
pkill -f "claude-desktop\|Claude Desktop" && sleep 2 && claude-desktop &>/dev/null &

# Step 3: For npm-based servers, reinstall
npm install -g @modelcontextprotocol/server-memory

# Step 4: For uvx-based servers (git, sqlite, fetch), install uvx first
pip install uv  # or: curl -LsSf https://astral.sh/uv/install.sh | sh

# Step 5: For servers needing API keys, verify env vars are set
grep -c "BRAVE_API_KEY" "$HOME/.claude/.env" 2>/dev/null && echo "Key present" || echo "Key MISSING"

# Step 6: Test a specific server manually
npx @modelcontextprotocol/server-memory --help 2>&1 | head -3
```

### Prevention
- Run `claude mcp list` after every config change
- Keep a backup of working `claude_desktop_config.json`
- Install `uvx` on every new machine as part of bootstrap
- Set API keys in shell profile, not just `.env`

---

## 3. Keyring Locked After Reboot (Credentials Lost)

### Problem
GNOME Keyring is locked after reboot, causing applications that rely on stored credentials (git, GPG, SSH, browser passwords) to fail silently or prompt unexpectedly.

### Symptoms
- `git push` asks for credentials that were previously saved
- Applications fail to authenticate to APIs
- SSH agent has no identities loaded
- Secret Service D-Bus calls fail

### Diagnosis
```bash
# Check if gnome-keyring-daemon is running
pgrep -fa gnome-keyring-daemon

# Check if the keyring is unlocked
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service OpenSession "sv" "plain" "s" "" 2>&1 | head -3

# Alternative: use secret-tool to probe
secret-tool lookup service test 2>&1; echo "Exit code: $?"

# Check if SSH keys are loaded
ssh-add -l 2>&1

# Check PAM config for auto-unlock
grep -r "pam_gnome_keyring" /etc/pam.d/ 2>/dev/null
```

### Fix
```bash
# Step 1: Unlock the keyring manually
echo -n "your-login-password" | gnome-keyring-daemon --unlock 2>/dev/null

# Step 2: If the daemon isn't running, start it
eval $(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2>/dev/null)
export SSH_AUTH_SOCK GNOME_KEYRING_CONTROL

# Step 3: Re-add SSH keys
ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null

# Step 4: If PAM auto-unlock isn't configured
# Add to /etc/pam.d/login (or sddm/gdm equivalent):
#   auth optional pam_gnome_keyring.so
#   session optional pam_gnome_keyring.so auto_start
```

### Prevention
- Ensure PAM is configured to auto-unlock the keyring on login
- Add `gnome-keyring-daemon --start` to your session startup (`.xinitrc` or systemd user unit)
- On Hyprland/Sway, add `exec-once = gnome-keyring-daemon --start --components=secrets,ssh,pkcs11` to config
- Store the keyring password as your login password so PAM unlocks it automatically

---

## 4. Claude Desktop Shows Grey Area / Wrong Scaling

### Problem
Claude Desktop renders with grey/blank areas, incorrect DPI scaling, or blurry text on HiDPI or non-standard resolution displays.

### Symptoms
- Parts of the window are grey or white with no content
- Text is blurry (fractional scaling artifacts)
- Window is too small or too large for the display
- Sidebar or chat area doesn't fill the window

### Diagnosis
```bash
# Check current display resolution and scale
wlr-randr 2>/dev/null || xrandr 2>/dev/null | grep -E "connected|current"

# Check Electron/Chromium flags being passed
grep -r "ozone\|scale\|dpi\|wayland" "$HOME/.config/Claude Desktop/" 2>/dev/null
cat "$HOME/.config/electron-flags.conf" 2>/dev/null
cat "$HOME/.config/claude-flags.conf" 2>/dev/null

# Check if running under Wayland or X11
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# Check GDK/Qt scale factors
echo "GDK_SCALE=$GDK_SCALE GDK_DPI_SCALE=$GDK_DPI_SCALE QT_SCALE_FACTOR=$QT_SCALE_FACTOR"

# Check Xresources DPI
xrdb -query 2>/dev/null | grep -i dpi
```

### Fix
```bash
# Step 1: Force correct scaling via electron flags
mkdir -p "$HOME/.config"
cat > "$HOME/.config/electron-flags.conf" << 'EOF'
--enable-features=UseOzonePlatform,WaylandWindowDecorations
--ozone-platform=wayland
--force-device-scale-factor=1
EOF

# Step 2: If using X11/XWayland, set DPI explicitly
echo "Xft.dpi: 96" | xrdb -merge

# Step 3: Set environment variables in your session
# Add to ~/.profile or window manager config:
# export GDK_SCALE=1
# export GDK_DPI_SCALE=1
# export QT_SCALE_FACTOR=1

# Step 4: Restart Claude Desktop with clean state
pkill -f "claude-desktop\|Claude Desktop" && sleep 1 && claude-desktop &>/dev/null &

# Step 5: If grey areas persist, try disabling GPU acceleration
# Add to electron-flags.conf: --disable-gpu
```

### Prevention
- Use integer scaling (1x or 2x), never fractional (1.25x, 1.5x)
- Set DPI via `Xft.dpi` in Xresources rather than relying on compositor scaling
- Keep `electron-flags.conf` in your dotfiles repo for sync across machines
- Test display changes with Claude Desktop before committing to new monitor configs

---

## 5. Chrome Canary Slow Page Loads

### Problem
Chrome Canary takes abnormally long to load pages, despite adequate network connectivity.

### Symptoms
- Pages take 10+ seconds to load
- Status bar shows "Resolving host..." or "Establishing connection..." for a long time
- Other browsers (Firefox, stable Chrome) load the same pages quickly
- High CPU usage from Chrome renderer processes

### Diagnosis
```bash
# Check Chrome process count and total memory
pgrep -c "chrome.*canary" 2>/dev/null; ps aux | grep "chrome.*canary" | awk '{sum+=$6} END {printf "Total RSS: %.0f MB\n", sum/1024}'

# Check network connectivity
curl -so /dev/null -w "DNS: %{time_namelookup}s, Connect: %{time_connect}s, Total: %{time_total}s\n" https://www.google.com

# Check if Chrome's DNS-over-HTTPS or async DNS is causing issues
grep -r "dns\|async\|predict" "$HOME/.config/google-chrome-canary/Local State" 2>/dev/null | head -5

# Check enabled Chrome flags count
python3 -c "
import json
with open('$HOME/.config/google-chrome-canary/Local State') as f:
    d = json.load(f)
    flags = d.get('browser', {}).get('enabled_labs_experiments', [])
    print(f'Enabled flags: {len(flags)}')
" 2>/dev/null

# Check available memory (Chrome is a memory hog)
free -h | head -2

# Check if extensions are consuming excessive resources
ls "$HOME/.config/google-chrome-canary/Default/Extensions/" 2>/dev/null | wc -l
```

### Fix
```bash
# Step 1: Kill zombie/excess renderer processes
pkill -f "chrome.*canary.*renderer" && sleep 1

# Step 2: Clear DNS cache in Chrome
# Navigate to: chrome://net-internals/#dns -> Clear host cache

# Step 3: If too many flags are enabled, audit them
# Navigate to: chrome://flags -> Reset all to default, then re-enable only needed ones

# Step 4: Disable prediction/preload if it's choking the network
# In chrome://settings/performance -> disable preloading

# Step 5: If memory is the bottleneck, reduce tab count or enable tab discarding
# chrome://flags/#automatic-tab-discarding -> Enable

# Step 6: Full restart with fresh profile caches
pkill -f "chrome.*canary" && sleep 2
rm -rf "$HOME/.config/google-chrome-canary/Default/Service Worker/CacheStorage/"*
google-chrome-canary &>/dev/null &
```

### Prevention
- Keep enabled Chrome flags under control (audit periodically)
- Use tab suspension/discard extensions
- Monitor Chrome memory with `scripts/claude-health`
- Restart Chrome weekly to clear accumulated bloat
- Keep Chrome Canary updated: it often gets perf regression fixes

---

## 6. Memory Profile Out of Date

### Problem
Claude Desktop or Claude Code has stale context because the memory profile (`MEMORY.md` or machine profiles) hasn't been updated.

### Symptoms
- Claude references old software versions, removed repos, or outdated hardware info
- Machine-specific advice doesn't match current setup
- Claude doesn't know about recently installed tools or changed workflows

### Diagnosis
```bash
# Check when memory files were last modified
find "$HOME/.claude" -name "MEMORY.md" -o -name "*.md" -path "*/memory/*" | while read f; do echo "$(stat -c '%Y %y' "$f" 2>/dev/null | cut -d. -f1)  $f"; done | sort -rn

# Check machine profile freshness
ls -la "$HOME/.claude/machines/" 2>/dev/null

# Check project-level memory
find "$HOME/.claude/projects" -name "MEMORY.md" -exec stat -c '%y  %n' {} \; 2>/dev/null | sort -r | head -10

# How old is the main memory file? (in hours)
if [ -f "$HOME/.claude/projects/-home-robthepirate/memory/MEMORY.md" ]; then
  age_sec=$(( $(date +%s) - $(stat -c %Y "$HOME/.claude/projects/-home-robthepirate/memory/MEMORY.md") ))
  echo "Memory age: $(( age_sec / 3600 )) hours ($(( age_sec / 86400 )) days)"
fi
```

### Fix
```bash
# Step 1: Update the memory index with current date
# Edit $HOME/.claude/projects/-home-robthepirate/memory/MEMORY.md
# Update the "# currentDate" section and any stale entries

# Step 2: Refresh machine profile
uname -a > /tmp/machine-info.txt
lscpu >> /tmp/machine-info.txt
free -h >> /tmp/machine-info.txt
lsblk >> /tmp/machine-info.txt
echo "Use this to update: $HOME/.claude/machines/"

# Step 3: Ask Claude to update its own memory in a session
# Just tell Claude: "Update your memory profile with current system state"

# Step 4: If using git sync, commit and push memory changes
cd "$HOME/.claude" && git add -A memory/ machines/ && git commit -m "Update memory profiles $(date +%F)" && git push 2>/dev/null
```

### Prevention
- Set a weekly calendar reminder to refresh memory profiles
- Add a memory freshness check to the health script (included in `claude-health`)
- After major system changes (new packages, new repos, hardware changes), immediately update memory
- Use the `currentDate` field in `MEMORY.md` as a staleness indicator

---

## 7. Auto-Updater Not Running

### Problem
Automatic update mechanisms (for Claude Desktop, Claude Code, Beeper, Chrome Canary, or system packages) are not running.

### Symptoms
- Running outdated versions of tools
- Security patches not applied
- `systemctl --user list-timers` doesn't show expected update timers
- No recent entries in update logs

### Diagnosis
```bash
# Check systemd user timers
systemctl --user list-timers 2>/dev/null | grep -iE "update\|upgrade\|claude\|beeper"

# Check if any update service failed
systemctl --user --failed 2>/dev/null

# Check crontab for update jobs
crontab -l 2>/dev/null | grep -iE "update\|upgrade\|claude\|beeper"

# Check Claude Code version
claude --version 2>/dev/null

# Check Beeper updater
ls -la "$HOME/.local/bin/update-beeper" 2>/dev/null
systemctl --user status update-beeper.timer 2>/dev/null

# Check pacman last update time (Arch)
grep "starting full system upgrade" /var/log/pacman.log 2>/dev/null | tail -1
```

### Fix
```bash
# Step 1: For Beeper auto-updater, re-enable the timer
systemctl --user enable --now update-beeper.timer 2>/dev/null

# Step 2: For Claude Code, update manually
npm update -g @anthropic-ai/claude-code 2>/dev/null

# Step 3: For system packages (Arch)
sudo pacman -Syu --noconfirm

# Step 4: Create a simple update timer if none exists
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/claude-update.service" << 'EOF'
[Unit]
Description=Update Claude Code

[Service]
Type=oneshot
ExecStart=/usr/bin/npm update -g @anthropic-ai/claude-code
EOF

cat > "$HOME/.config/systemd/user/claude-update.timer" << 'EOF'
[Unit]
Description=Weekly Claude Code Update

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now claude-update.timer
```

### Prevention
- Use systemd user timers for all recurring update tasks
- Check `systemctl --user list-timers` weekly
- Include auto-updater status in the health check script
- Subscribe to release notifications for critical tools

---

## 8. Native Messaging Host Broken After Claude Code Update

### Problem
After updating Claude Code (or the Chrome MCP extension), the native messaging host manifest points to an old binary path or has incorrect permissions.

### Symptoms
- Chrome extension shows "Native host has exited"
- `chrome://extensions` shows errors for the MCP extension
- Extension was working before the update

### Diagnosis
```bash
# Find all native messaging host manifests
find "$HOME/.config" -path "*/NativeMessagingHosts/*.json" 2>/dev/null -exec echo "=== {} ===" \; -exec cat {} \;

# Check if the binary referenced in the manifest actually exists
find "$HOME/.config" -path "*/NativeMessagingHosts/*.json" -exec grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' {} \; 2>/dev/null | while IFS='"' read -r _ _ _ path _; do
  [ -x "$path" ] && echo "OK: $path" || echo "MISSING/NOT EXEC: $path"
done

# Check Chrome's native messaging log
find "$HOME/.config/google-chrome-canary" -name "chrome_debug.log" -exec tail -20 {} \; 2>/dev/null

# Check permissions on the host binary
find "$HOME/.config" -path "*/NativeMessagingHosts/*.json" -exec grep -oP '"path"\s*:\s*"\K[^"]+' {} \; 2>/dev/null | xargs ls -la 2>/dev/null
```

### Fix
```bash
# Step 1: Find where the new binary actually is
which chrome-mcp-host 2>/dev/null || find "$HOME" /usr/local -name "*native*messaging*host*" -o -name "*chrome*mcp*" 2>/dev/null | head -5

# Step 2: Update the manifest with the correct path
MANIFEST_DIR="$HOME/.config/google-chrome-canary/NativeMessagingHosts"
# Edit the JSON file in $MANIFEST_DIR to point "path" to the correct binary

# Step 3: Ensure the binary is executable
# chmod +x /path/to/native-messaging-host

# Step 4: Restart Chrome to pick up the new manifest
pkill -f "chrome.*canary" && sleep 2 && google-chrome-canary &>/dev/null &

# Step 5: Verify
sleep 3 && find "$HOME/.config" -path "*/NativeMessagingHosts/*.json" -exec grep -oP '"path"\s*:\s*"\K[^"]+' {} \; 2>/dev/null | xargs ls -la 2>/dev/null
```

### Prevention
- After every Claude Code update, run: `find "$HOME/.config" -path "*/NativeMessagingHosts/*.json" -exec grep path {} \;`
- Keep a backup of working manifest files in your dotfiles
- Add a native messaging host check to the health script
- Pin the extension version if updates frequently break things

---

## 9. Cortex DB Empty or Corrupted

### Problem
The Cortex Claude memory system's database is empty, corrupted, or returning errors.

### Symptoms
- Memory queries return no results when they should
- Cortex MCP tools fail with database errors
- `sqlite3` reports "database disk image is malformed"
- Claude doesn't recall previously stored context

### Diagnosis
```bash
# Find the Cortex database
find "$HOME" -name "cortex*.db" -o -name "cortex*.sqlite" 2>/dev/null | head -5

# Check if the DB file exists and has content
CORTEX_DB=$(find "$HOME" -name "cortex*.db" -o -name "cortex*.sqlite" 2>/dev/null | head -1)
[ -n "$CORTEX_DB" ] && ls -la "$CORTEX_DB" && echo "Size: $(du -h "$CORTEX_DB" | cut -f1)" || echo "DB NOT FOUND"

# Check DB integrity
[ -n "$CORTEX_DB" ] && sqlite3 "$CORTEX_DB" "PRAGMA integrity_check;" 2>&1

# Count entries
[ -n "$CORTEX_DB" ] && sqlite3 "$CORTEX_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>&1

# Check for recent writes
[ -n "$CORTEX_DB" ] && stat -c "Last modified: %y" "$CORTEX_DB"
```

### Fix
```bash
# Step 1: If corrupted, try to recover
CORTEX_DB=$(find "$HOME" -name "cortex*.db" -o -name "cortex*.sqlite" 2>/dev/null | head -1)

# Attempt recovery via dump/restore
if [ -n "$CORTEX_DB" ]; then
  cp "$CORTEX_DB" "${CORTEX_DB}.bak.$(date +%s)"
  sqlite3 "$CORTEX_DB" ".recover" | sqlite3 "${CORTEX_DB}.recovered" 2>/dev/null
  if sqlite3 "${CORTEX_DB}.recovered" "PRAGMA integrity_check;" 2>/dev/null | grep -q "ok"; then
    mv "${CORTEX_DB}.recovered" "$CORTEX_DB"
    echo "Recovery successful"
  else
    echo "Recovery failed - manual intervention needed"
  fi
fi

# Step 2: If DB is empty but not corrupted, re-initialize
# Re-run cortex setup or re-import from backup

# Step 3: If DB is gone entirely, recreate from the cortex-claude project
# cd ~/cortex-claude && npm run setup  (or equivalent init command)

# Step 4: Restart the MCP server that uses Cortex
claude mcp list 2>/dev/null
```

### Prevention
- Back up the Cortex DB regularly: `cp "$CORTEX_DB" "$CORTEX_DB.bak"` in a cron job
- Use WAL mode for better crash resistance: `sqlite3 "$CORTEX_DB" "PRAGMA journal_mode=WAL;"`
- Include DB size and integrity in health checks
- Never kill Claude processes with `kill -9` -- use graceful shutdown to allow DB flush

---

## 10. Bootstrap Fails on New Machine

### Problem
Setting up the Claude Code environment on a fresh machine fails partway through.

### Symptoms
- Missing dependencies (node, npm, python, git)
- Config files not synced or incomplete
- MCP servers fail to start
- Permissions errors on config files

### Diagnosis
```bash
# Check essential tools
for cmd in node npm npx git python3 pip curl jq sqlite3 ssh-add; do
  which "$cmd" &>/dev/null && echo "OK: $cmd ($(command -v $cmd))" || echo "MISSING: $cmd"
done

# Check Node.js version (need 18+)
node --version 2>/dev/null

# Check if Claude Code is installed
which claude 2>/dev/null && claude --version 2>/dev/null || echo "Claude Code NOT INSTALLED"

# Check if config directories exist
for d in "$HOME/.claude" "$HOME/.claude/commands" "$HOME/.claude/skills" "$HOME/.claude/agents" "$HOME/.claude/machines" "$HOME/.claude/memory" "$HOME/.config/Claude"; do
  [ -d "$d" ] && echo "OK: $d" || echo "MISSING: $d"
done

# Check if settings files exist
for f in "$HOME/.claude/settings.json" "$HOME/.config/Claude/claude_desktop_config.json"; do
  [ -f "$f" ] && echo "OK: $f" || echo "MISSING: $f"
done
```

### Fix
```bash
# Step 1: Install essential packages (Arch Linux)
sudo pacman -S --needed nodejs npm python python-pip git curl jq sqlite base-devel

# Step 2: Install Claude Code
npm install -g @anthropic-ai/claude-code

# Step 3: Create directory structure
mkdir -p "$HOME/.claude"/{commands,skills,agents,machines,memory,logs,scripts/audit}
mkdir -p "$HOME/.config/Claude"

# Step 4: Clone/copy configs from your dotfiles repo or sync source
# git clone your-dotfiles-repo /tmp/dotfiles
# cp -r /tmp/dotfiles/.claude/* "$HOME/.claude/"

# Step 5: Set correct permissions
chmod 700 "$HOME/.claude"
chmod 600 "$HOME/.claude/.env" 2>/dev/null
chmod 644 "$HOME/.claude/settings.json" 2>/dev/null

# Step 6: Install MCP server dependencies
npm install -g @modelcontextprotocol/server-memory
pip install uv  # for uvx-based MCP servers

# Step 7: Verify
claude --version && claude mcp list 2>/dev/null
```

### Prevention
- Maintain a bootstrap script in your dotfiles repo
- Document all manual steps that can't be automated
- Test the bootstrap process in a VM or container periodically
- Keep a list of required packages in the repo (e.g., `packages.txt`)

---

## 11. Git Sync Conflicts

### Problem
Git-based config sync (dotfiles, memory files, machine profiles) has merge conflicts.

### Symptoms
- `git pull` fails with merge conflict markers
- Config files contain `<<<<<<<` conflict markers and break JSON parsing
- Claude Code fails to start due to malformed settings files

### Diagnosis
```bash
# Check for conflict markers in all config files
grep -rn "<<<<<<\|>>>>>>\|======" "$HOME/.claude/" 2>/dev/null

# Check git status
cd "$HOME/.claude" && git status 2>/dev/null

# Check if JSON files are valid
find "$HOME/.claude" -name "*.json" -exec sh -c 'python3 -m json.tool "$1" > /dev/null 2>&1 || echo "INVALID: $1"' _ {} \;

# Check git log for recent conflicts
cd "$HOME/.claude" && git log --oneline --merges -5 2>/dev/null
```

### Fix
```bash
# Step 1: Identify conflicted files
cd "$HOME/.claude" && git diff --name-only --diff-filter=U 2>/dev/null

# Step 2: For JSON files, take the newer version (ours = local, theirs = remote)
# To keep local version:
cd "$HOME/.claude" && git checkout --ours settings.json 2>/dev/null
# To keep remote version:
cd "$HOME/.claude" && git checkout --theirs settings.json 2>/dev/null

# Step 3: For memory/markdown files, manually merge (they're human-readable)
# Edit the conflicted file, remove conflict markers, keep the best content

# Step 4: Mark as resolved and complete the merge
cd "$HOME/.claude" && git add -A && git commit -m "Resolve sync conflicts $(date +%F)"

# Step 5: Validate all JSON after resolution
find "$HOME/.claude" -name "*.json" -exec sh -c 'python3 -m json.tool "$1" > /dev/null 2>&1 || echo "STILL INVALID: $1"' _ {} \;
```

### Prevention
- Use machine-specific branches and merge into main periodically
- Keep machine-specific configs in `settings.local.json` (not synced) rather than `settings.json`
- Use `git pull --rebase` instead of merge to keep history linear
- Avoid editing the same config files on multiple machines simultaneously

---

## 12. Extension Service Worker Dormant

### Problem
Chrome's Manifest V3 service workers go dormant after 5 minutes of inactivity, killing the MCP extension's background connection.

### Symptoms
- Extension works after browser launch but stops responding after ~5 minutes of inactivity
- Intermittent "not connected" errors
- Works again after manually clicking the extension icon

### Diagnosis
```bash
# Check Chrome's service worker status
# In Chrome: navigate to chrome://serviceworker-internals/
# Look for your extension's service worker - check "Running status"

# Check if keep-alive mechanisms are present in extension code
find "$HOME/.config/google-chrome-canary/Default/Extensions" -name "background.js" -o -name "service-worker.js" 2>/dev/null | xargs grep -l "keepAlive\|setInterval\|alarm" 2>/dev/null

# Check Chrome flags related to service workers
grep -o "service.worker[^\"]*" "$HOME/.config/google-chrome-canary/Local State" 2>/dev/null
```

### Fix
```bash
# Step 1: Enable the Chrome flag to extend service worker lifetime
# Navigate to chrome://flags/#extension-service-worker-keepalive
# Set to "Enabled"

# Step 2: If the extension supports it, enable its keep-alive option
# Check extension settings/options page

# Step 3: As a workaround, keep a Chrome tab open to the extension's options page
# Some extensions use this to keep the service worker alive

# Step 4: Restart Chrome with the new flags
pkill -f "chrome.*canary" && sleep 2 && google-chrome-canary &>/dev/null &
```

### Prevention
- Enable the service worker keepalive flag on every new Chrome profile
- Choose MCP extensions that implement proper keep-alive (alarms API, persistent connections)
- Keep the extension pinned and occasionally interact with it
- Consider using native messaging as a keep-alive mechanism (it prevents dormancy)

---

## 13. Settings.json Hook Blocks Legitimate File Edit

### Problem
The PreToolUse file protection hook prevents editing a file that you actually need to modify (false positive).

### Symptoms
- Claude Code refuses to edit a file with a message about protected files
- Error references the hook in `~/.claude/settings.json`
- The file is not actually sensitive but matches a protection pattern

### Diagnosis
```bash
# View the current hook configuration
python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    d = json.load(f)
    hooks = d.get('hooks', {})
    for hook_type, hook_list in hooks.items():
        for h in hook_list:
            print(f'{hook_type}: {h.get(\"matcher\", \"no matcher\")} -> {h.get(\"command\", h.get(\"hook\", \"no command\"))[:80]}')
" 2>/dev/null

# Check what patterns are being matched
grep -A5 "PreToolUse" "$HOME/.claude/settings.json" 2>/dev/null | head -20

# Check bash command log for the blocked operation
tail -5 "$HOME/.claude/logs/bash-commands.log" 2>/dev/null
```

### Fix
```bash
# Option 1: Temporarily disable the hook
# Edit $HOME/.claude/settings.json, comment out or remove the specific hook rule
# Make your edit, then re-enable the hook

# Option 2: Add an exception for the specific file
# Modify the hook's matcher pattern to exclude your file

# Option 3: Edit the file directly with a text editor (bypasses Claude Code hooks)
nano /path/to/the/file
# or
vim /path/to/the/file

# Option 4: Use the Bash tool to edit (if the hook only blocks the Edit tool)
# Claude can use sed/awk through Bash if the hook only intercepts Edit/Write tools
```

### Prevention
- Keep hook patterns specific (e.g., match exact filenames not broad globs)
- Use allowlists rather than blocklists when possible
- Document which files are protected and why in CLAUDE.md
- Test hook patterns after changes: intentionally try to edit a protected file

---

## 14. Beeper MCP Not Connecting

### Problem
The Beeper MCP server fails to connect, preventing chat/messaging operations through Claude.

### Symptoms
- `mcp__beeper__*` tools return connection errors
- `claude mcp list` shows beeper as failed/disconnected
- Beeper desktop app works fine but MCP bridge doesn't

### Diagnosis
```bash
# Check if Beeper is running
pgrep -fa beeper | head -5

# Check Beeper MCP server config
python3 -c "
import json
with open('$HOME/.config/Claude/claude_desktop_config.json') as f:
    d = json.load(f)
    beeper = d.get('mcpServers', {}).get('beeper', {})
    print(json.dumps(beeper, indent=2))
" 2>/dev/null

# Check if the Beeper MCP server process is running
pgrep -fa "beeper.*mcp\|mcp.*beeper" | head -5

# Check MCP server list for beeper status
claude mcp list 2>&1 | grep -i beeper

# Check Beeper version
beeper --version 2>/dev/null || flatpak info com.beeper.beeper 2>/dev/null | head -5

# Check if Beeper API is reachable
curl -s -o /dev/null -w "%{http_code}" "https://api.beeper.com" 2>/dev/null; echo
```

### Fix
```bash
# Step 1: Restart Beeper
pkill -f beeper && sleep 2 && beeper &>/dev/null &

# Step 2: Re-check MCP config syntax
python3 -m json.tool "$HOME/.config/Claude/claude_desktop_config.json" > /dev/null 2>&1 && echo "Config valid" || echo "Config INVALID - fix JSON"

# Step 3: If using a local bridge/proxy, restart it
# systemctl --user restart beeper-mcp-bridge 2>/dev/null

# Step 4: Update the Beeper MCP server
# If installed via npm: npm update -g @beeper/mcp-server
# If using update-beeper: $HOME/.local/bin/update-beeper

# Step 5: Restart Claude Desktop/Code to reconnect
pkill -f "claude-desktop" && sleep 2 && claude-desktop &>/dev/null &

# Step 6: Verify
sleep 3 && claude mcp list 2>&1 | grep -i beeper
```

### Prevention
- Ensure Beeper is in autostart
- Monitor the Beeper MCP connection in the health check script
- Keep Beeper updated (use the update-beeper auto-updater)
- Check `beeper-community/update-beeper` releases for known MCP issues

---

## 15. Electron App Rendering in XWayland Instead of Native Wayland

### Problem
Electron-based apps (Claude Desktop, Beeper, VS Code, etc.) fall back to XWayland instead of using native Wayland, causing blurriness, input lag, or missing Wayland-specific features.

### Symptoms
- Window title bar shows "(XWayland)" or `xprop` works on the window (Wayland windows don't respond to `xprop`)
- Blurry rendering at non-integer scales
- No touchpad gestures or smooth scrolling
- `xwayland` process shows the app in its tree
- Screen sharing shows black screen or wrong monitor

### Diagnosis
```bash
# Check if the app is running under XWayland or native Wayland
# If xprop can pick the window, it's XWayland
echo "Click on the window to test..." && timeout 5 xprop WM_CLASS 2>/dev/null && echo "XWayland (bad)" || echo "Native Wayland or timeout (check manually)"

# Check what platform Electron is using
strings /proc/$(pgrep -f "claude-desktop" | head -1)/cmdline 2>/dev/null | grep -i "ozone\|wayland\|x11"

# Check electron flags files
for f in "$HOME/.config/electron-flags.conf" "$HOME/.config/claude-flags.conf" "$HOME/.config/beeper-flags.conf" "$HOME/.config/code-flags.conf"; do
  [ -f "$f" ] && echo "=== $f ===" && cat "$f"
done

# Check environment variables
echo "ELECTRON_OZONE_PLATFORM_HINT=$ELECTRON_OZONE_PLATFORM_HINT"
echo "NIXOS_OZONE_WL=$NIXOS_OZONE_WL"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# Check if XWayland is running at all
pgrep -a Xwayland
```

### Fix
```bash
# Step 1: Create/update electron flags for the specific app
for app in electron claude beeper code; do
  cat > "$HOME/.config/${app}-flags.conf" << 'EOF'
--enable-features=UseOzonePlatform,WaylandWindowDecorations
--ozone-platform=wayland
EOF
done

# Step 2: Set the environment variable globally (affects all Electron apps)
# Add to ~/.profile or ~/.bash_profile:
echo 'export ELECTRON_OZONE_PLATFORM_HINT=wayland' >> "$HOME/.profile"

# Step 3: For .desktop file launchers, modify the Exec line
# Find the .desktop file
find /usr/share/applications "$HOME/.local/share/applications" -name "*claude*" -o -name "*beeper*" 2>/dev/null | head -5
# Add flags to the Exec line:
# Exec=claude-desktop --enable-features=UseOzonePlatform --ozone-platform=wayland %U

# Step 4: Restart the application
pkill -f "claude-desktop" && sleep 1 && claude-desktop &>/dev/null &

# Step 5: Verify it's now running under native Wayland
sleep 3 && echo "Click on the window..." && timeout 5 xprop WM_CLASS 2>/dev/null && echo "STILL XWayland" || echo "Native Wayland (or check manually)"
```

### Prevention
- Always create `*-flags.conf` files as part of machine bootstrap
- Set `ELECTRON_OZONE_PLATFORM_HINT=wayland` in your shell profile
- When installing new Electron apps, immediately create their flags file
- Keep flags files in your dotfiles repo for cross-machine sync
- Test after every Electron app update (some updates reset flags)

---

## Quick Reference: Common Diagnostic One-Liners

```bash
# System overview
echo "Uptime:"; uptime; echo "Memory:"; free -h; echo "Disk:"; df -h /; echo "CPU temp:"; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | awk '{printf "%.1fC\n", $1/1000}'

# All Claude processes
pgrep -fa "claude\|Claude" 2>/dev/null

# All MCP servers status
claude mcp list 2>&1

# Config validation (all JSON)
find "$HOME/.claude" "$HOME/.config/Claude" -name "*.json" -exec sh -c 'python3 -m json.tool "$1" > /dev/null 2>&1 || echo "INVALID: $1"' _ {} \;

# Recent hook activity
tail -20 "$HOME/.claude/logs/bash-commands.log" 2>/dev/null

# Chrome Canary health
pgrep -c "chrome.*canary" 2>/dev/null; ps aux | grep "chrome.*canary" | awk '{sum+=$6} END {printf "Chrome RSS: %.0f MB\n", sum/1024}'

# Keyring status
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service OpenSession "sv" "plain" "s" "" 2>&1 | head -1
```
