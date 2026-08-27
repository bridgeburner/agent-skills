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

required_workflow_phrases=(
    'top-level orchestrator'
    '$architect'
    '$better-goal'
    '$better-review'
    '$skill-creator'
    'fresh context'
    'context fork'
    'independent of context mode'
    'jointly expressible'
)

forbidden_workflow_phrases=(
    'Delegate by default'
    'throw more compute at it'
    'After ANY correction from the user'
    'spawn a subagent to act as critic'
    'Run these Tasks in the background'
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

assert_workflow_policy() {
    local path="$1"
    local phrase
    local normalized

    normalized="$(tr '\n' ' ' < "$path" | sed -E 's/[[:space:]]+/ /g')"

    for phrase in "${required_workflow_phrases[@]}"; do
        if [[ "$normalized" != *"$phrase"* ]]; then
            echo "Missing workflow policy phrase in $path: $phrase"
            exit 1
        fi
    done

    for phrase in "${forbidden_workflow_phrases[@]}"; do
        if [[ "$normalized" == *"$phrase"* ]]; then
            echo "Obsolete unconditional workflow policy remains in $path: $phrase"
            exit 1
        fi
    done
}

assert_skill_routing() {
    local architect="$REPO_DIR/skills/architect/SKILL.md"
    local better_goal="$REPO_DIR/skills/better-goal/SKILL.md"

    if ! grep -Fq 'independent decisions' "$architect"; then
        echo "Architect must treat workflow effort dimensions as independent decisions"
        exit 1
    fi

    if ! grep -Fq 'Review is a route, not an execution mode' "$architect"; then
        echo "Architect must route review without forcing it into a build mode"
        exit 1
    fi

    if ! grep -Fq 'knowledge claim' "$architect"; then
        echo "Architect must scope proof to a research or diagnosis claim"
        exit 1
    fi

    if grep -Fq '## Design Review Gauntlet' "$better_goal"; then
        echo "better-goal must route review instead of owning a review gauntlet"
        exit 1
    fi

    if ! grep -Fq '$better-review' "$better_goal"; then
        echo "better-goal must route warranted review to better-review"
        exit 1
    fi
}

assert_policy_phrases "$POLICY"
assert_workflow_policy "$POLICY"
assert_skill_routing

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
    assert_workflow_policy "$installed"
done

echo "ok"
