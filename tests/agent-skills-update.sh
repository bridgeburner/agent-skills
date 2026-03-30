#!/bin/bash

set -euo pipefail

REPO_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
TMP_REPO="$TMP_DIR/repo"
TMP_HOME="$TMP_DIR/home"
TMP_BIN="$TMP_DIR/bin"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_REPO/skills/demo-skill" "$TMP_HOME/.agents" "$TMP_BIN"

cp "$REPO_SRC/agent-skills" "$TMP_REPO/agent-skills"
cp "$REPO_SRC/CLAUDE.md" "$TMP_REPO/CLAUDE.md"

cat <<'SKILL' > "$TMP_REPO/skills/demo-skill/SKILL.md"
---
name: demo-skill
description: Demo skill for tests.
---
SKILL

cat <<'LOCK' > "$TMP_REPO/skills-lock.json"
{
  "version": 3,
  "skills": {}
}
LOCK

cat <<'SYSTEM_LOCK' > "$TMP_HOME/.agents/.skill-lock.json"
{
  "version": 3,
  "skills": {
    "demo-skill": {
      "source": "example/repo",
      "sourceType": "github",
      "sourceUrl": "https://example.com/repo.git",
      "skillPath": "skills/demo-skill/SKILL.md",
      "skillFolderHash": "deadbeef",
      "installedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-02T00:00:00.000Z"
    }
  }
}
SYSTEM_LOCK

cat <<EOF > "$TMP_BIN/git"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/git.log"
exit 0
EOF
chmod +x "$TMP_BIN/git"

cat <<EOF > "$TMP_BIN/npx"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/npx.log"
exit 0
EOF
chmod +x "$TMP_BIN/npx"

actual_npx="$(HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash -c 'command -v npx')"
if [[ "$actual_npx" != "$TMP_BIN/npx" ]]; then
    echo "Expected npx at $TMP_BIN/npx, got $actual_npx"
    exit 1
fi

HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash "$TMP_REPO/agent-skills" update

cmp -s "$TMP_REPO/skills-lock.json" "$TMP_HOME/.agents/.skill-lock.json"

if ! grep -q "skills update -g -y" "$TMP_DIR/npx.log"; then
    echo "Expected npx update call missing."
    echo "npx log:"
    cat "$TMP_DIR/npx.log"
    exit 1
fi
grep -q "^pull" "$TMP_DIR/git.log"
grep -q "^add" "$TMP_DIR/git.log"
grep -q "^commit" "$TMP_DIR/git.log"
grep -q "^push" "$TMP_DIR/git.log"

if [[ ! -L "$TMP_HOME/.claude/skills/demo-skill" ]]; then
    echo "Expected local skill link missing"
    exit 1
fi

if [[ ! -L "$TMP_HOME/.codex/skills/demo-skill" ]]; then
    echo "Expected codex skill link missing"
    exit 1
fi

echo "ok"
