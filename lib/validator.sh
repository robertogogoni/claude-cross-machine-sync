#!/bin/bash
# Pre-flight Validation System for Machine Sync
# Catches failures BEFORE they happen, not after
#
# Usage:
#   source lib/validator.sh
#   validate_preflight [--skip-network] [--skip-git-auth]
#
# Exit Codes:
#   0 - All checks passed
#   1 - Critical failure (cannot proceed)
#   2 - Warning only (can proceed with caution)

set -e

# Minimum versions
MIN_GIT_VERSION="2.30.0"
MIN_BASH_VERSION="4.0"

# Colors (inherit from parent or define)
: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

# Validation result tracking
declare -a VALIDATION_ERRORS=()
declare -a VALIDATION_WARNINGS=()

#######################################
# Log validation result
# Arguments:
#   $1 - Check name
#   $2 - Status (PASS|FAIL|WARN|SKIP)
#   $3 - Message
#######################################
log_check() {
    local name="$1"
    local status="$2"
    local message="$3"

    case "$status" in
        PASS)
            echo -e "  ${GREEN}✓${NC} $name: $message"
            ;;
        FAIL)
            echo -e "  ${RED}✗${NC} $name: $message"
            VALIDATION_ERRORS+=("$name: $message")
            ;;
        WARN)
            echo -e "  ${YELLOW}!${NC} $name: $message"
            VALIDATION_WARNINGS+=("$name: $message")
            ;;
        SKIP)
            echo -e "  ${CYAN}-${NC} $name: $message (skipped)"
            ;;
    esac
}

#######################################
# Compare semantic versions
# Arguments:
#   $1 - Version A
#   $2 - Version B
# Returns:
#   0 if A >= B, 1 if A < B
#######################################
version_gte() {
    local v1="$1"
    local v2="$2"

    # Extract major.minor.patch
    local v1_parts v2_parts
    IFS='.' read -ra v1_parts <<< "${v1%%[^0-9.]*}"
    IFS='.' read -ra v2_parts <<< "${v2%%[^0-9.]*}"

    for i in 0 1 2; do
        local a="${v1_parts[$i]:-0}"
        local b="${v2_parts[$i]:-0}"
        if (( a > b )); then return 0; fi
        if (( a < b )); then return 1; fi
    done
    return 0
}

#######################################
# Check: Bash version
#######################################
check_bash_version() {
    local current="${BASH_VERSION%%(*}"

    if version_gte "$current" "$MIN_BASH_VERSION"; then
        log_check "Bash version" "PASS" "v$current (≥$MIN_BASH_VERSION)"
    else
        log_check "Bash version" "FAIL" "v$current (need ≥$MIN_BASH_VERSION)"
    fi
}

#######################################
# Check: Git installation and version
#######################################
check_git() {
    if ! command -v git &>/dev/null; then
        log_check "Git" "FAIL" "Not installed. Install: sudo pacman -S git"
        return
    fi

    local version
    version=$(git --version | grep -oP '\d+\.\d+\.\d+' | head -1)

    if version_gte "$version" "$MIN_GIT_VERSION"; then
        log_check "Git version" "PASS" "v$version (≥$MIN_GIT_VERSION)"
    else
        log_check "Git version" "WARN" "v$version (recommend ≥$MIN_GIT_VERSION)"
    fi
}

#######################################
# Check: inotify-tools (Linux file watching)
#######################################
check_inotify() {
    if [[ "$OSTYPE" != linux* ]]; then
        log_check "inotify-tools" "SKIP" "Not Linux"
        return
    fi

    if command -v inotifywait &>/dev/null; then
        log_check "inotify-tools" "PASS" "Installed"
    else
        log_check "inotify-tools" "FAIL" "Not installed. Install: sudo pacman -S inotify-tools"
    fi
}

#######################################
# Check: fswatch (macOS file watching)
#######################################
check_fswatch() {
    if [[ "$OSTYPE" != darwin* ]]; then
        log_check "fswatch" "SKIP" "Not macOS"
        return
    fi

    if command -v fswatch &>/dev/null; then
        log_check "fswatch" "PASS" "Installed"
    else
        log_check "fswatch" "FAIL" "Not installed. Install: brew install fswatch"
    fi
}

