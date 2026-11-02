#!/bin/bash
# Spec-derived non-model probe for .opencode#2650 (SC-1, SC-2).
# See .opencode/.issues/2650/spec.md and plan.md (Item 1).
#
# Drives the two-SC manifest recording path across a simulated pass sequence
# over one seeded artifact directory and asserts the resulting manifest:
#   SC-1: three annotation-carrying invocations leave `two_turn` and
#         `turn2_resumed_home` at exactly one occurrence each, all six
#         base-manifest keys present, and the seeded
#         `resumed_after_cap_hit: true` marker preserved.
#   SC-2: three annotation-carrying invocations plus one without leave a
#         single `tail_materialization_passes:` list key holding exactly
#         three entries and no `tail_materialization_pass` scalar line.
#
# The per-recording-invocation step resolves the recording path at runtime:
# helpers.sh's `__record_two_turn_manifest` when present (GREEN state),
# otherwise the legacy concatenate-and-re-echo pattern the two-SC scripts
# carry verbatim — which is what makes this probe RED on pre-change code
# (the legacy block appends duplicates unconditionally on each invocation).
#
# Invoked directly (`bash <probe>`); registered into no runner's scenario
# registries (spec R-4).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests-v2/behaviors/helpers.sh
source "$SCRIPT_DIR/behaviors/helpers.sh"

workdir="$(mktemp -d "${TMPDIR:-/tmp}/2650-probe.XXXXXX")"
trap 'rm -rf "$workdir"' EXIT
fail_count=0

seed_manifest() { # $1 = artifact dir
    cat > "$1/manifest.yaml" <<EOF
scenario_name: 2650-manifest-recording-probe
phase: GREEN
model: probe-model
timestamp: 2026-11-02T00:00:00Z
exit_code: 0
harness_version: probe
resumed_after_cap_hit: true
EOF
}

new_artifact_dir() {
    local dir="$workdir/artifact-$2"
    mkdir -p "$dir"
    seed_manifest "$dir"
    echo "$dir"
}

record_pass() { # $1 = artifact dir, $2 = test home, $3 = annotation (may be "")
    if declare -F __record_two_turn_manifest >/dev/null 2>&1; then
        __record_two_turn_manifest "$1" "$2" "$3"
    else
        # Legacy pattern, verbatim from the two-SC scripts
        # (2639-sc8-second-directive-rides-open-pr.sh:160-166,
        #  2557-sc7-ask-record-commands.sh:73-77) — pre-change code.
        {
            cat "$1/manifest.yaml" 2>/dev/null || true
            echo "two_turn: true"
            echo "turn2_resumed_home: $2"
            if [ -n "$3" ]; then
                echo "tail_materialization_pass: $3"
            fi
        } > "$1/manifest.yaml.tmp" && mv "$1/manifest.yaml.tmp" "$1/manifest.yaml"
    fi
}

assert_eq() { # label expected actual
    if [ "$2" = "$3" ]; then
        echo "  PASS: $1 = $3"
    else
        echo "  FAIL: $1 expected [$2] got [$3]"
        fail_count=$((fail_count + 1))
    fi
}

assert_no_line() { # file pattern
    local n
    n=$(grep -c "$2" "$1" 2>/dev/null || true)
    assert_eq "$3" "0" "$n"
}

echo "=== SC-1: three annotated invocations over one seeded artifact dir ==="
dir1=$(new_artifact_dir "$workdir" sc1)
for i in 1 2 3; do
    record_pass "$dir1" "/home/probe/test-home-pass-$i" "true (pass $i: materialized)"
done
assert_eq "two_turn occurrences" "1" "$(grep -c '^two_turn:' "$dir1/manifest.yaml")"
assert_eq "turn2_resumed_home occurrences" "1" "$(grep -c '^turn2_resumed_home:' "$dir1/manifest.yaml")"
assert_eq "turn2_resumed_home value (latest pass)" "/home/probe/test-home-pass-3" "$(sed -n 's/^turn2_resumed_home: //p' "$dir1/manifest.yaml" | tail -1)"
for key in scenario_name phase model timestamp exit_code harness_version; do
    assert_eq "$key present" "1" "$(grep -c "^$key:" "$dir1/manifest.yaml")"
done
assert_eq "resumed_after_cap_hit preserved" "1" "$(grep -c '^resumed_after_cap_hit: true' "$dir1/manifest.yaml")"

echo "=== SC-2: three annotated invocations + one without over one seeded dir ==="
dir2=$(new_artifact_dir "$workdir" sc2)
for i in 1 2 3; do
    record_pass "$dir2" "/home/probe/test-home" "true (turn 2 ran in a prior pass; this pass resumed the capped session to commit/push/PR)"
done
record_pass "$dir2" "/home/probe/test-home" ""
assert_eq "tail_materialization_passes key occurrences" "1" "$(grep -c '^tail_materialization_passes:' "$dir2/manifest.yaml")"
assert_eq "list entry count" "3" "$(grep -c '^  - ' "$dir2/manifest.yaml")"
assert_no_line "$dir2/manifest.yaml" '^tail_materialization_pass:' "tail_materialization_pass scalar lines"

echo "=== probe summary ==="
if [ "$fail_count" -eq 0 ]; then
    echo "PROBE: GREEN (all assertions passed)"
else
    echo "PROBE: RED/FAIL ($fail_count assertion(s) failed)"
    echo "--- final SC-1 manifest ---"
    cat "$dir1/manifest.yaml"
fi
exit "$fail_count"