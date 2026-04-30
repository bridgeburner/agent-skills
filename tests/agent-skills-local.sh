#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_HOME"
}
trap cleanup EXIT

mkdir -p "$TMP_HOME/.agents/skills/external-skill"
echo "# External Skill" > "$TMP_HOME/.agents/skills/external-skill/SKILL.md"

assert_symlink() {
    local path="$1"
    local expected="$2"

    if [[ ! -L "$path" ]]; then
        echo "Expected symlink missing: $path"
        exit 1
    fi

    local target
    target="$(readlink "$path")"
    if [[ "$target" != "$expected" ]]; then
        echo "Symlink target mismatch for $path"
        echo "  expected: $expected"
        echo "  actual:   $target"
        exit 1
    fi
}

HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local

assert_symlink "$TMP_HOME/.claude/CLAUDE.md" "$REPO_DIR/config/CLAUDE.md"
assert_symlink "$TMP_HOME/.codex/AGENTS.md" "$REPO_DIR/config/CLAUDE.md"
assert_symlink "$TMP_HOME/.claude/skills/external-skill" "$TMP_HOME/.agents/skills/external-skill/"
assert_symlink "$TMP_HOME/.codex/skills/external-skill" "$TMP_HOME/.agents/skills/external-skill/"

for skill_path in "$REPO_DIR/skills"/*/; do
    if [[ ! -d "$skill_path" ]]; then
        continue
    fi
    skill_name="$(basename "$skill_path")"
    assert_symlink "$TMP_HOME/.claude/skills/$skill_name" "$skill_path"
    assert_symlink "$TMP_HOME/.codex/skills/$skill_name" "$skill_path"
done

echo "ok"
