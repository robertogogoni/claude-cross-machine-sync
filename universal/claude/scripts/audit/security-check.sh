#!/bin/bash
#
# security-check.sh - Scan Claude Code configuration files for security issues
#
# Flexible security approach: Focus on exposed secrets, suggest (don't enforce) permissions
# Exit codes: 0=clean, 1=warnings, 2=critical issues found
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CRITICAL=0
WARNINGS=0

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Security Audit${NC}"
echo -e "${BLUE}  Approach: Flexible (focus on secrets, not restrictions)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Pattern definitions for secret detection
SECRET_PATTERNS=(
    "apiKey"
    "api_key"
    "API_KEY"
    "token"
    "TOKEN"
    "password"
    "PASSWORD"
    "secret"
    "SECRET"
    "credential"
    "CREDENTIAL"
    "private_key"
    "PRIVATE_KEY"
)

# Files to scan
SCAN_PATHS=(
    "$HOME/.claude/settings.json"
    "$HOME/.claude/settings.local.json"
    "$HOME/.config/Claude/claude_desktop_config.json"
    "$HOME/.claude/machines/*.json"
    "$HOME/.claude/memory/*.md"
    "$HOME/.claude.json"
)

echo -e "${BLUE}[1/4] Scanning for exposed secrets...${NC}"
echo ""

for path_pattern in "${SCAN_PATHS[@]}"; do
    # Expand glob patterns
    shopt -s nullglob
    for file in $path_pattern; do
        if [ -f "$file" ]; then
            # Check each secret pattern
            for pattern in "${SECRET_PATTERNS[@]}"; do
                # Search for pattern followed by value (not just the key name)
                matches=$(grep -n "\"$pattern\".*:" "$file" 2>/dev/null || true)

                if [ -n "$matches" ]; then
                    # Check if value looks like an actual secret (not empty, not placeholder)
                    actual_secrets=$(echo "$matches" | grep -v '""' | grep -v '"YOUR_' | grep -v '"<' | grep -v 'null' || true)

                    if [ -n "$actual_secrets" ]; then
                        echo -e "${RED}🔴 CRITICAL: Potential secret found in${NC} $file"
                        echo "$actual_secrets" | while read -r line; do
                            echo -e "   ${YELLOW}└─${NC} $line"
                        done
                        echo ""
                        ((CRITICAL++))
                    fi
                fi
            done
        fi
    done
done

if [ $CRITICAL -eq 0 ]; then
    echo -e "${GREEN}✓ No exposed secrets detected${NC}"
    echo ""
fi

echo -e "${BLUE}[2/4] Checking file permissions (suggestions, not enforcement)...${NC}"
echo ""

# Check .env file if it exists
if [ -f "$HOME/.claude/.env" ]; then
    perm=$(stat -c "%a" "$HOME/.claude/.env" 2>/dev/null || stat -f "%A" "$HOME/.claude/.env" 2>/dev/null || echo "unknown")
    if [ "$perm" != "600" ]; then
        echo -e "${YELLOW}⚠️  WARNING: .env file has permissions $perm (recommend 600)${NC}"
        echo -e "   ${YELLOW}└─${NC} Suggested: chmod 600 ~/.claude/.env"
        echo ""
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ .env file has secure permissions (600)${NC}"
        echo ""
    fi
fi

# Check sensitive config files
SENSITIVE_FILES=(
    "$HOME/.claude/settings.local.json"
    "$HOME/.config/Claude/claude_desktop_config.json"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        perm=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null || echo "unknown")
        # Note: We suggest 600 for files with secrets, but don't fail
        if [ "$perm" = "644" ] || [ "$perm" = "600" ]; then
            echo -e "${GREEN}✓${NC} $file permissions: $perm (acceptable)"
        else
            echo -e "${YELLOW}⚠️  Note:${NC} $file has permissions $perm"
            echo -e "   ${YELLOW}└─${NC} Suggestion: Use 600 for files with secrets, 644 for others"
            echo ""
        fi
    fi
done

echo ""
echo -e "${BLUE}[3/4] Scanning logs for accidentally leaked secrets...${NC}"
echo ""

# Check bash commands log
if [ -f "$HOME/.claude/logs/bash-commands.log" ]; then
    log_secrets=0
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$HOME/.claude/logs/bash-commands.log" 2>/dev/null; then
            ((log_secrets++))
        fi
    done

    if [ $log_secrets -gt 0 ]; then
        echo -e "${YELLOW}⚠️  WARNING: Potential secrets detected in bash-commands.log${NC}"
        echo -e "   ${YELLOW}└─${NC} Review: ~/.claude/logs/bash-commands.log"
        echo -e "   ${YELLOW}└─${NC} Consider: Rotate any exposed credentials"
        echo ""
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ No secrets detected in bash command logs${NC}"
        echo ""
    fi
else
    echo -e "${BLUE}ℹ  bash-commands.log not found (no commands logged yet)${NC}"
    echo ""
fi

# Check debug logs
debug_count=$(find "$HOME/.claude/debug/" -name "*.txt" 2>/dev/null | wc -l || echo 0)
if [ $debug_count -gt 0 ]; then
    echo -e "${BLUE}ℹ  Found $debug_count debug log files${NC}"
    echo -e "   ${BLUE}└─${NC} Suggestion: Manually review if debugging sensitive operations"
    echo ""
fi

echo -e "${BLUE}[4/4] Additional security checks...${NC}"
echo ""

# Check if .env is in .gitignore (if using git)
if [ -d "$HOME/.claude/.git" ]; then
    if [ -f "$HOME/.claude/.gitignore" ]; then
        if grep -q "^\.env$" "$HOME/.claude/.gitignore" 2>/dev/null; then
            echo -e "${GREEN}✓ .env is in .gitignore${NC}"
        else
            echo -e "${YELLOW}⚠️  WARNING: .env not found in .gitignore${NC}"
            echo -e "   ${YELLOW}└─${NC} Add to .gitignore to prevent accidental commits"
            echo ""
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠️  No .gitignore found in .claude directory${NC}"
        ((WARNINGS++))
    fi
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Security Audit Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All security checks passed!${NC}"
    echo ""
    exit 0
elif [ $CRITICAL -gt 0 ]; then
    echo -e "${RED}🔴 CRITICAL: $CRITICAL critical issue(s) found${NC}"
    echo -e "${YELLOW}⚠️  WARNING: $WARNINGS warning(s)${NC}"
    echo ""
    echo "Action required: Address critical issues immediately"
    echo ""
    exit 2
else
    echo -e "${GREEN}✓ No critical issues${NC}"
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) - review recommended${NC}"
    echo ""
    exit 1
fi
