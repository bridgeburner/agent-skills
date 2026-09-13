#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf -- "$test_home"' EXIT

# Check installation behavior, not the wording of agent instructions.
mkdir -p "$test_home/.claude/skills" "$test_home/.codex/skills"
for harness in .claude .codex; do
    ln -s "$repo_root/skills/architect/" "$test_home/$harness/skills/architect"
    ln -s "$test_home/.agents/skills/test-driven-development/" \
        "$test_home/$harness/skills/test-driven-development"
done

env HOME="$test_home" "$repo_root/agent-skills" install-local

for installed in "$test_home/.claude/CLAUDE.md" \
    "$test_home/.codex/AGENTS.md" "$test_home/.agents/AGENTS.md"; do
    [[ -L "$installed" ]]
    [[ "$(readlink "$installed")" == "$repo_root/config/AGENTS.md" ]]
    cmp "$repo_root/config/AGENTS.md" "$installed"
done

for harness in .claude .codex; do
    [[ ! -e "$test_home/$harness/skills/architect" ]]
    [[ ! -L "$test_home/$harness/skills/architect" ]]
    [[ ! -e "$test_home/$harness/skills/test-driven-development" ]]
    [[ ! -L "$test_home/$harness/skills/test-driven-development" ]]
    for skill in better-goal better-review claude-spawn codex-cli gwsctx desloppify pr-monitor; do
        installed="$test_home/$harness/skills/$skill"
        [[ -L "$installed" && -f "$installed/SKILL.md" ]]
        cmp "$repo_root/skills/$skill/SKILL.md" "$installed/SKILL.md"
    done
done

jq -e '.skills | has("test-driven-development") | not' \
    "$repo_root/skills-lock.json" >/dev/null
echo "ok"
