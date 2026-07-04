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
cp "$REPO_SRC/config/AGENTS.md" "$TMP_REPO/config/AGENTS.md"

# Create fake external skills directory
mkdir -p "$TMP_EXT/skill-alpha"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"

# Register and install
HOME="$TMP_HOME" "$TMP_REPO/agent-skills" add-source "$TMP_EXT" --name test-ext
HOME="$TMP_HOME" "$TMP_REPO/agent-skills" install-local

# Verify symlinks exist before removal
if [[ ! -L "$TMP_HOME/.claude/skills/skill-alpha" ]]; then
    echo "FAIL: Symlink not created before remove test"
    exit 1
fi

echo "--- Test: remove-source cleans up ---"
HOME="$TMP_HOME" "$TMP_REPO/agent-skills" remove-source test-ext

# Verify config has empty sources
count=$(jq '.sources | length' "$TMP_REPO/skill-sources.json")
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
