#!/bin/bash
# Unit tests for lib/validator.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the module under test
source "$REPO_DIR/lib/validator.sh"

# Test counter
PASSED=0
FAILED=0

# Test helper
assert_eq() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" = "$actual" ]; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        FAILED=$((FAILED + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if echo "$haystack" | grep -qF "$needle"; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        echo "    '$needle' not found in '$haystack'"
        FAILED=$((FAILED + 1))
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if ! echo "$haystack" | grep -qF "$needle"; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        echo "    '$needle' should not be in '$haystack'"
        FAILED=$((FAILED + 1))
    fi
}

echo "Testing: sanitize_path()"

# Test: removes path traversal
result=$(sanitize_path "../../etc/passwd")
assert_not_contains "$result" ".." "removes path traversal (..)"
assert_not_contains "$result" "/" "removes forward slashes"

# Test: removes backslashes
result=$(sanitize_path "..\\..\\windows\\system32")
assert_not_contains "$result" "\\" "removes backslashes"

# Test: preserves valid characters
result=$(sanitize_path "my-machine-name")
assert_eq "my-machine-name" "$result" "preserves valid machine name"

# Test: converts spaces to dashes
result=$(sanitize_path "my machine name")
assert_not_contains "$result" " " "removes spaces"

# Test: handles empty input
result=$(sanitize_path "")
assert_eq "" "$result" "handles empty input"

# Test: removes leading dashes
result=$(sanitize_path "-bad-name")
assert_not_contains "${result:0:1}" "-" "removes leading dash"

# Test: preserves underscores
result=$(sanitize_path "my_machine_name")
assert_eq "my_machine_name" "$result" "preserves underscores"

# Test: preserves dots
result=$(sanitize_path "machine.local")
assert_eq "machine.local" "$result" "preserves dots"

echo ""
echo "Testing: version_gte()"

# Test: equal versions
version_gte "2.30.0" "2.30.0"
assert_eq "0" "$?" "2.30.0 >= 2.30.0"

# Test: greater major
version_gte "3.0.0" "2.30.0"
assert_eq "0" "$?" "3.0.0 >= 2.30.0"

# Test: greater minor
version_gte "2.31.0" "2.30.0"
assert_eq "0" "$?" "2.31.0 >= 2.30.0"

# Test: greater patch
version_gte "2.30.1" "2.30.0"
assert_eq "0" "$?" "2.30.1 >= 2.30.0"

# Test: lesser version
version_gte "2.29.0" "2.30.0" || result=$?
assert_eq "1" "$result" "2.29.0 < 2.30.0"

echo ""
echo "Testing: validate_machine_name()"

# Test: valid name
result=$(validate_machine_name "my-laptop" 2>&1)
assert_contains "$result" "Valid" "accepts valid name"

# Test: sanitizes bad characters
result=$(validate_machine_name "my/laptop" 2>&1)
assert_contains "$result" "sanitized" "sanitizes invalid characters"

echo ""
echo "Summary: $PASSED passed, $FAILED failed"

# Exit with failure if any tests failed
[ $FAILED -eq 0 ]
