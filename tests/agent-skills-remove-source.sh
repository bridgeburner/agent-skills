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

# Create fake external skills directory
mkdir -p "$TMP_EXT/skill-alpha"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"

# Register and install
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" add-source "$TMP_EXT" --name test-ext
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local

# Verify symlinks exist before removal
if [[ ! -L "$TMP_HOME/.claude/skills/skill-alpha" ]]; then
    echo "FAIL: Symlink not created before remove test"
    exit 1
fi

echo "--- Test: remove-source cleans up ---"
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" remove-source test-ext

# Verify config has empty sources
count=$(jq '.sources | length' "$REPO_DIR/skill-sources.json")
if [[ "$count" != "0" ]]; then
    echo "FAIL: Expected 0 sources after removal, got $count"
    exit 1
fi

# Verify symlinks were cleaned up
if [[ -L "$TMP_HOME/.claude/skills/skill-alpha" ]]; then
    echo "FAIL: Symlink still exists after remove-source"
    exit 1
fi
if [[ -L "$TMP_HOME/.codex/skills/skill-alpha" ]]; then
    echo "FAIL: Codex symlink still exists after remove-source"
    exit 1
fi

echo "ok"
