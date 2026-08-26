#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY="$REPO_DIR/config/AGENTS.md"
TMP_HOME="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_HOME"
}
trap cleanup EXIT

required_phrases=(
    "read the repository's PR template"
    "Preserve every required section"
    "exact literal label"
    "answer every required field"
    "Write in plain English"
    "**Why**"
    "**What**"
    "**Required outcome**"
    "**Removed** means existing code"
    "**Avoided** means a new concept"
    "check the task, durable tracker, user context"
    "hosting-service link or bot state"
    "association or closing syntax"
    "A bot link or comment proves"
    "Never claim there is no ticket"
    "Direct Linear writes"
    "evidence boundary"
    "read the live current body back"
    "Do not add a manual testing plan unless"
)

assert_policy_phrases() {
    local path="$1"
    local phrase
    local normalized

    normalized="$(tr '\n' ' ' < "$path" | sed -E 's/[[:space:]]+/ /g')"

    for phrase in "${required_phrases[@]}"; do
        if [[ "$normalized" != *"$phrase"* ]]; then
            echo "Missing PR policy phrase in $path: $phrase"
            exit 1
        fi
    done
}

assert_policy_phrases "$POLICY"

HOME="$TMP_HOME" "$REPO_DIR/agent-skills" install-local

for installed in \
    "$TMP_HOME/.claude/CLAUDE.md" \
    "$TMP_HOME/.codex/AGENTS.md" \
    "$TMP_HOME/.agents/AGENTS.md"; do
    if [[ ! -L "$installed" ]]; then
        echo "Expected installed policy symlink missing: $installed"
        exit 1
    fi

    target="$(readlink "$installed")"
    if [[ "$target" != "$POLICY" ]]; then
        echo "Installed policy symlink target mismatch for $installed"
        echo "  expected: $POLICY"
        echo "  actual:   $target"
        exit 1
    fi

    assert_policy_phrases "$installed"
done

echo "ok"
