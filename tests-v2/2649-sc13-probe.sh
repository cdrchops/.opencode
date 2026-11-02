#!/bin/bash
# Spec-derived non-model probe for .opencode#2649 (SC-2).
# See .opencode/.issues/2649/spec.md and plan.md (Item 1; items 2-4 add their
# cases here as they are implemented).
#
# SC-2 (lock-domain separation): while a run-loop-like long-lived holder keeps
# the exclusive flock on $PARENT_REPO_DIR/tmp/.behavior-run.lock, 4 concurrent
# __count_undetermined_cycle invocations on an undetermined determination must
# all complete (succeed) and leave the counter at exactly 4 — no lost updates,
# no 30s run-loop-lock wait inside the counting path (its lock domain is
# disjoint from the run-loop lock).
#
# The synthetic "-synthetic" fixture name routes the counter state file to the
# scratch evidence root (never the shared default tmp/.undetermined-cycle-count).
# Invoked directly (`bash <probe>`); registered into no runner's scenario
# registries (2650 probe precedent).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests-v2/behaviors/helpers.sh
source "$SCRIPT_DIR/behaviors/helpers.sh"

workdir="$(mktemp -d "${TMPDIR:-/tmp}/2649-probe.XXXXXX")"
trap 'rm -rf "$workdir"' EXIT
fail_count=0
check() { # name assertion-result
    if [ "$2" = "1" ]; then
        echo "  PASS: $1"
    else
        echo "  FAIL: $1"
        fail_count=$((fail_count + 1))
    fi
}

seed_undetermined_record() { # $1 = artifact dir
    mkdir -p "$1"
    cat > "$1/determination.yaml" <<EOF
determination_record:
  schema: determination-record
  schema_version: 1
  scenario_name: 2649-sc13-probe-synthetic
  phase: GREEN
  attempt: 1
  model: probe-model
  exit_code: 1
  run_path: monitor-abort
  classification: undetermined
  poll_evidence:
    monitor_log: $1/monitor.log
    polls_executed: 3
  harness_version: probe
  recorded_at: 2026-11-02T00:00:00Z
  false_signal_annotations: []
  orchestrator_decisions: []
  run_outcome_observations: []
EOF
}

echo "=== SC-2: 4 concurrent counter calls under a held behavior-run.lock ==="
art="$workdir/artifacts/2649-sc13-probe/attempt-1"
seed_undetermined_record "$art"
state_file=$(__undetermined_cycle_state_file "$art")
lock_file="$PARENT_REPO_DIR/tmp/.behavior-run.lock"
mkdir -p "$(dirname "$lock_file")" "$(dirname "$state_file")"

# Long-lived holder: flock the run-loop lock exclusively and sleep, mimicking
# the run loop holding the lock for a whole monitored run. Holds PAST the 30s
# lock-wait window so pre-change counting calls (which contend on this same
# lock) fail their -w 30 rather than succeeding after release.
(
    flock -x 200
    sleep 45
) 200>>"$lock_file" &
holder_pid=$!
# Give the holder time to acquire its lock before the counters start.
sleep 0.5

start_ts=$(date +%s)
call_pids=()
for i in 1 2 3 4; do
    __count_undetermined_cycle "$art" >"$workdir/call-$i.out" 2>&1 &
    call_pids+=("$!")
done
for pid in "${call_pids[@]}"; do
    wait "$pid" || true
done
end_ts=$(date +%s)
# release-and-reap the holder (its 45s sleep outlives the asserted window)
kill "$holder_pid" 2>/dev/null || true
wait "$holder_pid" 2>/dev/null || true
elapsed=$((end_ts - start_ts))

elapsed=$((end_ts - start_ts))
count=$(cat "$state_file" 2>/dev/null || echo 0)
check "counter value == 4 (all increments applied)" "$([ "$count" = "4" ] && echo 1 || echo 0)"
check "combined wall time (${elapsed}s) far below the 30s run-loop lock wait" "$([ "$elapsed" -lt 20 ] && echo 1 || echo 0)"
for i in 1 2 3 4; do
    ok=0
    if [ -f "$workdir/call-$i.out" ] && ! grep -q "HARNESS_FAILURE" "$workdir/call-$i.out"; then
        ok=1
    fi
    check "call $i completed without a harness lock-contention failure" "$ok"
done
echo "=== SC-3: halt-class outcome recording adds zero decision entries ==="
art2="$workdir/artifacts/2649-sc3-probe/attempt-1"
seed_undetermined_record "$art2"
sed -i 's/^  classification: undetermined$/  classification: off-track/' "$art2/determination.yaml"
echo "MONITOR-HALTED halt-class (SC-6) poll=7" > "$art2/monitor.log"
printf 'run output\nmore output\n' > "$art2/stdout.log"
printf 'run stderr\n' > "$art2/stderr.log"
__record_run_outcome "$art2" 1
det2="$art2/determination.yaml"
decisions=$(grep -c '^    - decision:' "$det2" 2>/dev/null || true)
decisions=${decisions:-0}
check "machine path appended zero 'decision:' entries" "$([ "$decisions" = "0" ] && echo 1 || echo 0)"
obs_count=$(grep -c '^    - observed_exit_code:' "$det2" 2>/dev/null || true)
obs_count=${obs_count:-0}
check "one run_outcome_observations entry present" "$([ "$obs_count" = "1" ] && echo 1 || echo 0)"
check "observation carries evidence pointers (stdout/stderr/monitor)" "$(grep -q 'stdout.log/stderr.log/monitor.log' "$det2" && echo 1 || echo 0)"
check "observation carries the exit code (exit_code: 1)" "$(grep -q "observed_exit_code: 1\$" "$det2" && echo 1 || echo 0)"

