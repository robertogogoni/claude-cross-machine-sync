#!/bin/bash
# Test Runner for Machine Sync
# Runs all unit and integration tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Run a test file
# Arguments:
#   $1 - Test file path
#######################################
run_test() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)

    echo -e "\n${CYAN}Running: $test_name${NC}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if bash "$test_file"; then
        echo -e "${GREEN}  ✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}  ✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            Machine Sync Test Suite                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Source the lib modules for testing
source "$REPO_DIR/lib/validator.sh" 2>/dev/null || true
source "$REPO_DIR/lib/rollback.sh" 2>/dev/null || true

# Run unit tests
echo -e "\n${YELLOW}=== Unit Tests ===${NC}"

for test_file in "$SCRIPT_DIR"/unit/test_*.sh; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

# Run integration tests (if not in CI quick mode)
if [ "$CI_QUICK" != "true" ]; then
    echo -e "\n${YELLOW}=== Integration Tests ===${NC}"

    for test_file in "$SCRIPT_DIR"/integration/test_*.sh; do
        if [ -f "$test_file" ]; then
            run_test "$test_file"
        fi
    done
fi

# Summary
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}FAILED${NC}"
    exit 1
else
    echo -e "\n${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
