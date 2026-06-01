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

mkdir -p "$TMP_REPO/skills" "$TMP_HOME/.agents/skills" "$TMP_BIN"
mkdir -p "$TMP_HOME/.claude/skills" "$TMP_HOME/.codex/skills"

cp "$REPO_SRC/agent-skills" "$TMP_REPO/agent-skills"
cp "$REPO_SRC/CLAUDE.md" "$TMP_REPO/CLAUDE.md"

# keep-skill: still listed upstream -> kept
# gone-skill: absent from upstream listing -> pruned
# safe-skill: upstream listing fails (empty) -> kept (fail-closed)
make_lock() {
    cat <<'LOCK'
{
  "version": 3,
  "skills": {
    "keep-skill": {
      "source": "ex/keep",
      "sourceType": "github",
      "sourceUrl": "https://example.com/keep.git",
      "skillPath": "skills/keep-skill/SKILL.md",
      "skillFolderHash": "aaaa",
      "installedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-02T00:00:00.000Z"
    },
    "gone-skill": {
      "source": "ex/gone",
      "sourceType": "github",
      "sourceUrl": "https://example.com/gone.git",
      "skillPath": "skills/gone-skill/SKILL.md",
      "skillFolderHash": "bbbb",
      "installedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-02T00:00:00.000Z"
    },
    "safe-skill": {
      "source": "ex/flaky",
      "sourceType": "github",
      "sourceUrl": "https://example.com/flaky.git",
      "skillPath": "skills/safe-skill/SKILL.md",
      "skillFolderHash": "cccc",
      "installedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-02T00:00:00.000Z"
    }
  }
}
LOCK
}

make_lock > "$TMP_REPO/skills-lock.json"
make_lock > "$TMP_HOME/.agents/.skill-lock.json"

# Installed skill dirs + pre-existing symlinks (as a prior install-local would leave them).
for s in keep-skill gone-skill safe-skill; do
    mkdir -p "$TMP_HOME/.agents/skills/$s"
    printf -- '---\nname: %s\n---\n' "$s" > "$TMP_HOME/.agents/skills/$s/SKILL.md"
    ln -s "$TMP_HOME/.agents/skills/$s" "$TMP_HOME/.claude/skills/$s"
    ln -s "$TMP_HOME/.agents/skills/$s" "$TMP_HOME/.codex/skills/$s"
done

cat <<EOF > "$TMP_BIN/npx"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/npx.log"
# Real npx reads stdin; draining it here ensures the detection loop redirects
# child stdin from /dev/null (otherwise this swallows the remaining sources).
cat > /dev/null 2>&1 || true
if [[ "\$1" == "skills" && "\$2" == "add" && "\$4" == "--list" ]]; then
    case "\$3" in
        ex/keep)  printf '│    keep-skill\n' ;;
        ex/gone)  printf '│    other-skill\n' ;;
        ex/flaky) exit 1 ;;                       # simulate clone/list failure
    esac
    exit 0
fi
exit 0
EOF
chmod +x "$TMP_BIN/npx"

cat <<EOF > "$TMP_BIN/git"
#!/bin/bash
echo "\$@" >> "$TMP_DIR/git.log"
exit 0
EOF
chmod +x "$TMP_BIN/git"

run_cli() {
    HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash "$TMP_REPO/agent-skills" "$@"
}

fail() {
    echo "FAIL: $1"
    [[ -n "${2:-}" ]] && { echo "--- $2 ---"; cat "$2"; }
    exit 1
}

# ---------------------------------------------------------------------------
# Phase 1: dry-run reports the deleted skill but changes nothing.
# ---------------------------------------------------------------------------
dry_out="$(run_cli prune --dry-run)"

echo "$dry_out" | grep -q "gone-skill" || fail "dry-run should report gone-skill"

if [[ "$(jq '.skills | length' "$TMP_REPO/skills-lock.json")" != "3" ]]; then
    fail "dry-run must not modify the repo lock" "$TMP_REPO/skills-lock.json"
fi
if [[ ! -d "$TMP_HOME/.agents/skills/gone-skill" ]]; then
    fail "dry-run must not remove the skill dir"
fi
if [[ -f "$TMP_DIR/git.log" ]] && grep -q "commit" "$TMP_DIR/git.log"; then
    fail "dry-run must not commit" "$TMP_DIR/git.log"
fi

# ---------------------------------------------------------------------------
# Phase 2: --yes actually prunes gone-skill, keeps the rest.
# ---------------------------------------------------------------------------
run_cli prune --yes > /dev/null

# Repo lock: gone-skill removed, the other two retained.
if jq -e '.skills["gone-skill"]' "$TMP_REPO/skills-lock.json" > /dev/null 2>&1; then
    fail "gone-skill should be removed from repo lock" "$TMP_REPO/skills-lock.json"
fi
jq -e '.skills["keep-skill"]' "$TMP_REPO/skills-lock.json" > /dev/null || fail "keep-skill missing from repo lock"
jq -e '.skills["safe-skill"]' "$TMP_REPO/skills-lock.json" > /dev/null || fail "safe-skill (fail-closed) wrongly pruned from repo lock"
if [[ "$(jq '.skills | length' "$TMP_REPO/skills-lock.json")" != "2" ]]; then
    fail "repo lock should have exactly 2 skills" "$TMP_REPO/skills-lock.json"
fi

# System lock: gone-skill removed, others retained.
if jq -e '.skills["gone-skill"]' "$TMP_HOME/.agents/.skill-lock.json" > /dev/null 2>&1; then
    fail "gone-skill should be removed from system lock" "$TMP_HOME/.agents/.skill-lock.json"
fi
jq -e '.skills["safe-skill"]' "$TMP_HOME/.agents/.skill-lock.json" > /dev/null || fail "safe-skill wrongly pruned from system lock"

# Disk: gone-skill dir removed, others present.
[[ ! -d "$TMP_HOME/.agents/skills/gone-skill" ]] || fail "gone-skill dir should be deleted"
[[ -d "$TMP_HOME/.agents/skills/keep-skill" ]] || fail "keep-skill dir should remain"
[[ -d "$TMP_HOME/.agents/skills/safe-skill" ]] || fail "safe-skill dir should remain"

# Symlinks: gone-skill's dangling link swept, others still valid links.
[[ ! -e "$TMP_HOME/.claude/skills/gone-skill" && ! -L "$TMP_HOME/.claude/skills/gone-skill" ]] \
    || fail "gone-skill claude symlink should be removed"
[[ -L "$TMP_HOME/.claude/skills/keep-skill" ]] || fail "keep-skill claude symlink should remain"
[[ -L "$TMP_HOME/.codex/skills/safe-skill" ]] || fail "safe-skill codex symlink should remain"

# Git: committed with the pruned name and pushed.
grep -q "commit -m Prune deleted skills: gone-skill" "$TMP_DIR/git.log" \
    || grep -q "Prune deleted skills: gone-skill" "$TMP_DIR/git.log" \
    || fail "expected prune commit" "$TMP_DIR/git.log"
grep -q "^push" "$TMP_DIR/git.log" || fail "expected push" "$TMP_DIR/git.log"

echo "ok"
