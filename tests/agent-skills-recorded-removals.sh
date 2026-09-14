#!/bin/bash

set -euo pipefail

REPO_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

fail_with_output() {
    local message="$1" output_file="$2"
    echo "FAIL: $message" >&2
    if [[ -f "$output_file" ]]; then
        echo "--- command output ---" >&2
        cat "$output_file" >&2
    fi
    exit 1
}

new_fixture() {
    local label="$1"

    CASE_DIR="$TMP_DIR/$label"
    CASE_REPO="$CASE_DIR/repo"
    CASE_HOME="$CASE_DIR/home"
    CASE_BIN="$CASE_DIR/bin"
    CASE_LOG="$CASE_DIR/log"

    mkdir -p "$CASE_REPO/config" "$CASE_REPO/skills" \
        "$CASE_HOME/.agents/skills" "$CASE_HOME/.claude/skills" \
        "$CASE_HOME/.codex/skills" "$CASE_BIN" "$CASE_LOG"
    cp "$REPO_SRC/agent-skills" "$CASE_REPO/agent-skills"
    cp "$REPO_SRC/config/AGENTS.md" "$CASE_REPO/config/AGENTS.md"

    cat > "$CASE_BIN/git" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >> "$TEST_LOG/git.log"
EOF
    chmod +x "$CASE_BIN/git"

    cat > "$CASE_BIN/npx" <<'EOF'
#!/bin/bash
set -euo pipefail

printf '%s\n' "$*" >> "$TEST_LOG/npx.log"

if [[ "${1:-}" != "skills" ]]; then
    exit 0
fi

case "${2:-}" in
    update)
        if [[ "${RESURRECT_UPDATE:-0}" == "1" ]]; then
            # The pre-update cleanup must have removed this canonical directory.
            [[ ! -e "$TEST_HOME/.agents/skills/updater-retired" &&
                ! -L "$TEST_HOME/.agents/skills/updater-retired" ]]

            mkdir -p "$TEST_HOME/.agents/skills/updater-retired"
            printf '%s\n' '# resurrected by mocked updater' \
                > "$TEST_HOME/.agents/skills/updater-retired/SKILL.md"
            ln -s "$TEST_HOME/.agents/skills/updater-retired" \
                "$TEST_HOME/.claude/skills/updater-retired"
            ln -s "../../.agents/skills/updater-retired" \
                "$TEST_HOME/.codex/skills/updater-retired"

            lock="$TEST_HOME/.agents/.skill-lock.json"
            tmp_lock="$lock.npx-tmp"
            jq '.skills["updater-retired"] = {
                source: "example/retired",
                sourceType: "github",
                sourceUrl: "https://example.test/retired.git",
                skillPath: "skills/updater-retired/SKILL.md",
                skillFolderHash: "resurrected"
            }' "$lock" > "$tmp_lock"
            /bin/mv -- "$tmp_lock" "$lock"
        fi
        ;;
    add)
        repo="${3:-}"
        skill=""
        args=("$@")
        for ((i = 0; i < ${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "--skill" && $((i + 1)) -lt ${#args[@]} ]]; then
                skill="${args[$((i + 1))]}"
                break
            fi
        done

        # This is only a local package-manager stand-in. It records the
        # requested add so the CLI's add path can be tested without a provider.
        if [[ -n "$repo" && -n "$skill" ]]; then
            mkdir -p "$TEST_HOME/.agents/skills/$skill"
            printf '%s\n' '# installed by mocked npx' \
                > "$TEST_HOME/.agents/skills/$skill/SKILL.md"
            lock="$TEST_HOME/.agents/.skill-lock.json"
            tmp_lock="$lock.npx-tmp"
            jq --arg name "$skill" --arg source "$repo" \
                '.skills[$name] = {
                    source: $source,
                    sourceType: "github",
                    sourceUrl: ("https://example.test/" + $source + ".git"),
                    skillPath: ("skills/" + $name + "/SKILL.md"),
                    skillFolderHash: "added"
                }' "$lock" > "$tmp_lock"
            /bin/mv -- "$tmp_lock" "$lock"
        fi
        ;;
esac
EOF
    chmod +x "$CASE_BIN/npx"
}

run_cli() {
    TEST_HOME="$CASE_HOME" TEST_LOG="$CASE_LOG" \
        RESURRECT_UPDATE="${RESURRECT_UPDATE:-0}" \
        FAIL_MOVE_ONCE="${FAIL_MOVE_ONCE:-0}" \
        HOME="$CASE_HOME" PATH="$CASE_BIN:$PATH" \
        bash "$CASE_REPO/agent-skills" "$@"
}

make_skill_dir() {
    local path="$1" name="$2"
    mkdir -p "$path"
    printf -- '---\nname: %s\n---\n' "$name" > "$path/SKILL.md"
}

resolved_link_target() {
    node -e '
        const fs = require("fs");
        const path = require("path");
        const link = process.argv[1];
        console.log(path.resolve(path.dirname(link), fs.readlinkSync(link)));
    ' "$1"
}

assert_link_to() {
    local link="$1" expected="$2" actual expected_abs
    [[ -L "$link" ]] || fail "expected symlink: $link"
    actual="$(resolved_link_target "$link")"
    expected_abs="$(node -e 'const path=require("path"); console.log(path.resolve(process.argv[1]));' "$expected")"
    [[ "$actual" == "$expected_abs" ]] || fail "symlink target mismatch for $link: $actual != $expected_abs"
}

assert_lock_source() {
    local lock="$1" name="$2" source="$3" source_type="$4"
    jq -e --arg name "$name" --arg source "$source" --arg source_type "$source_type" \
        '.skills[$name].source == $source and .skills[$name].sourceType == $source_type' \
        "$lock" > /dev/null || fail "lock identity mismatch for $name in $lock"
}

assert_lock_has() {
    local lock="$1" name="$2"
    jq -e --arg name "$name" '.skills[$name] != null' "$lock" > /dev/null \
        || fail "missing $name from $lock"
}

assert_lock_absent() {
    local lock="$1" name="$2"
    if jq -e --arg name "$name" '.skills[$name] != null' "$lock" > /dev/null 2>&1; then
        fail "unexpected $name in $lock"
    fi
}

assert_log_line() {
    local log_name="$1" expected="$2" log_file
    log_file="$CASE_LOG/$log_name"
    [[ -f "$log_file" ]] || fail "missing $log_name; expected call: $expected"
    awk -v expected="$expected" '$0 == expected { found = 1 } END { exit(found ? 0 : 1) }' \
        "$log_file" || fail "missing exact $log_name call: $expected"
}

assert_no_log() {
    local log_name="$1"
    [[ ! -s "$CASE_LOG/$log_name" ]] || fail "unexpected calls in $log_name: $(cat "$CASE_LOG/$log_name")"
}

backup_for() {
    local name="$1" backup
    for backup in "$CASE_HOME"/.agents/removed-skills.*; do
        if [[ -d "$backup/$name" ]]; then
            printf '%s\n' "$backup"
            return 0
        fi
    done
    return 1
}

assert_backup_for() {
    local name="$1" backup
    backup="$(backup_for "$name")" || fail "no recovery copy for $name"
    [[ -f "$backup/$name/SKILL.md" ]] || fail "recovery copy missing for $name"
}

assert_no_backup_dirs() {
    local backup
    for backup in "$CASE_HOME"/.agents/removed-skills.*; do
        [[ ! -e "$backup" ]] || fail "unexpected recovery directory: $backup"
    done
}

test_sync_removals_and_replacements() {
    new_fixture sync-removals

    mkdir -p "$CASE_REPO/skills/local-replacement"
    printf '%s\n' '# local replacement' > "$CASE_REPO/skills/local-replacement/SKILL.md"
    CASE_EXT="$CASE_DIR/external"
    mkdir -p "$CASE_EXT/source-replacement"
    printf '%s\n' '# source replacement' > "$CASE_EXT/source-replacement/SKILL.md"

    cat > "$CASE_REPO/skill-sources.json" <<EOF
{
  "sources": [
    {"name": "fixture-source", "path": "$CASE_EXT"}
  ]
}
EOF

    cat > "$CASE_REPO/skills-removed.json" <<'EOF'
{
  "version": 1,
  "skills": {
    "retired-absolute": {"source": "example/retired", "sourceType": "github"},
    "retired-relative": {"source": "example/retired", "sourceType": "github"},
    "different-source": {"source": "example/retired", "sourceType": "github"},
    "local-replacement": {"source": "example/retired", "sourceType": "github"},
    "source-replacement": {"source": "example/retired", "sourceType": "github"},
    "real-consumer": {"source": "example/retired", "sourceType": "github"}
  }
}
EOF

    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "retired-absolute": {"source": "example/retired", "sourceType": "github"},
    "retired-relative": {"source": "example/retired", "sourceType": "github"},
    "different-source": {"source": "example/retired", "sourceType": "github"},
    "local-replacement": {"source": "example/retired", "sourceType": "github"},
    "source-replacement": {"source": "example/retired", "sourceType": "github"},
    "real-consumer": {"source": "example/retired", "sourceType": "github"},
    "survivor": {"source": "example/survivor", "sourceType": "github"}
  }
}
EOF

    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "retired-absolute": {"source": "example/retired", "sourceType": "github"},
    "retired-relative": {"source": "example/retired", "sourceType": "github"},
    "different-source": {"source": "example/replacement", "sourceType": "github"},
    "local-replacement": {"source": "example/retired", "sourceType": "github"},
    "source-replacement": {"source": "example/retired", "sourceType": "github"},
    "real-consumer": {"source": "example/retired", "sourceType": "github"},
    "survivor": {"source": "example/survivor", "sourceType": "github"}
  }
}
EOF

    for name in retired-absolute retired-relative different-source \
        local-replacement source-replacement real-consumer survivor; do
        make_skill_dir "$CASE_HOME/.agents/skills/$name" "$name"
    done

    # These links exercise absolute and relative canonical targets, plus
    # replacement links that must not be mistaken for owned canonical links.
    ln -s "$CASE_HOME/.agents/skills/retired-absolute" \
        "$CASE_HOME/.claude/skills/retired-absolute"
    ln -s "$CASE_HOME/.agents/skills/retired-absolute" \
        "$CASE_HOME/.codex/skills/retired-absolute"
    ln -s "../../.agents/skills/retired-relative" \
        "$CASE_HOME/.claude/skills/retired-relative"
    ln -s "../../.agents/skills/retired-relative" \
        "$CASE_HOME/.codex/skills/retired-relative"
    ln -s "$CASE_HOME/.agents/skills/different-source" \
        "$CASE_HOME/.claude/skills/different-source"
    ln -s "$CASE_HOME/.agents/skills/different-source" \
        "$CASE_HOME/.codex/skills/different-source"
    ln -s "$CASE_REPO/skills/local-replacement" \
        "$CASE_HOME/.claude/skills/local-replacement"
    ln -s "../../.agents/skills/local-replacement" \
        "$CASE_HOME/.codex/skills/local-replacement"
    ln -s "$CASE_HOME/.agents/skills/source-replacement" \
        "$CASE_HOME/.claude/skills/source-replacement"
    ln -s "$CASE_EXT/source-replacement" \
        "$CASE_HOME/.codex/skills/source-replacement"
    mkdir -p "$CASE_HOME/.claude/skills/real-consumer" \
        "$CASE_HOME/.codex/skills/real-consumer"
    printf '%s\n' '# unmanaged claude path' > "$CASE_HOME/.claude/skills/real-consumer/marker"
    printf '%s\n' '# unmanaged codex path' > "$CASE_HOME/.codex/skills/real-consumer/marker"
    ln -s "$CASE_HOME/.agents/skills/survivor" "$CASE_HOME/.claude/skills/survivor"
    ln -s "../../.agents/skills/survivor" "$CASE_HOME/.codex/skills/survivor"

    local output="$CASE_DIR/sync.out"
    if ! run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "sync removal fixture failed" "$output"
    fi

    for name in retired-absolute retired-relative local-replacement \
        source-replacement real-consumer; do
        [[ ! -e "$CASE_HOME/.agents/skills/$name" &&
            ! -L "$CASE_HOME/.agents/skills/$name" ]] || fail "canonical directory survived for $name"
        assert_lock_absent "$CASE_HOME/.agents/.skill-lock.json" "$name"
        assert_lock_absent "$CASE_REPO/skills-lock.json" "$name"
        assert_backup_for "$name"
    done
    [[ ! -e "$CASE_HOME/.claude/skills/retired-absolute" &&
        ! -L "$CASE_HOME/.claude/skills/retired-absolute" ]] || fail "absolute Claude link survived"
    [[ ! -e "$CASE_HOME/.codex/skills/retired-absolute" &&
        ! -L "$CASE_HOME/.codex/skills/retired-absolute" ]] || fail "absolute Codex link survived"
    [[ ! -e "$CASE_HOME/.claude/skills/retired-relative" &&
        ! -L "$CASE_HOME/.claude/skills/retired-relative" ]] || fail "relative Claude link survived"
    [[ ! -e "$CASE_HOME/.codex/skills/retired-relative" &&
        ! -L "$CASE_HOME/.codex/skills/retired-relative" ]] || fail "relative Codex link survived"

    # A same-name installation from another source is not an ownership match.
    assert_lock_source "$CASE_HOME/.agents/.skill-lock.json" \
        different-source example/replacement github
    [[ -d "$CASE_HOME/.agents/skills/different-source" ]] || fail "different-source directory removed"
    assert_link_to "$CASE_HOME/.claude/skills/different-source" \
        "$CASE_HOME/.agents/skills/different-source"
    assert_link_to "$CASE_HOME/.codex/skills/different-source" \
        "$CASE_HOME/.agents/skills/different-source"
    [[ ! -d "$CASE_HOME"/.agents/removed-skills.*/different-source ]] \
        || fail "different-source was copied into recovery"

    # Local and registered-source replacements keep their real directories and
    # become the targets of both consumer links after relinking.
    [[ -d "$CASE_REPO/skills/local-replacement" ]] || fail "local replacement directory removed"
    assert_link_to "$CASE_HOME/.claude/skills/local-replacement" \
        "$CASE_REPO/skills/local-replacement"
    assert_link_to "$CASE_HOME/.codex/skills/local-replacement" \
        "$CASE_REPO/skills/local-replacement"
    [[ -d "$CASE_EXT/source-replacement" ]] || fail "source replacement directory removed"
    assert_link_to "$CASE_HOME/.claude/skills/source-replacement" "$CASE_EXT/source-replacement"
    assert_link_to "$CASE_HOME/.codex/skills/source-replacement" "$CASE_EXT/source-replacement"

    # Unmanaged real consumer paths are preserved rather than replaced or deleted.
    [[ -d "$CASE_HOME/.claude/skills/real-consumer" &&
        -f "$CASE_HOME/.claude/skills/real-consumer/marker" ]] || fail "real Claude consumer path changed"
    [[ -d "$CASE_HOME/.codex/skills/real-consumer" &&
        -f "$CASE_HOME/.codex/skills/real-consumer/marker" ]] || fail "real Codex consumer path changed"
    assert_lock_source "$CASE_HOME/.agents/.skill-lock.json" survivor example/survivor github
    assert_link_to "$CASE_HOME/.claude/skills/survivor" "$CASE_HOME/.agents/skills/survivor"
    assert_link_to "$CASE_HOME/.codex/skills/survivor" "$CASE_HOME/.agents/skills/survivor"
    assert_no_log npx.log
    assert_log_line git.log "pull"
}

