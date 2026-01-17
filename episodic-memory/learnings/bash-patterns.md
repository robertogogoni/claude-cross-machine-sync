# Bash Scripting Patterns

Reusable patterns and anti-patterns learned from real projects.

---

## Directory Safety

### The Subshell Pattern
**Problem:** `cd` inside functions changes the working directory for the entire script.

```bash
# ❌ BAD - Directory leak
cleanup_old_files() {
    cd "$BACKUP_DIR"
    ls -t | tail -n +4 | xargs -r rm -rf
}
# After calling this, you're in $BACKUP_DIR!

# ✅ GOOD - Isolated in subshell
cleanup_old_files() {
    (cd "$BACKUP_DIR" && ls -t | tail -n +4 | xargs -r sudo rm -rf)
}
# Working directory unchanged after call
```

**When to use:** Any time you need `cd` inside a function or loop.

---

## Error Handling

### The `|| true` Pattern
Prevent `set -e` from exiting on expected failures:

```bash
set -e

# This might fail, and that's OK
update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true

# Continue executing...
```

### Counting Error-Safe Operations
A well-written script should have `|| true` or `2>/dev/null` on:
- Desktop database updates
- Optional dependency checks
- Cleanup operations
- Notification sends

---

## Version Extraction

### From Redirect URLs
```bash
# Beeper uses redirect-based versioning
DOWNLOAD_URL=$(curl -Ls -o /dev/null -w "%{url_effective}" "$API_URL")
VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'AppName-\K[0-9]+\.[0-9]+\.[0-9]+')
```

### From JSON files
```bash
# Extract version from package.json
VERSION=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)

# Or with jq
VERSION=$(jq -r '.version' package.json)
```

---

## Self-Healing Pipelines

### Pattern: Verify → Retry → Rollback

```bash
MAX_RETRIES=2

do_operation() {
    local attempt=0
    while ((attempt < MAX_RETRIES)); do
        if perform_action && verify_success; then
            return 0
        fi
        ((attempt++))
        apply_targeted_fix  # Clean temp files, reset state, etc.
    done
    rollback_to_backup
    return 1
}
```

### Critical File Verification
After extracting archives, verify critical files exist:

```bash
CRITICAL_FILES=(
    "main_binary"
    "config/required.conf"
    "lib/important.so"
)

verify_extraction() {
    for file in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "$EXTRACT_DIR/$file" ]]; then
            echo "Missing: $file"
            return 1
        fi
    done
    return 0
}
```

---

## Desktop File Management

### XDG Override Strategy
User desktop files in `~/.local/share/applications/` take precedence over system files in `/usr/share/applications/`.

```bash
USER_DESKTOP_DIR="$HOME/.local/share/applications"

create_desktop_override() {
    local system_file="/usr/share/applications/app.desktop"
    local user_file="$USER_DESKTOP_DIR/app.desktop"

    mkdir -p "$USER_DESKTOP_DIR"
    cp "$system_file" "$user_file"

    # Modify Exec line
    sed -i "s|^Exec=app |Exec=app --custom-flag |" "$user_file"

    # Refresh database
    update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true
}
```

---

## Environment Detection

### Wayland vs X11
```bash
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    echo "Running on Wayland"
    DISPLAY_FLAGS="--ozone-platform=wayland"
elif [[ -n "$DISPLAY" ]]; then
    echo "Running on X11"
    DISPLAY_FLAGS=""
else
    echo "No display server detected"
fi
```

### Architecture Check
```bash
check_architecture() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]]; then
        echo "Error: x86_64 required, got $arch"
        return 1
    fi
}
```

### Distro Detection
```bash
check_distro() {
    if [[ -f /etc/arch-release ]]; then
        echo "Arch Linux detected"
    elif [[ -f /etc/debian_version ]]; then
        echo "Debian-based detected"
    else
        echo "Unknown distro"
    fi
}
```

---

## Backup Management

### Rolling Backups (Keep Last N)
```bash
BACKUP_DIR="/opt/app-backups"
KEEP_BACKUPS=3

cleanup_old_backups() {
    # Use subshell to avoid directory leak
    (cd "$BACKUP_DIR" && ls -t | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r sudo rm -rf)
}

create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    sudo cp -r "$INSTALL_DIR" "$BACKUP_DIR/backup_$timestamp"
    cleanup_old_backups
}
```

---

## Process Management

### Health Check with Timeout
```bash
verify_app_starts() {
    local pid timeout=10

    # Start app in background
    /opt/app/binary &
    pid=$!

    # Wait and check if still running
    sleep "$timeout"

    if kill -0 "$pid" 2>/dev/null; then
        echo "App running stable after ${timeout}s"
        kill "$pid" 2>/dev/null || true
        return 0
    else
        echo "App crashed within ${timeout}s"
        return 1
    fi
}
```

---

## Color Output

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo -e "${GREEN}✓ Success${NC}"
echo -e "${RED}✗ Error${NC}"
echo -e "${YELLOW}⚠ Warning${NC}"
echo -e "${BLUE}→ Info${NC}"
```

---

*Last updated: 2026-01-16*
