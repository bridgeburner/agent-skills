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

# Pick an existing local skill name for collision
local_skill=""
for skill_path in "$REPO_DIR/skills"/*/; do
    if [[ -d "$skill_path" ]]; then
        local_skill="$(basename "$skill_path")"
        break
    fi
done

if [[ -z "$local_skill" ]]; then
    echo "SKIP: No local skills found for collision test"
    exit 0
fi

# Create external source with same skill name
mkdir -p "$TMP_EXT/$local_skill"
echo "# External version" > "$TMP_EXT/$local_skill/SKILL.md"

# Register and install
HOME="$TMP_HOME" "$REPO_DIR/agent-skills" add-source "$TMP_EXT" --name test-collision

echo "--- Test: local skill wins collision ---"
output=$(HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local 2>&1)

# Verify symlink points to local, not external
target=$(readlink "$TMP_HOME/.claude/skills/$local_skill")
if [[ "$target" == "$TMP_EXT"* ]]; then
    echo "FAIL: External source won over local for '$local_skill'"
    echo "  target: $target"
    exit 1
fi

if [[ "$target" != "$REPO_DIR/skills/$local_skill/"* ]] && [[ "$target" != "$REPO_DIR/skills/$local_skill" ]]; then
    # Could also be personal, which is also higher priority
    if [[ "$target" != "$REPO_DIR/skills-personal/$local_skill/"* ]] && [[ "$target" != "$REPO_DIR/skills-personal/$local_skill" ]]; then
        echo "FAIL: Symlink doesn't point to local or personal source"
        echo "  target: $target"
        exit 1
    fi
fi

# Verify collision warning was logged
if ! echo "$output" | grep -q "Skipping '$local_skill'"; then
    echo "FAIL: No collision warning logged for '$local_skill'"
    echo "Output was:"
    echo "$output"
    exit 1
fi

echo "ok"