test_update_cancellation_and_no_resurrection() {
    new_fixture update-removals

    cat > "$CASE_REPO/skills-removed.json" <<'EOF'
{
  "version": 1,
  "skills": {
    "updater-retired": {"source": "example/retired", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "updater-retired": {"source": "example/retired", "sourceType": "github"},
    "updater-survivor": {"source": "example/survivor", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "updater-retired": {"source": "example/retired", "sourceType": "github"},
    "updater-survivor": {"source": "example/survivor", "sourceType": "github"}
  }
}
EOF
    make_skill_dir "$CASE_HOME/.agents/skills/updater-retired" updater-retired
    make_skill_dir "$CASE_HOME/.agents/skills/updater-survivor" updater-survivor
    ln -s "$CASE_HOME/.agents/skills/updater-retired" \
        "$CASE_HOME/.claude/skills/updater-retired"
    ln -s "../../.agents/skills/updater-retired" \
        "$CASE_HOME/.codex/skills/updater-retired"
    ln -s "$CASE_HOME/.agents/skills/updater-survivor" \
        "$CASE_HOME/.claude/skills/updater-survivor"
    ln -s "../../.agents/skills/updater-survivor" \
        "$CASE_HOME/.codex/skills/updater-survivor"

    # Cancellation must stop before the updater call and leave ownership state
    # untouched. EOF is the deterministic negative response for the prompt.
    local cancel_output="$CASE_DIR/update-cancel.out"
    if RESURRECT_UPDATE=1 run_cli update > "$cancel_output" 2>&1 < /dev/null; then
        fail_with_output "update cancellation unexpectedly succeeded" "$cancel_output"
    fi
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" updater-retired
    [[ -d "$CASE_HOME/.agents/skills/updater-retired" ]] || fail "cancelled update removed canonical skill"
    assert_link_to "$CASE_HOME/.claude/skills/updater-retired" \
        "$CASE_HOME/.agents/skills/updater-retired"
    assert_link_to "$CASE_HOME/.codex/skills/updater-retired" \
        "$CASE_HOME/.agents/skills/updater-retired"
    assert_no_log npx.log

    local update_output="$CASE_DIR/update.out"
    if ! RESURRECT_UPDATE=1 run_cli update --yes > "$update_output" 2>&1; then
        fail_with_output "update removal fixture failed" "$update_output"
    fi

    assert_log_line npx.log "skills update -g -y"
    [[ ! -e "$CASE_HOME/.agents/skills/updater-retired" &&
        ! -L "$CASE_HOME/.agents/skills/updater-retired" ]] \
        || fail "updater resurrected canonical skill"
    [[ ! -e "$CASE_HOME/.claude/skills/updater-retired" &&
        ! -L "$CASE_HOME/.claude/skills/updater-retired" ]] \
        || fail "updater resurrected Claude link"
    [[ ! -e "$CASE_HOME/.codex/skills/updater-retired" &&
        ! -L "$CASE_HOME/.codex/skills/updater-retired" ]] \
        || fail "updater resurrected Codex link"
    assert_lock_absent "$CASE_HOME/.agents/.skill-lock.json" updater-retired
    assert_lock_absent "$CASE_REPO/skills-lock.json" updater-retired
    assert_backup_for updater-retired
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" updater-survivor
    assert_lock_has "$CASE_REPO/skills-lock.json" updater-survivor
    assert_link_to "$CASE_HOME/.claude/skills/updater-survivor" \
        "$CASE_HOME/.agents/skills/updater-survivor"
    assert_link_to "$CASE_HOME/.codex/skills/updater-survivor" \
        "$CASE_HOME/.agents/skills/updater-survivor"
}

make_single_removal_fixture() {
    local name="$1" source system_source
    source="${2:-example/retired}"
    system_source="${3:-$source}"

    cat > "$CASE_REPO/skills-removed.json" <<EOF
{
  "version": 1,
  "skills": {
    "$name": {"source": "$source", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_REPO/skills-lock.json" <<EOF
{
  "version": 3,
  "skills": {
    "$name": {"source": "$source", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<EOF
{
  "version": 3,
  "skills": {
    "$name": {"source": "$system_source", "sourceType": "github"}
  }
}
EOF
}

test_refusal_boundaries() {
    new_fixture refusal-canonical-symlink
    make_single_removal_fixture symlink-canonical
    mkdir -p "$CASE_HOME/redirected/symlink-canonical"
    printf '%s\n' '# redirected' > "$CASE_HOME/redirected/symlink-canonical/SKILL.md"
    ln -s "$CASE_HOME/redirected/symlink-canonical" \
        "$CASE_HOME/.agents/skills/symlink-canonical"
    ln -s "$CASE_HOME/.agents/skills/symlink-canonical" \
        "$CASE_HOME/.claude/skills/symlink-canonical"
    ln -s "../../.agents/skills/symlink-canonical" \
        "$CASE_HOME/.codex/skills/symlink-canonical"
    local output="$CASE_DIR/canonical-symlink.out"
    if run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "canonical symlink refusal unexpectedly succeeded" "$output"
    fi
    [[ -L "$CASE_HOME/.agents/skills/symlink-canonical" ]] || fail "canonical symlink was removed"
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" symlink-canonical
    assert_link_to "$CASE_HOME/.claude/skills/symlink-canonical" \
        "$CASE_HOME/.agents/skills/symlink-canonical"
    assert_no_log npx.log

    new_fixture refusal-parent-symlink
    make_single_removal_fixture parent-symlink
    mkdir -p "$CASE_HOME/redirected-skills/parent-symlink"
    printf '%s\n' '# redirected parent' > "$CASE_HOME/redirected-skills/parent-symlink/SKILL.md"
    rmdir "$CASE_HOME/.agents/skills"
    ln -s "$CASE_HOME/redirected-skills" "$CASE_HOME/.agents/skills"
    ln -s "$CASE_HOME/.agents/skills/parent-symlink" \
        "$CASE_HOME/.claude/skills/parent-symlink"
    output="$CASE_DIR/parent-symlink.out"
    if run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "parent symlink refusal unexpectedly succeeded" "$output"
    fi
    [[ -d "$CASE_HOME/redirected-skills/parent-symlink" ]] || fail "redirected parent target changed"
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" parent-symlink
    assert_no_log npx.log

    new_fixture refusal-missing-owner
    make_single_removal_fixture missing-owner
    # Replace the ownership lock with an unrelated entry while retaining the
    # canonical directory; source identity cannot be inferred from disk.
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "unrelated": {"source": "example/unrelated", "sourceType": "github"}
  }
}
EOF
    make_skill_dir "$CASE_HOME/.agents/skills/missing-owner" missing-owner
    ln -s "$CASE_HOME/.agents/skills/missing-owner" \
        "$CASE_HOME/.claude/skills/missing-owner"
    output="$CASE_DIR/missing-owner.out"
    if run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "missing ownership refusal unexpectedly succeeded" "$output"
    fi
    [[ -d "$CASE_HOME/.agents/skills/missing-owner" ]] || fail "missing-owner directory changed"
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" unrelated
    assert_no_log npx.log

    new_fixture refusal-invalid-policy
    cat > "$CASE_REPO/skills-removed.json" <<'EOF'
{
  "version": 1,
  "skills": {
    "../escape": {"source": "example/retired", "sourceType": "github"},
    "valid-name": {"source": "example/valid", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "valid-name": {"source": "example/valid", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "valid-name": {"source": "example/valid", "sourceType": "github"}
  }
}
EOF
    make_skill_dir "$CASE_HOME/.agents/skills/valid-name" valid-name
    ln -s "$CASE_HOME/.agents/skills/valid-name" "$CASE_HOME/.claude/skills/valid-name"
    local policy_before="$CASE_DIR/policy-before.json"
    cp "$CASE_REPO/skills-removed.json" "$policy_before"
    output="$CASE_DIR/invalid-policy.out"
    if run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "invalid policy refusal unexpectedly succeeded" "$output"
    fi
    cmp -s "$policy_before" "$CASE_REPO/skills-removed.json" \
        || fail "invalid policy was changed"
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" valid-name
    [[ -d "$CASE_HOME/.agents/skills/valid-name" ]] || fail "valid-name changed after invalid policy"
    assert_link_to "$CASE_HOME/.claude/skills/valid-name" \
        "$CASE_HOME/.agents/skills/valid-name"
    assert_no_log npx.log

    if run_cli remove ../escape > "$CASE_DIR/invalid-name.out" 2>&1; then
        fail "invalid remove name unexpectedly succeeded"
    fi
    cmp -s "$policy_before" "$CASE_REPO/skills-removed.json" \
        || fail "invalid remove changed policy"
}

test_failure_retry_keeps_ownership_until_cleanup() {
    new_fixture removal-retry
    make_single_removal_fixture fail-move
    make_skill_dir "$CASE_HOME/.agents/skills/fail-move" fail-move
    ln -s "$CASE_HOME/.agents/skills/fail-move" "$CASE_HOME/.claude/skills/fail-move"
    ln -s "../../.agents/skills/fail-move" "$CASE_HOME/.codex/skills/fail-move"

    cat > "$CASE_BIN/mv" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ "${FAIL_MOVE_ONCE:-0}" == "1" &&
    "${1:-}" == "--" &&
    "${2:-}" == "$TEST_HOME/.agents/skills/fail-move" &&
    ! -e "$TEST_LOG/mv-failed" ]]; then
    touch "$TEST_LOG/mv-failed"
    exit 1
fi
exec /bin/mv "$@"
EOF
    chmod +x "$CASE_BIN/mv"

    local output="$CASE_DIR/retry-failed.out"
    if FAIL_MOVE_ONCE=1 run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "injected removal failure unexpectedly succeeded" "$output"
    fi
    # The ownership lock is intentionally retained, so a retry can identify and
    # finish the same removal after the filesystem operation failed.
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" fail-move
    [[ -d "$CASE_HOME/.agents/skills/fail-move" ]] || fail "failed move lost canonical directory"
    assert_link_to "$CASE_HOME/.claude/skills/fail-move" "$CASE_HOME/.agents/skills/fail-move"
    assert_lock_has "$CASE_REPO/skills-lock.json" fail-move

    output="$CASE_DIR/retry-success.out"
    if ! run_cli sync --yes > "$output" 2>&1; then
        fail_with_output "removal retry failed" "$output"
    fi
    [[ ! -e "$CASE_HOME/.agents/skills/fail-move" &&
        ! -L "$CASE_HOME/.agents/skills/fail-move" ]] || fail "retry left canonical directory"
    [[ ! -e "$CASE_HOME/.claude/skills/fail-move" &&
        ! -L "$CASE_HOME/.claude/skills/fail-move" ]] || fail "retry left Claude link"
    [[ ! -e "$CASE_HOME/.codex/skills/fail-move" &&
        ! -L "$CASE_HOME/.codex/skills/fail-move" ]] || fail "retry left Codex link"
    assert_lock_absent "$CASE_HOME/.agents/.skill-lock.json" fail-move
    assert_lock_absent "$CASE_REPO/skills-lock.json" fail-move
    assert_backup_for fail-move
}

test_export_filters_without_disk_mutation() {
    new_fixture export-removals

    cat > "$CASE_REPO/skills-removed.json" <<'EOF'
{
  "version": 1,
  "skills": {
    "stale": {"source": "example/retired", "sourceType": "github"},
    "system-only-retired": {"source": "example/retired", "sourceType": "github"},
    "good-repo": {"source": "example/retired", "sourceType": "github"},
    "good-system": {"source": "example/retired", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "stale": {"source": "example/retired", "sourceType": "github"},
    "good-repo": {"source": "example/good-repo", "sourceType": "github"},
    "good-system": {"source": "example/retired", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "system-only-retired": {"source": "example/retired", "sourceType": "github"},
    "good-repo": {"source": "example/retired", "sourceType": "github"},
    "good-system": {"source": "example/good-system", "sourceType": "github"},
    "unrelated": {"source": "example/unrelated", "sourceType": "github"}
  }
}
EOF

    for name in stale system-only-retired good-repo good-system unrelated; do
        make_skill_dir "$CASE_HOME/.agents/skills/$name" "$name"
        ln -s "$CASE_HOME/.agents/skills/$name" "$CASE_HOME/.claude/skills/$name"
    done
    local policy_before="$CASE_DIR/policy-before.json"
    local system_before="$CASE_DIR/system-before.json"
    cp "$CASE_REPO/skills-removed.json" "$policy_before"
    cp "$CASE_HOME/.agents/.skill-lock.json" "$system_before"

    local output="$CASE_DIR/export.out"
    if ! run_cli export > "$output" 2>&1; then
        fail_with_output "export removal fixture failed" "$output"
    fi

    assert_lock_absent "$CASE_REPO/skills-lock.json" stale
    assert_lock_absent "$CASE_REPO/skills-lock.json" system-only-retired
    assert_lock_source "$CASE_REPO/skills-lock.json" good-repo example/good-repo github
    assert_lock_source "$CASE_REPO/skills-lock.json" good-system example/good-system github
    assert_lock_source "$CASE_REPO/skills-lock.json" unrelated example/unrelated github
    cmp -s "$policy_before" "$CASE_REPO/skills-removed.json" || fail "export changed removal policy"
    cmp -s "$system_before" "$CASE_HOME/.agents/.skill-lock.json" || fail "export changed system lock"
    for name in stale system-only-retired good-repo good-system unrelated; do
        [[ -d "$CASE_HOME/.agents/skills/$name" ]] || fail "export removed canonical directory $name"
        assert_link_to "$CASE_HOME/.claude/skills/$name" "$CASE_HOME/.agents/skills/$name"
    done
    assert_no_backup_dirs
    assert_no_log npx.log
    assert_no_log git.log

    # A machine with no policy file retains the historical merge behavior.
    rm -- "$CASE_REPO/skills-removed.json"
    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "legacy-repo": {"source": "example/legacy-repo", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "legacy-system": {"source": "example/legacy-system", "sourceType": "github"}
  }
}
EOF
    run_cli export > "$CASE_DIR/export-absent-policy.out" 2>&1 \
        || fail_with_output "export without removal policy failed" "$CASE_DIR/export-absent-policy.out"
    assert_lock_has "$CASE_REPO/skills-lock.json" legacy-repo
    assert_lock_has "$CASE_REPO/skills-lock.json" legacy-system
}

test_remove_records_and_readd_requires_clear() {
    new_fixture remove-and-readd

    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "future-remove": {"source": "example/future", "sourceType": "github"},
    "other-skill": {"source": "example/other", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {
    "future-remove": {"source": "example/future", "sourceType": "github"},
    "other-skill": {"source": "example/other", "sourceType": "github"}
  }
}
EOF
    make_skill_dir "$CASE_HOME/.agents/skills/future-remove" future-remove
    make_skill_dir "$CASE_HOME/.agents/skills/other-skill" other-skill
    ln -s "$CASE_HOME/.agents/skills/future-remove" \
        "$CASE_HOME/.claude/skills/future-remove"
    ln -s "../../.agents/skills/future-remove" \
        "$CASE_HOME/.codex/skills/future-remove"
    ln -s "$CASE_HOME/.agents/skills/other-skill" \
        "$CASE_HOME/.claude/skills/other-skill"
    ln -s "../../.agents/skills/other-skill" \
        "$CASE_HOME/.codex/skills/other-skill"

    run_cli remove future-remove > "$CASE_DIR/remove.out" 2>&1 \
        || fail_with_output "remove command failed" "$CASE_DIR/remove.out"

    jq -e '
        .version == 1 and
        (.skills | length == 1) and
        .skills["future-remove"].source == "example/future" and
        .skills["future-remove"].sourceType == "github"
    ' "$CASE_REPO/skills-removed.json" > /dev/null \
        || fail "remove did not write the expected policy identity"
    assert_lock_absent "$CASE_HOME/.agents/.skill-lock.json" future-remove
    assert_lock_has "$CASE_HOME/.agents/.skill-lock.json" other-skill
    assert_lock_absent "$CASE_REPO/skills-lock.json" future-remove
    assert_lock_has "$CASE_REPO/skills-lock.json" other-skill
    [[ ! -e "$CASE_HOME/.agents/skills/future-remove" &&
        ! -L "$CASE_HOME/.agents/skills/future-remove" ]] || fail "remove left canonical directory"
    [[ ! -e "$CASE_HOME/.claude/skills/future-remove" &&
        ! -L "$CASE_HOME/.claude/skills/future-remove" ]] || fail "remove left Claude link"
    [[ ! -e "$CASE_HOME/.codex/skills/future-remove" &&
        ! -L "$CASE_HOME/.codex/skills/future-remove" ]] || fail "remove left Codex link"
    assert_backup_for future-remove
    assert_link_to "$CASE_HOME/.claude/skills/other-skill" "$CASE_HOME/.agents/skills/other-skill"
    assert_link_to "$CASE_HOME/.codex/skills/other-skill" "$CASE_HOME/.agents/skills/other-skill"
    assert_log_line git.log "add skills-lock.json skills-removed.json"
    assert_log_line git.log "commit -m Remove skill: future-remove"
    assert_log_line git.log "push"

    # A recorded identity blocks a deliberate re-add before the package manager
    # is called. Clearing that one policy entry is the explicit restore action.
    if run_cli add example/future --skill future-remove > "$CASE_DIR/add-blocked.out" 2>&1; then
        fail "recorded removal did not block re-add"
    fi
    assert_no_log npx.log

    jq 'del(.skills["future-remove"])' "$CASE_REPO/skills-removed.json" \
        > "$CASE_REPO/skills-removed.json.tmp"
    /bin/mv -- "$CASE_REPO/skills-removed.json.tmp" "$CASE_REPO/skills-removed.json"
    run_cli add example/future --skill future-remove > "$CASE_DIR/add-restored.out" 2>&1 \
        || fail_with_output "explicitly cleared re-add failed" "$CASE_DIR/add-restored.out"
    assert_log_line npx.log "skills add example/future -g -y --skill future-remove"
    assert_lock_source "$CASE_HOME/.agents/.skill-lock.json" future-remove example/future github
    assert_lock_source "$CASE_REPO/skills-lock.json" future-remove example/future github
    [[ -d "$CASE_HOME/.agents/skills/future-remove" ]] || fail "re-add did not install canonical directory"
    jq -e '(.skills | has("future-remove") | not)' "$CASE_REPO/skills-removed.json" > /dev/null \
        || fail "cleared removal policy still blocks identity"
}

test_add_different_source_same_name_is_allowed() {
    new_fixture add-different-source

    cat > "$CASE_REPO/skills-removed.json" <<'EOF'
{
  "version": 1,
  "skills": {
    "same-name": {"source": "example/retired", "sourceType": "github"}
  }
}
EOF
    cat > "$CASE_REPO/skills-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {}
}
EOF
    cat > "$CASE_HOME/.agents/.skill-lock.json" <<'EOF'
{
  "version": 3,
  "skills": {}
}
EOF

    run_cli add example/replacement --skill same-name > "$CASE_DIR/add.out" 2>&1 \
        || fail_with_output "different-source same-name add was blocked" "$CASE_DIR/add.out"
    assert_log_line npx.log "skills add example/replacement -g -y --skill same-name"
    assert_lock_source "$CASE_HOME/.agents/.skill-lock.json" \
        same-name example/replacement github
    assert_lock_source "$CASE_REPO/skills-lock.json" \
        same-name example/replacement github
    [[ -d "$CASE_HOME/.agents/skills/same-name" ]] || fail "same-name replacement was not installed"
    assert_lock_source "$CASE_REPO/skills-removed.json" \
        same-name example/retired github
}

test_sync_removals_and_replacements
test_update_cancellation_and_no_resurrection
test_refusal_boundaries
test_failure_retry_keeps_ownership_until_cleanup
test_export_filters_without_disk_mutation
test_remove_records_and_readd_requires_clear
test_add_different_source_same_name_is_allowed

echo "ok"
