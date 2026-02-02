#!/bin/bash
# Unit tests for lib/rollback.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Use temp directory for snapshots
export SNAPSHOT_DIR="/tmp/test-machine-sync-snapshots"
rm -rf "$SNAPSHOT_DIR"
mkdir -p "$SNAPSHOT_DIR"

# Source the module under test
source "$REPO_DIR/lib/rollback.sh"

# Test counter
PASSED=0
FAILED=0

# Cleanup on exit
cleanup() {
    rm -rf "$SNAPSHOT_DIR"
}
trap cleanup EXIT

# Test helper
assert_true() {
    local condition="$1"
    local test_name="$2"

    if eval "$condition"; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        FAILED=$((FAILED + 1))
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [ -f "$file" ]; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name (file not found: $file)"
        FAILED=$((FAILED + 1))
    fi
}

assert_dir_exists() {
    local dir="$1"
    local test_name="$2"

    if [ -d "$dir" ]; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name (dir not found: $dir)"
        FAILED=$((FAILED + 1))
    fi
}

echo "Testing: create_snapshot()"

# Create a snapshot
create_snapshot "test" "/tmp" >/dev/null

assert_true '[ -n "$CURRENT_SNAPSHOT" ]' "sets CURRENT_SNAPSHOT variable"
assert_dir_exists "$CURRENT_SNAPSHOT_PATH" "creates snapshot directory"
assert_file_exists "$CURRENT_SNAPSHOT_PATH/manifest.json" "creates manifest.json"

# Check manifest content
manifest_content=$(cat "$CURRENT_SNAPSHOT_PATH/manifest.json")
assert_true 'echo "$manifest_content" | jq -e .snapshot_id' "manifest has snapshot_id"
assert_true 'echo "$manifest_content" | jq -e .operation' "manifest has operation"
assert_true 'echo "$manifest_content" | jq -e ".status == \"pending\""' "manifest status is pending"

echo ""
echo "Testing: commit_snapshot()"

commit_snapshot >/dev/null
manifest_content=$(cat "$SNAPSHOT_DIR/$CURRENT_SNAPSHOT/manifest.json" 2>/dev/null || echo '{}')
# Note: CURRENT_SNAPSHOT is cleared after commit, so we use the dir listing

# Check that at least one snapshot exists with committed status
has_committed=$(find "$SNAPSHOT_DIR" -name "manifest.json" -exec grep -l '"committed"' {} \; | head -1)
assert_true '[ -n "$has_committed" ]' "snapshot status updated to committed"

echo ""
echo "Testing: list_snapshots()"

# Create another snapshot for listing
create_snapshot "list-test" "/tmp" >/dev/null
commit_snapshot >/dev/null

output=$(list_snapshots 2>&1)
assert_true 'echo "$output" | grep -q "list-test"' "lists snapshot operations"

echo ""
echo "Summary: $PASSED passed, $FAILED failed"

# Exit with failure if any tests failed
[ $FAILED -eq 0 ]
