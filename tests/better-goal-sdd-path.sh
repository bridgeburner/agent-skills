#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

SCRIPT="$REPO_DIR/skills/better-goal/scripts/sdd_path.py"

mkdir -p "$TMP_HOME/dev/personal/demo-worktree" "$TMP_HOME/dev/altius/scheduler-worktree"
git -C "$TMP_HOME/dev/personal/demo-worktree" init -q
git -C "$TMP_HOME/dev/altius/scheduler-worktree" init -q

personal_output="$(HOME="$TMP_HOME" python3 "$SCRIPT" --cwd "$TMP_HOME/dev/personal/demo-worktree")"
[[ "$personal_output" == *'"pillar": "personal"'* ]] || {
    echo "Expected personal pillar"
    echo "$personal_output"
    exit 1
}
[[ "$personal_output" == *"\"tracker\": \"$TMP_HOME/.sdd/personal/demo-worktree\""* ]] || {
    echo "Expected personal tracker path"
    echo "$personal_output"
    exit 1
}
[[ "$personal_output" == *"\"archive_root\": \"$TMP_HOME/.sdd/personal/archive/demo-worktree\""* ]] || {
    echo "Expected personal archive path"
    echo "$personal_output"
    exit 1
}

altius_output="$(HOME="$TMP_HOME" python3 "$SCRIPT" --cwd "$TMP_HOME/dev/altius/scheduler-worktree")"
[[ "$altius_output" == *'"pillar": "altius"'* ]] || {
    echo "Expected altius pillar"
    echo "$altius_output"
    exit 1
}

HOME="$TMP_HOME" python3 "$SCRIPT" --cwd "$TMP_HOME/dev/altius/scheduler-worktree" --create >/dev/null
[[ -d "$TMP_HOME/.sdd/altius/scheduler-worktree/designs" ]] || {
    echo "Expected tracker skeleton"
    exit 1
}
[[ -d "$TMP_HOME/.sdd/altius/archive/scheduler-worktree" ]] || {
    echo "Expected archive skeleton"
    exit 1
}

mkdir -p "$TMP_HOME/dev/unknown/demo"
if HOME="$TMP_HOME" python3 "$SCRIPT" --cwd "$TMP_HOME/dev/unknown/demo" >/tmp/better-goal-sdd-path-unexpected.out 2>&1; then
    echo "Expected unknown pillar to fail"
    cat /tmp/better-goal-sdd-path-unexpected.out
    exit 1
fi

echo "ok"
