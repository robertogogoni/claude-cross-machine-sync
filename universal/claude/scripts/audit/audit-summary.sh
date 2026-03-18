#!/bin/bash
#
# audit-summary.sh - Run comprehensive audit and generate summary report
#
# Executes all audit scripts and combines results into a single report
# Exit codes: 0=all clean, 1=warnings, 2=critical issues
#

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

AUDIT_DIR="$HOME/.claude/scripts/audit"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE="$HOME/.claude/audit-report-$TIMESTAMP.txt"

# Header
{
  echo "════════════════════════════════════════════════════════════════"
  echo "  CLAUDE CODE COMPREHENSIVE AUDIT REPORT"
  echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  Machine: $(hostname)"
  echo "  User: $USER"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
} | tee "$REPORT_FILE"

# Track overall status
CRITICAL=0
WARNINGS=0
CLEAN=0

echo -e "${CYAN}Running comprehensive audit...${NC}"
echo ""

# 1. Security Check
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[1/2] Security Audit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -x "$AUDIT_DIR/security-check.sh" ]; then
  "$AUDIT_DIR/security-check.sh" 2>&1 | tee -a "$REPORT_FILE"
  SECURITY_EXIT=$?

  if [ $SECURITY_EXIT -eq 2 ]; then
    ((CRITICAL++))
  elif [ $SECURITY_EXIT -eq 1 ]; then
    ((WARNINGS++))
  else
    ((CLEAN++))
  fi
else
  echo -e "${YELLOW}⚠  security-check.sh not found${NC}" | tee -a "$REPORT_FILE"
  ((WARNINGS++))
fi

echo "" | tee -a "$REPORT_FILE"

# 2. Configuration Validation
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2/2] Configuration Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -x "$AUDIT_DIR/validate-configs.sh" ]; then
  "$AUDIT_DIR/validate-configs.sh" 2>&1 | tee -a "$REPORT_FILE"
  CONFIG_EXIT=$?

  if [ $CONFIG_EXIT -eq 2 ]; then
    ((CRITICAL++))
  elif [ $CONFIG_EXIT -eq 1 ]; then
    ((WARNINGS++))
  else
    ((CLEAN++))
  fi
else
  echo -e "${YELLOW}⚠  validate-configs.sh not found${NC}" | tee -a "$REPORT_FILE"
  ((WARNINGS++))
fi

echo "" | tee -a "$REPORT_FILE"

# System Information
{
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "System Information"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "OS: $(uname -s) $(uname -r)"
  echo "Hostname: $(hostname)"
  echo "Claude Config: $HOME/.claude/"
  echo "Active Machine Profile: $(readlink -f $HOME/.claude/machines/current.json 2>/dev/null | xargs basename 2>/dev/null || echo 'Not set')"
  echo ""
  echo "Directory Statistics:"
  echo "  Commands: $(ls $HOME/.claude/commands/ 2>/dev/null | wc -l)"
  echo "  Agents: $(ls $HOME/.claude/agents/ 2>/dev/null | wc -l)"
  echo "  Skills: $(ls $HOME/.claude/skills/ 2>/dev/null | wc -l)"
  echo "  Debug logs: $(ls $HOME/.claude/debug/ 2>/dev/null | wc -l)"
  echo ""
} | tee -a "$REPORT_FILE"

# Final Summary
{
  echo "════════════════════════════════════════════════════════════════"
  echo "  AUDIT SUMMARY"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
} | tee -a "$REPORT_FILE"

if [ $CRITICAL -gt 0 ]; then
  echo -e "${RED}🔴 CRITICAL ISSUES FOUND${NC}" | tee -a "$REPORT_FILE"
  echo "   $CRITICAL audit(s) reported critical issues" | tee -a "$REPORT_FILE"
  echo "   Action required immediately" | tee -a "$REPORT_FILE"
  EXIT_CODE=2
elif [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}⚠️  WARNINGS DETECTED${NC}" | tee -a "$REPORT_FILE"
  echo "   $WARNINGS audit(s) reported warnings" | tee -a "$REPORT_FILE"
  echo "   Review recommended" | tee -a "$REPORT_FILE"
  EXIT_CODE=1
else
  echo -e "${GREEN}✓ ALL AUDITS PASSED${NC}" | tee -a "$REPORT_FILE"
  echo "   $CLEAN audit(s) completed successfully" | tee -a "$REPORT_FILE"
  echo "   No issues detected" | tee -a "$REPORT_FILE"
  EXIT_CODE=0
fi

echo "" | tee -a "$REPORT_FILE"
echo "Full report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo ""

exit $EXIT_CODE
