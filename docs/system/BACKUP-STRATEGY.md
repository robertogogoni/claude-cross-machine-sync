# Backup Strategy

What lives outside this git repo and needs independent backup.

This repo handles Claude Code configs, learnings, and machine profiles. Everything below lives only on the local machine and would be lost without a separate backup.

---

## Critical (lose work if lost)

### Cortex Database
| | |
|-|-|
| **What it contains** | Vector embeddings (384-dim) + FTS5 full-text index of all CLI memories. Powers semantic search across every memory file. Rebuilt from scratch takes hours of re-embedding. |
| **Where it lives** | `~/.claude-cortex/memories.db` (SQLite) |
| **How to backup** | `rsync -a ~/.claude-cortex/ "$BACKUP_DIR/claude-cortex/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/claude-cortex/" ~/.claude-cortex/` |
| **Frequency** | Daily (embeddings change with every memory update) |
| **Size estimate** | 50-200 MB depending on memory count |

### Chrome Canary Profile
| | |
|-|-|
| **What it contains** | Bookmarks, saved passwords (encrypted), extension installs + settings, browsing history, open tabs, autofill data, cookies/sessions. The 66 custom flags are already in this repo at `machines/<hostname>/chrome-canary-flags.conf`. |
| **Where it lives** | `~/.config/google-chrome-canary/` |
| **How to backup** | `rsync -a --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' --exclude='Service Worker/CacheStorage' ~/.config/google-chrome-canary/ "$BACKUP_DIR/chrome-canary/"` |
| **How to restore** | Close Chrome Canary first. `rsync -a "$BACKUP_DIR/chrome-canary/" ~/.config/google-chrome-canary/` |
| **Frequency** | Daily |
| **Size estimate** | 500 MB - 2 GB (excluding caches; with caches can be 5-10 GB) |

