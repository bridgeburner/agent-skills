#!/bin/bash

set -euo pipefail

REPO_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
TMP_REPO="$TMP_DIR/repo"
TMP_HOME="$TMP_DIR/home"
TMP_EXT="$TMP_DIR/ext"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_REPO/config" "$TMP_REPO/skills" "$TMP_HOME" "$TMP_EXT"
cp "$REPO_SRC/agent-skills" "$TMP_REPO/agent-skills"
cp "$REPO_SRC/config/CLAUDE.md" "$TMP_REPO/config/CLAUDE.md"

# Create one valid external source
mkdir -p "$TMP_EXT/skill-alpha"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"

# Pre-create config with one valid and one missing directory
cat > "$TMP_REPO/skill-sources.json" <<EOF
{
  "sources": [
    {"name": "valid-source", "path": "$TMP_EXT"},
    {"name": "missing-source", "path": "/nonexistent/path/to/skills"}
  ]
}
EOF

echo "--- Test: list-sources shows both sources ---"
output=$(HOME="$TMP_HOME" "$TMP_REPO/agent-skills" list-sources 2>&1)

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