#######################################
# Check: Git authentication
# Arguments:
#   $1 - Repository path
#######################################
check_git_auth() {
    local repo_path="${1:-.}"
    local skip_auth="${SKIP_GIT_AUTH:-false}"

    if [[ "$skip_auth" == "true" ]]; then
        log_check "Git auth" "SKIP" "Skipped by flag"
        return
    fi

    # Get remote URL
    local remote_url
    remote_url=$(git -C "$repo_path" remote get-url origin 2>/dev/null || echo "")

    if [[ -z "$remote_url" ]]; then
        log_check "Git auth" "WARN" "No remote configured"
        return
    fi

    # Test authentication with ls-remote (timeout after 10s)
    if timeout 10 git -C "$repo_path" ls-remote --exit-code origin &>/dev/null; then
        log_check "Git auth" "PASS" "Can access remote"
    else
        if [[ "$remote_url" == git@* ]]; then
            log_check "Git auth" "FAIL" "SSH key not configured or not added to agent"
        else
            log_check "Git auth" "FAIL" "Authentication failed. Configure PAT or SSH key"
        fi
    fi
}

#######################################
# Check: Network connectivity
# Arguments:
#   $1 - Host to check (default: github.com)
#######################################
check_network() {
    local host="${1:-github.com}"
    local skip_network="${SKIP_NETWORK:-false}"

    if [[ "$skip_network" == "true" ]]; then
        log_check "Network" "SKIP" "Skipped by flag"
        return
    fi

    # Try TCP connection to port 443
    if timeout 5 bash -c "echo >/dev/tcp/$host/443" 2>/dev/null; then
        log_check "Network" "PASS" "Can reach $host"
    else
        # Fallback: try curl
        if command -v curl &>/dev/null && curl -sf --max-time 5 "https://$host" &>/dev/null; then
            log_check "Network" "PASS" "Can reach $host"
        else
            log_check "Network" "WARN" "Cannot reach $host (offline mode will be enabled)"
        fi
    fi
}

#######################################
# Check: Disk space
# Arguments:
#   $1 - Path to check
#   $2 - Minimum MB required (default: 100)
#######################################
check_disk_space() {
    local path="${1:-.}"
    local min_mb="${2:-100}"

    # Get available space in MB
    local available_mb
    available_mb=$(df -m "$path" 2>/dev/null | awk 'NR==2 {print $4}')

    if [[ -z "$available_mb" ]]; then
        log_check "Disk space" "WARN" "Could not determine available space"
        return
    fi

    if (( available_mb >= min_mb )); then
        log_check "Disk space" "PASS" "${available_mb}MB available (need ≥${min_mb}MB)"
    else
        log_check "Disk space" "FAIL" "Only ${available_mb}MB available (need ≥${min_mb}MB)"
    fi
}

#######################################
# Check: Write permissions
# Arguments:
#   $1 - Path to check
#######################################
check_permissions() {
    local path="$1"

    if [[ ! -e "$path" ]]; then
        # Check parent directory
        local parent
        parent=$(dirname "$path")
        if [[ -w "$parent" ]]; then
            log_check "Permissions ($path)" "PASS" "Parent directory writable"
        else
            log_check "Permissions ($path)" "FAIL" "Cannot write to $parent"
        fi
    elif [[ -w "$path" ]]; then
        log_check "Permissions ($path)" "PASS" "Writable"
    else
        log_check "Permissions ($path)" "FAIL" "Not writable. Try: chmod u+w $path"
    fi
}

#######################################
# Check: Valid git repository
# Arguments:
#   $1 - Repository path
#######################################
check_repository() {
    local repo_path="${1:-.}"

    if [[ ! -d "$repo_path/.git" ]]; then
        log_check "Repository" "FAIL" "Not a git repository: $repo_path"
        return
    fi

    # Check for detached HEAD
    local branch
    branch=$(git -C "$repo_path" symbolic-ref --short HEAD 2>/dev/null || echo "")

    if [[ -z "$branch" ]]; then
        log_check "Repository" "WARN" "Detached HEAD state (not on a branch)"
    else
        log_check "Repository" "PASS" "Valid repo on branch: $branch"
    fi

    # Check for uncommitted changes
    if git -C "$repo_path" diff --quiet && git -C "$repo_path" diff --cached --quiet; then
        log_check "Working tree" "PASS" "Clean"
    else
        log_check "Working tree" "WARN" "Has uncommitted changes"
    fi
}