### Keyring
| | |
|-|-|
| **What it contains** | GNOME Keyring or KDE Wallet stored credentials: WiFi passwords, application tokens, GPG passphrases, SSH key passphrases. Used by Chrome, NetworkManager, and other apps. |
| **Where it lives** | `~/.local/share/keyrings/` |
| **How to backup** | `rsync -a ~/.local/share/keyrings/ "$BACKUP_DIR/keyrings/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/keyrings/" ~/.local/share/keyrings/` then `chmod 700 ~/.local/share/keyrings && chmod 600 ~/.local/share/keyrings/*` |
| **Frequency** | Weekly or on change (credentials don't change often) |
| **Size estimate** | < 1 MB |

### SSH Keys
| | |
|-|-|
| **What it contains** | Private and public key pairs for GitHub, remote servers, and other SSH-authenticated services. Losing these means regenerating and re-registering keys everywhere. |
| **Where it lives** | `~/.ssh/` |
| **How to backup** | `rsync -a ~/.ssh/ "$BACKUP_DIR/ssh/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/ssh/" ~/.ssh/` then `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub ~/.ssh/config ~/.ssh/known_hosts` |
| **Frequency** | On change (new key generated, new host added to config) |
| **Size estimate** | < 100 KB |

---

## Important (annoying to recreate)

### Claude Desktop Config
| | |
|-|-|
| **What it contains** | MCP server definitions (10 servers with API keys and paths), window size/position preferences, session metadata, conversation cache. The MCP server template is in this repo at `universal/claude/claude-desktop-config.template.json`, but the live config has machine-specific paths and real API keys. |
| **Where it lives** | `~/.config/Claude/` |
| **How to backup** | `rsync -a ~/.config/Claude/ "$BACKUP_DIR/claude-desktop/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/claude-desktop/" ~/.config/Claude/` |
| **Frequency** | Weekly or after MCP config changes |
| **Size estimate** | 10-50 MB |

### Beeper Data
| | |
|-|-|
| **What it contains** | Message history across all bridges (WhatsApp, Telegram, Signal, etc.), account configuration, bridge auth tokens. Beeper stores messages locally; losing this means losing message search and history. |
| **Where it lives** | `~/.config/Beeper/` and `~/.local/share/Beeper/` |
| **How to backup** | `rsync -a ~/.config/Beeper/ "$BACKUP_DIR/beeper-config/" && rsync -a ~/.local/share/Beeper/ "$BACKUP_DIR/beeper-data/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/beeper-config/" ~/.config/Beeper/ && rsync -a "$BACKUP_DIR/beeper-data/" ~/.local/share/Beeper/` |
| **Frequency** | Daily (messages accumulate constantly) |
| **Size estimate** | 200 MB - 1 GB |

### Installed AUR Packages List
| | |
|-|-|
| **What it contains** | List of manually installed AUR and pacman packages. Recreating this by memory on a fresh install is tedious and error-prone. |
| **Where it lives** | Generated on demand (not a file) |
| **How to backup** | `pacman -Qqe > "$BACKUP_DIR/pacman-packages.txt" && pacman -Qqm > "$BACKUP_DIR/aur-packages.txt"` |
| **How to restore** | Reinstall from lists: `pacman -S --needed - < "$BACKUP_DIR/pacman-packages.txt"` (AUR packages need `yay` or `paru`) |
| **Frequency** | Weekly or after installing/removing packages |
| **Size estimate** | < 10 KB |

---

## Nice to Have (convenience)

### Chrome Extension Individual Configs
| | |
|-|-|
| **What it contains** | Per-extension settings (uBlock Origin filter lists, Dark Reader site-specific settings, etc.). These live inside the Chrome profile but are hard to extract individually. Backing up the full Chrome profile (above) covers this. |
| **Where it lives** | `~/.config/google-chrome-canary/Default/Extensions/` and `~/.config/google-chrome-canary/Default/Local Extension Settings/` |
| **How to backup** | Covered by Chrome Canary profile backup above. For individual export, most extensions have their own export/import in settings. |
| **How to restore** | Restore Chrome profile, or re-import from extension UI. |
| **Frequency** | Covered by Chrome profile daily backup |
| **Size estimate** | 50-200 MB (part of Chrome profile) |

### Warp Terminal Config
| | |
|-|-|
| **What it contains** | Theme, keybindings, AI query history, workflows, custom agents. The Warp AI history is already archived in this repo at `warp-ai/`. |
| **Where it lives** | `~/.warp/` and `~/.config/warp-terminal/` |
| **How to backup** | `rsync -a ~/.warp/ "$BACKUP_DIR/warp/" 2>/dev/null; rsync -a ~/.config/warp-terminal/ "$BACKUP_DIR/warp-terminal/" 2>/dev/null` |
| **How to restore** | `rsync -a "$BACKUP_DIR/warp/" ~/.warp/; rsync -a "$BACKUP_DIR/warp-terminal/" ~/.config/warp-terminal/` |
| **Frequency** | Weekly |
| **Size estimate** | 10-50 MB |

### Ghostty Config
| | |
|-|-|
| **What it contains** | Terminal theme, font settings, keybindings, shell integration. The Omarchy-managed Ghostty config is already in this repo at `platform/linux/omarchy/terminals/ghostty.conf`. This backup catches any local overrides. |
| **Where it lives** | `~/.config/ghostty/` |
| **How to backup** | `rsync -a ~/.config/ghostty/ "$BACKUP_DIR/ghostty/"` |
| **How to restore** | `rsync -a "$BACKUP_DIR/ghostty/" ~/.config/ghostty/` |
| **Frequency** | On change |
| **Size estimate** | < 1 MB |

---

## What's Already Covered (no backup needed)

These are already tracked in the `claude-cross-machine-sync` git repo:

- Claude Code settings, hooks, skills, agents, commands (`universal/claude/`)
- Machine profiles and hardware specs (`machines/`)
- Omarchy/Hyprland configs (`platform/linux/omarchy/`)
- Chrome Canary flags (`machines/<hostname>/chrome-canary-flags.conf`)
- Electron/Wayland flags (`universal/electron/`)
- Learnings and session logs (`learnings/`, `docs/sessions/`)
- Memory files (`universal/claude/memory/`, `platform/linux/memory/`, `machines/<hostname>/memory/`)
- Episodic memory archives (`episodic-memory/`)

---

## Sample Backup Script

Save as `~/bin/claude-backup.sh` and make executable with `chmod +x ~/bin/claude-backup.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/backups/claude-ecosystem}"
KEEP_DAYS=7
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# ── Colors ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[backup]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Pre-flight ─────────────────────────────────────────────────
if ! command -v rsync &>/dev/null; then
    err "rsync is required but not installed"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
log "Backup target: $BACKUP_DIR"

# ── Backup function ───────────────────────────────────────────
backup_dir() {
    local label="$1"
    local src="$2"
    local dest="$BACKUP_DIR/$3"
    shift 3
    # remaining args are extra rsync flags (e.g., --exclude)

    if [ -d "$src" ]; then
        log "Backing up $label..."
        mkdir -p "$dest"
        rsync -a "$@" "$src/" "$dest/"
        local size
        size=$(du -sh "$dest" | cut -f1)
        log "  -> $dest ($size)"
    else
        warn "Skipping $label (not found: $src)"
    fi
}

backup_file() {
    local label="$1"
    local src="$2"
    local dest="$BACKUP_DIR/$3"

    if [ -f "$src" ]; then
        log "Backing up $label..."
        mkdir -p "$(dirname "$dest")"
        cp -a "$src" "$dest"
        log "  -> $dest"
    else
        warn "Skipping $label (not found: $src)"
    fi
}

# ── Critical ──────────────────────────────────────────────────
log ""
log "=== CRITICAL ==="

backup_dir "Cortex DB" \
    "$HOME/.claude-cortex" "claude-cortex"

backup_dir "Chrome Canary profile" \
    "$HOME/.config/google-chrome-canary" "chrome-canary" \
    --exclude='Cache' \
    --exclude='Code Cache' \
    --exclude='GPUCache' \
    --exclude='Service Worker/CacheStorage' \
    --exclude='ShaderCache'

backup_dir "Keyring" \
    "$HOME/.local/share/keyrings" "keyrings"

backup_dir "SSH keys" \
    "$HOME/.ssh" "ssh"

# ── Important ─────────────────────────────────────────────────
log ""
log "=== IMPORTANT ==="

backup_dir "Claude Desktop config" \
    "$HOME/.config/Claude" "claude-desktop"

backup_dir "Beeper config" \
    "$HOME/.config/Beeper" "beeper-config"

backup_dir "Beeper data" \
    "$HOME/.local/share/Beeper" "beeper-data"

if command -v pacman &>/dev/null; then
    log "Backing up package lists..."
    mkdir -p "$BACKUP_DIR/packages"
    pacman -Qqe > "$BACKUP_DIR/packages/pacman-explicit.txt"
    pacman -Qqm > "$BACKUP_DIR/packages/aur-packages.txt" 2>/dev/null || true
    log "  -> $BACKUP_DIR/packages/"
fi

# ── Nice to Have ──────────────────────────────────────────────
log ""
log "=== NICE TO HAVE ==="

backup_dir "Warp config" \
    "$HOME/.warp" "warp" 2>/dev/null || true

backup_dir "Warp Terminal config" \
    "$HOME/.config/warp-terminal" "warp-terminal" 2>/dev/null || true

backup_dir "Ghostty config" \
    "$HOME/.config/ghostty" "ghostty" 2>/dev/null || true

# ── Rotation ──────────────────────────────────────────────────
log ""
log "=== CLEANUP ==="

# Keep only the last KEEP_DAYS daily backups
# Each backup dir is named YYYY-MM-DD_HHMMSS
backup_count=$(find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d | wc -l)

if [ "$backup_count" -gt "$KEEP_DAYS" ]; then
    remove_count=$((backup_count - KEEP_DAYS))
    log "Removing $remove_count old backup(s) (keeping $KEEP_DAYS)..."

    find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d \
        | sort \
        | head -n "$remove_count" \
        | while read -r old_backup; do
            log "  Removing $(basename "$old_backup")"
            rm -rf "$old_backup"
        done
else
    log "No old backups to remove ($backup_count of $KEEP_DAYS max)"
fi

# ── Summary ───────────────────────────────────────────────────
log ""
total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Backup complete: $BACKUP_DIR ($total_size)"
log "Backups on disk: $(find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d | wc -l) of $KEEP_DAYS max"
```

### Usage

```bash
# Run manually
~/bin/claude-backup.sh

# Custom backup location
BACKUP_ROOT=/mnt/external/backups ~/bin/claude-backup.sh

# Automate with cron (daily at 2 AM)
# crontab -e
0 2 * * * /home/robthepirate/bin/claude-backup.sh >> /home/robthepirate/.local/share/claude-backup.log 2>&1

# Automate with systemd timer
# See platform/linux/systemd/ for timer unit examples
```

### Restore

```bash
# List available backups
ls ~/backups/claude-ecosystem/

# Restore a specific backup (example: Cortex DB)
rsync -a ~/backups/claude-ecosystem/2026-03-18_020000/claude-cortex/ ~/.claude-cortex/

# Restore everything (close all apps first)
rsync -a ~/backups/claude-ecosystem/2026-03-18_020000/chrome-canary/ ~/.config/google-chrome-canary/
rsync -a ~/backups/claude-ecosystem/2026-03-18_020000/keyrings/ ~/.local/share/keyrings/
rsync -a ~/backups/claude-ecosystem/2026-03-18_020000/ssh/ ~/.ssh/
# ... fix permissions after restore
chmod 700 ~/.ssh ~/.local/share/keyrings
chmod 600 ~/.ssh/id_* ~/.local/share/keyrings/*
```
