#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_EXT="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_HOME" "$TMP_EXT"
    rm -f "$REPO_DIR/skill-sources.json"
}
trap cleanup EXIT

# Create one valid external source
mkdir -p "$TMP_EXT/skill-alpha"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"

# Pre-create config with one valid and one missing directory
cat > "$REPO_DIR/skill-sources.json" <<EOF
{
  "sources": [
    {"name": "valid-source", "path": "$TMP_EXT"},
    {"name": "missing-source", "path": "/nonexistent/path/to/skills"}
  ]
}
EOF

echo "--- Test: list-sources shows both sources ---"
output=$(HOME="$TMP_HOME" "$REPO_DIR/agent-skills" list-sources 2>&1)

# Check valid source appears
if ! echo "$output" | grep -q "valid-source"; then
    echo "FAIL: valid-source not shown"
    echo "Output: $output"
    exit 1
fi

# Check missing source appears
if ! echo "$output" | grep -q "missing-source"; then
    echo "FAIL: missing-source not shown"
    echo "Output: $output"
    exit 1
fi

# Check missing dir warning
if ! echo "$output" | grep -q "directory not found"; then
    echo "FAIL: Missing directory warning not shown"
    echo "Output: $output"
    exit 1
fi

echo "ok"
