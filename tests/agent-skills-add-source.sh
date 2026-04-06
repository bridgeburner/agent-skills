#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_EXT="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_HOME" "$TMP_EXT"
}
trap cleanup EXIT

assert_symlink() {
    local path="$1"
    local expected="$2"

    if [[ ! -L "$path" ]]; then
        echo "FAIL: Expected symlink missing: $path"
        exit 1
    fi

    local target
    target="$(readlink "$path")"
    if [[ "$target" != "$expected" ]]; then
        echo "FAIL: Symlink target mismatch for $path"
        echo "  expected: $expected"
        echo "  actual:   $target"
        exit 1
    fi
}

# Create fake external skills directory with two skills
mkdir -p "$TMP_EXT/skill-alpha" "$TMP_EXT/skill-beta"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"
echo "# Beta" > "$TMP_EXT/skill-beta/SKILL.md"

# Test 1: add-source registers the external directory
echo "--- Test 1: add-source creates config ---"
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" add-source "$TMP_EXT" --name test-ext

config="$REPO_DIR/skill-sources.json"
if [[ ! -f "$config" ]]; then
    echo "FAIL: skill-sources.json not created"
    exit 1
fi

# Verify JSON content
name=$(jq -r '.sources[0].name' "$config")
path=$(jq -r '.sources[0].path' "$config")
if [[ "$name" != "test-ext" ]]; then
    echo "FAIL: Expected name 'test-ext', got '$name'"
    rm -f "$config"
    exit 1
fi
if [[ "$path" != "$TMP_EXT" ]]; then
    echo "FAIL: Expected path '$TMP_EXT', got '$path'"
    rm -f "$config"
    exit 1
fi

echo "--- Test 2: install-local links external skills ---"
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local

assert_symlink "$TMP_HOME/.claude/skills/skill-alpha" "$TMP_EXT/skill-alpha/"
assert_symlink "$TMP_HOME/.claude/skills/skill-beta" "$TMP_EXT/skill-beta/"
assert_symlink "$TMP_HOME/.codex/skills/skill-alpha" "$TMP_EXT/skill-alpha/"
assert_symlink "$TMP_HOME/.codex/skills/skill-beta" "$TMP_EXT/skill-beta/"

echo "--- Test 3: skill-sources.json not modified by install-local ---"
name_after=$(jq -r '.sources[0].name' "$config")
if [[ "$name_after" != "test-ext" ]]; then
    echo "FAIL: skill-sources.json was modified by install-local"
    rm -f "$config"
    exit 1
fi

# Cleanup config file (it's in the repo dir, not in TMP)
rm -f "$config"

echo "ok"
