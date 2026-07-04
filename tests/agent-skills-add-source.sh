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

# Create fake local and external skills plus artifact directories without SKILL.md.
mkdir -p "$TMP_REPO/skills/local-skill" "$TMP_REPO/skills/local-workspace"
echo "# Local" > "$TMP_REPO/skills/local-skill/SKILL.md"

mkdir -p "$TMP_EXT/skill-alpha" "$TMP_EXT/skill-beta" "$TMP_EXT/not-a-skill"
echo "# Alpha" > "$TMP_EXT/skill-alpha/SKILL.md"
echo "# Beta" > "$TMP_EXT/skill-beta/SKILL.md"

# Test 1: add-source registers the external directory
echo "--- Test 1: add-source creates config ---"
add_output=$(HOME="$TMP_HOME" "$TMP_REPO/agent-skills" add-source "$TMP_EXT" --name test-ext 2>&1)

if grep -q "not-a-skill" <<< "$add_output"; then
    echo "FAIL: add-source should not report directories without SKILL.md"
    echo "$add_output"
    exit 1
fi
if ! grep -q "Found 2 skill(s)" <<< "$add_output"; then
    echo "FAIL: add-source should report only directories with SKILL.md"
    echo "$add_output"
    exit 1
fi

config="$TMP_REPO/skill-sources.json"
if [[ ! -f "$config" ]]; then
    echo "FAIL: skill-sources.json not created"
    exit 1
fi

# Verify JSON content
name=$(jq -r '.sources[0].name' "$config")
path=$(jq -r '.sources[0].path' "$config")
if [[ "$name" != "test-ext" ]]; then
    echo "FAIL: Expected name 'test-ext', got '$name'"
    exit 1
fi
if [[ "$path" != "$TMP_EXT" ]]; then
    echo "FAIL: Expected path '$TMP_EXT', got '$path'"
    exit 1
fi

echo "--- Test 2: install-local links external skills ---"
HOME="$TMP_HOME" "$TMP_REPO/agent-skills" install-local

assert_symlink "$TMP_HOME/.claude/skills/skill-alpha" "$TMP_EXT/skill-alpha/"
assert_symlink "$TMP_HOME/.claude/skills/skill-beta" "$TMP_EXT/skill-beta/"
assert_symlink "$TMP_HOME/.codex/skills/skill-alpha" "$TMP_EXT/skill-alpha/"
assert_symlink "$TMP_HOME/.codex/skills/skill-beta" "$TMP_EXT/skill-beta/"
assert_symlink "$TMP_HOME/.claude/skills/local-skill" "$TMP_REPO/skills/local-skill/"
assert_symlink "$TMP_HOME/.codex/skills/local-skill" "$TMP_REPO/skills/local-skill/"

if [[ -e "$TMP_HOME/.claude/skills/not-a-skill" || -e "$TMP_HOME/.codex/skills/not-a-skill" ]]; then
    echo "FAIL: external directory without SKILL.md should not be linked"
    exit 1
fi
if [[ -e "$TMP_HOME/.claude/skills/local-workspace" || -e "$TMP_HOME/.codex/skills/local-workspace" ]]; then
    echo "FAIL: local directory without SKILL.md should not be linked"
    exit 1
fi

list_output=$(HOME="$TMP_HOME" "$TMP_REPO/agent-skills" list 2>&1)
if grep -q "not-a-skill\\|local-workspace" <<< "$list_output"; then
    echo "FAIL: directories without SKILL.md should not be listed"
    echo "$list_output"
    exit 1
fi

source_output=$(HOME="$TMP_HOME" "$TMP_REPO/agent-skills" list-sources 2>&1)
if ! grep -q "Skills: 2" <<< "$source_output"; then
    echo "FAIL: list-sources should count only directories with SKILL.md"
    echo "$source_output"
    exit 1
fi

echo "--- Test 3: skill-sources.json not modified by install-local ---"
name_after=$(jq -r '.sources[0].name' "$config")
if [[ "$name_after" != "test-ext" ]]; then
    echo "FAIL: skill-sources.json was modified by install-local"
    exit 1
fi

echo "ok"
