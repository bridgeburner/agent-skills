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

# Create external source with two skills
mkdir -p "$TMP_EXT/skill-alpha" "$TMP_EXT/skill-beta"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"
echo "# Beta" > "$TMP_EXT/skill-beta/SKILL.md"

# Register and install
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" add-source "$TMP_EXT" --name test-dangling
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local

# Verify both symlinks exist
if [[ ! -L "$TMP_HOME/.claude/skills/skill-alpha" ]]; then
    echo "FAIL: skill-alpha symlink not created"
    exit 1
fi
if [[ ! -L "$TMP_HOME/.claude/skills/skill-beta" ]]; then
    echo "FAIL: skill-beta symlink not created"
    exit 1
fi

# Remove one skill directory from the external source
rm -rf "$TMP_EXT/skill-alpha"

echo "--- Test: dangling symlink cleaned up on re-install ---"
output=$(HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local 2>&1)

# skill-alpha should have been cleaned up (dangling)
if [[ -L "$TMP_HOME/.claude/skills/skill-alpha" ]]; then
    echo "FAIL: Dangling symlink for skill-alpha still exists"
    exit 1
fi

# skill-beta should still be linked
if [[ ! -L "$TMP_HOME/.claude/skills/skill-beta" ]]; then
    echo "FAIL: skill-beta symlink was removed"
    exit 1
fi

# Verify cleanup message was logged
if ! echo "$output" | grep -q "Removing dangling symlink"; then
    echo "FAIL: No dangling symlink cleanup message"
    echo "Output was:"
    echo "$output"
    exit 1
fi

echo "ok"