echo "=== SC-4/SC-5: SC-13 gate validates, never rewrites; SC-7 contract unchanged ==="
seed_record() { # $1=dir $2=classification $3=monitor-lines(optional)
    local dir="$1" cls="$2" mon="${3:-}"
    mkdir -p "$1"
    cat > "$1/determination.yaml" <<X
determination_record:
  schema: determination-record
  scenario_name: 2649-sc13-probe
  classification: $cls
  false_signal_annotations: []
  orchestrator_decisions: []
  run_outcome_observations: []
X
    printf '%b' "$mon" > "$1/monitor.log"
}
count_decisions() { grep -c '^    - decision:' "$1/determination.yaml" 2>/dev/null || true; }

# Case A: off-track + identifiable external cause + continue-new-dispatch →
# REJECTED (non-zero), no entry appended, values never rewritten.
dA="$workdir/case-a"; seed_record "$dA" off-track 'ORCHESTRATOR_DECISION_REQUIRED: halt-class\nleft-running process detected after halt (poll 7)\n'
rcA=0
__record_orchestrator_decision "$dA" --decision continue-new-dispatch >/dev/null 2>&1 || rcA=$?
check "case A rejected (continue-new-dispatch on non-progressing record with cause)" "$([ $rcA -ne 0 ] && echo 1 || echo 0)"
check "case A appended no decision entry" "$([ "$(count_decisions "$dA")" = "0" ] && echo 1 || echo 0)"

# Case B: undetermined + cause + terminate-with-root-cause with a generic
# (non-diagnosis) root cause → REJECTED, no entry, values never rewritten.
dB="$workdir/case-b"; seed_record "$dB" undetermined '"spending limit" notice in provider output\n'
rcB=0
__record_orchestrator_decision "$dB" --decision terminate-with-root-cause --root-cause "run exited non-zero" >/dev/null 2>&1 || rcB=$?
check "case B rejected (root_cause names no diagnosed cause)" "$([ $rcB -ne 0 ] && echo 1 || echo 0)"
check "case B appended no decision entry" "$([ "$(count_decisions "$dB")" = "0" ] && echo 1 || echo 0)"

# Case C: diagnosis-named terminate-with-root-cause → ACCEPTED and appended
# byte-identical to the entered values.
dC="$workdir/case-c"; seed_record "$dC" undetermined 'orphaned run processes after halt\n'
entered_decision="terminate-with-root-cause"
entered_root_cause="diagnosis: orphaned/left-running run processes after the halt (monitor.log)"
rcC=0
__record_orchestrator_decision "$dC" --decision "$entered_decision" --root-cause "$entered_root_cause" >/dev/null 2>&1 || rcC=$?
check "case C accepted (rc 0)" "$([ $rcC -eq 0 ] && echo 1 || echo 0)"
check "case C appended decision value byte-identical (no rewrite)" "$(grep -cF '    - decision: terminate-with-root-cause' "$dC/determination.yaml" 2>/dev/null | grep -q '^1$' && echo 1 || echo 0)"
check "case C appended root_cause byte-identical (no machine synthesis)" "$(grep -cF "      root_cause: $entered_root_cause" "$dC/determination.yaml" 2>/dev/null | grep -q '^1$' && echo 1 || echo 0)"

# Case D: non-progressing record with NO identifiable cause +
# continue-new-dispatch → gate does not fire, decision appended unchanged.
dD="$workdir/case-d"; seed_record "$dD" off-track
rcD=0
__record_orchestrator_decision "$dD" --decision continue-new-dispatch >/dev/null 2>&1 || rcD=$?
check "case D accepted (no cause → gate does not fire)" "$([ $rcD -eq 0 ] && echo 1 || echo 0)"
check "case D appended exactly one decision entry" "$([ "$(count_decisions "$dD")" = "1" ] && echo 1 || echo 0)"

# SC-5 regression cases: value-set + root-cause requirement unchanged.
dE="$workdir/case-e"; seed_record "$dE" progressing-directionally
rcE1=0
__record_orchestrator_decision "$dE" --decision terminate-with-root-cause >/dev/null 2>&1 || rcE1=$?
check "SC-5: terminate-with-root-cause without root-cause still rejected" "$([ $rcE1 -ne 0 ] && echo 1 || echo 0)"
rcE2=0
__record_orchestrator_decision "$dE" --decision bogus-value >/dev/null 2>&1 || rcE2=$?
check "SC-5: invalid value-set member still rejected" "$([ $rcE2 -ne 0 ] && echo 1 || echo 0)"
rcE3=0
__record_orchestrator_decision "$dE" --decision continue-new-dispatch >/dev/null 2>&1 || rcE3=$?
check "SC-5: valid continue-new-dispatch on progressing record accepted" "$([ $rcE3 -eq 0 ] && echo 1 || echo 0)"

echo "=== probe summary ==="
if [ "$fail_count" -eq 0 ]; then
    echo "PROBE: GREEN (all assertions passed)"
    exit 0
else
    echo "PROBE: RED ($fail_count assertion(s) failed)"
    exit 1
fi