#######################################
# Check: Stale lock files
# Arguments:
#   $1 - Lock file path
#######################################
check_lock_file() {
    local lock_file="$1"

    if [[ ! -f "$lock_file" ]]; then
        log_check "Lock file" "PASS" "No stale lock"
        return
    fi

    local pid
    pid=$(cat "$lock_file" 2>/dev/null)

    if [[ -z "$pid" ]]; then
        log_check "Lock file" "WARN" "Empty lock file, cleaning up"
        rm -f "$lock_file"
        return
    fi

    if kill -0 "$pid" 2>/dev/null; then
        log_check "Lock file" "WARN" "Process $pid is running (daemon may be active)"
    else
        log_check "Lock file" "PASS" "Stale lock (process $pid dead), cleaning up"
        rm -f "$lock_file"
    fi
}

#######################################
# Sanitize user input for safe path usage
# Arguments:
#   $1 - Input string
# Outputs:
#   Sanitized string (alphanumeric, dash, underscore only)
#######################################
sanitize_path() {
    local input="$1"
    # Remove path traversal attempts and unsafe characters
    # 1. Remove path separators
    # 2. Remove null bytes
    # 3. Replace .. sequences (path traversal)
    # 4. Keep only alphanumeric, dash, underscore, and single dots
    # 5. Remove leading/trailing dashes
    echo "$input" \
        | tr -d '/' \
        | tr -d '\\' \
        | tr -d '\0' \
        | sed 's/\.\.//g' \
        | tr -c '[:alnum:]-_.' '-' \
        | sed 's/^-//' \
        | sed 's/-$//'
}

#######################################
# Validate machine name
# Arguments:
#   $1 - Machine name
#######################################
validate_machine_name() {
    local name="$1"
    local sanitized
    sanitized=$(sanitize_path "$name")

    if [[ -z "$sanitized" ]]; then
        log_check "Machine name" "FAIL" "Name cannot be empty"
        return 1
    fi

    if [[ "$sanitized" != "$name" ]]; then
        log_check "Machine name" "WARN" "Name sanitized: '$name' -> '$sanitized'"
    else
        log_check "Machine name" "PASS" "Valid: $name"
    fi

    echo "$sanitized"
}

#######################################
# Run all pre-flight checks
# Arguments:
#   $1 - Repository path (optional)
# Environment:
#   SKIP_NETWORK - Skip network check
#   SKIP_GIT_AUTH - Skip git auth check
# Returns:
#   0 - All critical checks passed
#   1 - Critical failure
#   2 - Warnings only
#######################################
validate_preflight() {
    local repo_path="${1:-.}"
    local lock_file="${2:-$HOME/.local/state/machine-sync/daemon.lock}"

    echo -e "\n${CYAN}Pre-flight Validation${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Reset tracking arrays
    VALIDATION_ERRORS=()
    VALIDATION_WARNINGS=()

    # Run checks
    check_bash_version
    check_git
    check_inotify
    check_fswatch
    check_network
    check_disk_space "$repo_path" 100

    if [[ -d "$repo_path/.git" ]]; then
        check_repository "$repo_path"
        check_git_auth "$repo_path"
    fi

    check_permissions "$repo_path"
    check_permissions "$HOME/.claude"
    check_lock_file "$lock_file"

    # Summary
    echo ""
    local error_count=${#VALIDATION_ERRORS[@]}
    local warn_count=${#VALIDATION_WARNINGS[@]}

    if (( error_count > 0 )); then
        echo -e "${RED}✗ Pre-flight failed: $error_count error(s), $warn_count warning(s)${NC}"
        echo ""
        echo "Errors:"
        for err in "${VALIDATION_ERRORS[@]}"; do
            echo -e "  ${RED}•${NC} $err"
        done
        return 1
    elif (( warn_count > 0 )); then
        echo -e "${YELLOW}! Pre-flight passed with $warn_count warning(s)${NC}"
        return 2
    else
        echo -e "${GREEN}✓ Pre-flight passed: All checks OK${NC}"
        return 0
    fi
}

#######################################
# Quick validation (minimal checks)
# Arguments:
#   $1 - Repository path
#######################################
validate_quick() {
    local repo_path="${1:-.}"

    # Only critical checks
    command -v git &>/dev/null || { echo "ERROR: git not installed"; return 1; }
    [[ -d "$repo_path/.git" ]] || { echo "ERROR: Not a git repository"; return 1; }

    return 0
}

# Export functions
export -f sanitize_path
export -f validate_machine_name
export -f validate_preflight
export -f validate_quick
