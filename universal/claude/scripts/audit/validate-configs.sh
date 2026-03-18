#!/bin/bash
#
# validate-configs.sh - Validate all Claude Code JSON configuration files
#
# Checks JSON syntax, schemas, and cross-references
# Exit codes: 0=all valid, 1=warnings, 2=errors found
#

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
VALID=0
INVALID=0
WARNINGS=0

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Configuration Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# JSON files to validate
JSON_FILES=(
  "$HOME/.claude/settings.json"
  "$HOME/.claude/settings.local.json"
  "$HOME/.claude.json"
  "$HOME/.config/Claude/claude_desktop_config.json"
  "$HOME/.claude/machines/omarchy-samsung.json"
  "$HOME/.claude/machines/macbook-air.json"
)

echo -e "${BLUE}[1/3] Validating JSON syntax...${NC}"
echo ""

for file in "${JSON_FILES[@]}"; do
  if [ -f "$file" ]; then
    if python3 -m json.tool "$file" > /dev/null 2>&1; then
      echo -e "${GREEN}✓${NC} Valid: $(basename $file)"
      ((VALID++))
    else
      echo -e "${RED}✗ INVALID:${NC} $(basename $file)"
      python3 -m json.tool "$file" 2>&1 | head -3 | sed 's/^/  /'
      echo ""
      ((INVALID++))
    fi
  else
    echo -e "${YELLOW}⚠${NC}  Not found: $(basename $file)"
    ((WARNINGS++))
  fi
done

echo ""
echo -e "${BLUE}[2/3] Checking file references...${NC}"
echo ""

# Check hook scripts exist
if [ -x "$HOME/.claude/machines/detect-machine.sh" ]; then
  echo -e "${GREEN}✓${NC} Hook script exists: detect-machine.sh"
else
  echo -e "${RED}✗${NC} Missing or not executable: detect-machine.sh"
  ((INVALID++))
fi

# Check MCP server executables
echo ""
echo "MCP Server Dependencies:"
which npx > /dev/null && echo -e "  ${GREEN}✓${NC} npx (Node.js)" || echo -e "  ${RED}✗${NC} npx NOT FOUND"
which uvx > /dev/null && echo -e "  ${GREEN}✓${NC} uvx (Python UV)" || echo -e "  ${YELLOW}⚠${NC}  uvx not found (git/sqlite/fetch MCP won't work)"
[ -f "$HOME/.local/share/mcp-servers/superpowers-chrome/mcp/dist/index.js" ] && echo -e "  ${GREEN}✓${NC} Chrome MCP script" || echo -e "  ${RED}✗${NC} Chrome MCP missing"

# Check symlinks
echo ""
echo "Symlinks:"
[ -L "$HOME/.claude/skills/omarchy" ] && [ -e "$HOME/.claude/skills/omarchy" ] && echo -e "  ${GREEN}✓${NC} omarchy skill symlink" || echo -e "  ${YELLOW}⚠${NC}  omarchy symlink broken"
[ -L "$HOME/.claude/machines/current.json" ] && [ -e "$HOME/.claude/machines/current.json" ] && echo -e "  ${GREEN}✓${NC} current.json machine profile" || echo -e "  ${YELLOW}⚠${NC}  current.json broken"

echo ""
echo -e "${BLUE}[3/3] Validating directory structure...${NC}"
echo ""

REQUIRED_DIRS=(
  "$HOME/.claude/commands"
  "$HOME/.claude/agents"
  "$HOME/.claude/skills"
  "$HOME/.claude/machines"
  "$HOME/.claude/memory"
  "$HOME/.claude/logs"
  "$HOME/.claude/scripts/audit"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    count=$(find "$dir" -maxdepth 1 -type f -o -type l 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} $(basename $dir)/ ($count items)"
  else
    echo -e "${YELLOW}⚠${NC}  Missing: $(basename $dir)/"
    ((WARNINGS++))
  fi
done

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Validation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

if [ $INVALID -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo -e "  Valid JSON files: $VALID"
  echo ""
  exit 0
elif [ $INVALID -gt 0 ]; then
  echo -e "${RED}✗ $INVALID error(s) found${NC}"
  [ $WARNINGS -gt 0 ] && echo -e "${YELLOW}⚠ $WARNINGS warning(s)${NC}"
  echo -e "  Valid JSON files: $VALID"
  echo ""
  exit 2
else
  echo -e "${GREEN}✓ No critical errors${NC}"
  echo -e "${YELLOW}⚠ $WARNINGS warning(s)${NC}"
  echo -e "  Valid JSON files: $VALID"
  echo ""
  exit 1
fi
