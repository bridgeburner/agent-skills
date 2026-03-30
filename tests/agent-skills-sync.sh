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

mkdir -p "$TMP_REPO/skills" "$TMP_HOME/.agents" "$TMP_BIN"

cp "$REPO_SRC/agent-skills" "$TMP_REPO/agent-skills"
cp "$REPO_SRC/CLAUDE.md" "$TMP_REPO/CLAUDE.md"

cat <<'LOCK' > "$TMP_REPO/skills-lock.json"
{
  "version": 3,
  "skills": {
    "my-skill": {
      "source": "example/repo",
      "sourceType": "github",
      "sourceUrl": "https://example.com/repo.git",
      "skillPath": "plugins/other/skills/other-skill/SKILL.md",
      "skillFolderHash": "deadbeef",
      "installedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-02T00:00:00.000Z"
    }
  }
}
LOCK

cat <<'SYSTEM_LOCK' > "$TMP_HOME/.agents/.skill-lock.json"
{
  "version": 3,
  "skills": {}
}
SYSTEM_LOCK

cat <<GIT > "$TMP_BIN/git"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/git.log"
exit 0
GIT
chmod +x "$TMP_BIN/git"

cat <<NPX > "$TMP_BIN/npx"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/npx.log"
exit 0
NPX
chmod +x "$TMP_BIN/npx"

HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash "$TMP_REPO/agent-skills" sync

if ! grep -q "skills add example/repo --skill my-skill -g -y" "$TMP_DIR/npx.log"; then
    echo "Expected npx call missing or incorrect."
    echo "npx log:"
    cat "$TMP_DIR/npx.log"
    exit 1
fi

if grep -q "other-skill" "$TMP_DIR/npx.log"; then
    echo "Unexpected skill name derived from skillPath."
    echo "npx log:"
    cat "$TMP_DIR/npx.log"
    exit 1
fi

echo "ok"
