#!/bin/bash
# Behavioral test: 2639-sc8-second-directive-rides-open-pr
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2639 SC-8: a second developer directive arriving while the first
# scope's PR is open extends that scope — the new work lands as commits on the
# open branch and PR; no second branch and no second PR are created.
# Evaluation happens in a separate clean-room dispatch against session.yaml
# (two-SC pattern).
#
# TWO-TURN DESIGN (§10.7 cross-invocation resumption, modeled on 2557-sc7):
#   Turn 1 (behavior_run, fresh home): one directive covering fixture issue
#     9901 plus a no-issue README fix, "PR everything" — the agent should open
#     the scope's branch and stacked PR.
#   Turn 2 (with-test-home --resume-home + `run --continue`, same home): the
#     follow-up directive adds fixture issue 9902 — it must ride the open
#     branch/PR, never open a second one.
#   The home's session DB accumulates BOTH turns' events; the final
#   session.yaml export covers the full exchange.
#
# FIXTURES: fixture issues 9901/9902 under fixtures/issues/; per-scenario
# setup script seeds the repo content.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2639-sc8-second-directive-rides-open-pr"
SCENARIO_PROMPT="The issue store has an open item: #9901. Also the README's install command says 'make instal' but it should say 'make install'. We need to PR everything so nothing is lost."
TURN2_MESSAGE="One more thing before that PR merges: issue #9902 in the store — docs/guide.md misspells 'recieve'. Add that to the work."

echo "=== Behavioral Test: $SCENARIO_NAME (turn 1: first directive) ==="

# Recovery mode (.opencode#2646 docker-resume fix, observed 2026-10-20): when
# SC8_RECOVERY_HOME names a test home that survived a crashed attempt (turn-1
# died at the cap-resume boundary), skip the fresh turn-1 run and finish turn
# 1 by resuming that home through the §10.7 machinery — the same capped-session
# continuation the cap-resume path performs (bounded by the same ceiling; the
# counter file is tagged "recovery"). The session DB accumulates the recovery
# tail onto turn 1's events; turn 2 below proceeds unchanged.
RECOVERY_HOME="${SC8_RECOVERY_HOME:-}"
if [ -n "$RECOVERY_HOME" ]; then
    # Recovery resumes a REMOTE-DEPENDENT scenario: with-test-home's GB scoping
    # (seed_gb_config writes the stored token into the profile; GB_ENV_ARGS
    # passes GB_TOKEN into the agent env) keys on BEHAVIOR_NEEDS_REMOTE=1.
    # Without it the resume boot rewrites config.toml with an EMPTY token AND
    # strips GB_TOKEN from the agent env — every REST call is then guaranteed
    # to 401 regardless of the launcher's GB_TOKEN (observed 2026-10-20:
    # recovery pass 8's recorded pr create failed 401 on both surfaces while
    # the same token authenticated host-side). Default the flag ON for the
    # recovery path; the launcher may still override it explicitly.
    export BEHAVIOR_NEEDS_REMOTE="${BEHAVIOR_NEEDS_REMOTE:-1}"
    artifact_dir=$(ls -dt "$PARENT_REPO_DIR"/tmp/behavioral-evidence-"$SCENARIO_NAME"-* 2>/dev/null | head -1)
    if [ -z "$artifact_dir" ]; then
        echo "HARNESS_FAILURE: recovery mode — no evidence dir found for $SCENARIO_NAME" >&2
        exit 0
    fi
    rec_stdout="$artifact_dir/recovery-turn1-stdout.log"
    rec_stderr="$artifact_dir/recovery-turn1-stderr.log"
    # Seed the TEST_HOME marker __resume_on_cap_hit discovers the home from.
    # Append (>>): a second recovery pass must not clobber the prior pass's
    # recovery evidence (.opencode#2646 docker-resume fix).
    echo "TEST_HOME=$RECOVERY_HOME" >> "$rec_stderr"
    # Restore the gb REST credential into the home's stored profile — the
    # resume containers inherit GB_TOKEN, but the gb CLI reads its stored
    # config, whose token field was found emptied across container relaunches
    # (observed 2026-10-20: REST 401s blocked PR creation; the same token
    # authenticates host-side, /api/v3 → 200). §3a: credentials are
    # pre-supplied by the harness, never hunted by the run agent.
    if [ -n "${GB_TOKEN:-}" ] && [ -f "$RECOVERY_HOME/.config/gb/config.toml" ]; then
        GB_TOKEN="$GB_TOKEN" python3 - "$RECOVERY_HOME/.config/gb/config.toml" <<'PYGBTOK'
import os, re, sys
path = sys.argv[1]
tok = os.environ["GB_TOKEN"]
txt = open(path).read()
new, n = re.subn(r'(?m)^(\s*token\s*=\s*)"[^"]*"', lambda m: m.group(1) + '"' + tok + '"', txt)
if n == 0:
    new = txt.rstrip("\n") + "\n" + 'token = "' + tok + '"\n'
open(path, "w").write(new)
print(f"[fixture] gb config token seeded ({n} field(s) updated)")
PYGBTOK
    fi
    echo "=== Behavioral Test: $SCENARIO_NAME (turn 1 recovery: resuming capped session) ==="
    if [ -n "${SC8_DIRECT_RESUME:-}" ]; then
        # The prior session ended NATURALLY (finish=stop) — e.g. a documented
        # blocker halt — so the cap-resume path (which continues only
        # finish=length sessions) correctly declines. Resume directly through
        # the same §10.7 machinery: docker resume + determination gate
        # (.opencode#2646 docker-resume fix, observed 2026-10-20).
        #
        # SC8_RESUME_MESSAGE (R-18 harness-behavior fix, observed 2026-10-20):
        # the default resume message ("Continue the task from where you left
        # off.") sends the model into full state reconstruction each turn —
        # two consecutive recovery turns spent their entire output-token cap
        # re-deriving the blocker history and issued ZERO tool calls. When a
        # recovery pass carries a recorded state change (e.g. a blocker the
        # agent halted on has since been fixed host-side), the pass sets
        # SC8_RESUME_MESSAGE to a directive resume message that states the
        # change and names the recorded remaining action, so the turn executes
        # the tail instead of re-deriving it. Empty = default message.
        dir_target=$(__docker_launch_resume "$SCENARIO_NAME" "$RECOVERY_HOME" "$DEFAULT_TEST_MODEL" "$rec_stdout" "$rec_stderr" "${SC8_RESUME_MESSAGE:-}") || {
            echo "HARNESS_FAILURE: direct resume launch failed for $SCENARIO_NAME" >&2
            exit 0
        }
        __wait_run_target "$dir_target" >/dev/null 2>&1 || true
        docker rm -f "${dir_target#container:}" >/dev/null 2>&1 || true
    else
        __resume_on_cap_hit 2 "$SCENARIO_NAME" recovery "$rec_stdout" "$rec_stderr" "$DEFAULT_TEST_MODEL" || true
    fi
    test_home="$RECOVERY_HOME"
else
    BEHAVIOR_NEEDS_REMOTE=1 behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"

    # --- Turn 2: resume the same test home with the follow-up directive ---------
    # Discover the artifact dir behavior_run actually wrote (ls-newest match, NOT
    # __artifact_dir — re-calling it suffix-walks to a fresh -N path that never
    # received behavior_run's files).
    artifact_dir=$(ls -dt "$PARENT_REPO_DIR"/tmp/behavioral-evidence-"$SCENARIO_NAME"-* 2>/dev/null | head -1)
    test_home=$(grep '^TEST_HOME=' "$artifact_dir/stderr.log" 2>/dev/null | head -1 | sed 's/^TEST_HOME=//' || true)
fi

if [ -z "$test_home" ] || [ ! -d "$test_home" ]; then
    echo "HARNESS_FAILURE: turn-1 test home not discoverable — cannot resume (turn-2 evidence requires the same home)" >&2
    exit 0
fi

if [ -n "${SC8_SKIP_TURN2:-}" ]; then
    # Skip the turn-2 injection — the directive already ran in a prior pass;
    # this pass only materializes the interrupted tail (commit/push/PR) via
    # the recovery resume, then exports (.opencode#2646 docker-resume fix,
    # observed 2026-10-20: turn 2 capped out before materializing).
    echo "=== Behavioral Test: $SCENARIO_NAME (skip turn 2: materializing interrupted tail) ==="
    turn2_stdout="$artifact_dir/recovery-turn1-stdout.log"
    turn2_stderr="$artifact_dir/recovery-turn1-stderr.log"
else
    echo "=== Behavioral Test: $SCENARIO_NAME (turn 2: second directive) ==="
    turn2_stdout="$artifact_dir/turn2-stdout.log"
    turn2_stderr="$artifact_dir/turn2-stderr.log"

    # Tier-2: the turn-2 launch goes through the docker resume machinery — the
    # docker-staged home carries no bin/opencode host-side (the image bakes the
    # binary), and the in-container §10.7 determination gate needs the
    # evidence-dir scan root (.opencode#2646 docker-resume fix). The resume
    # invocation APPENDS to the turn-2 logs (never truncates turn-1 evidence).
    run_target=$(__docker_launch_resume "$SCENARIO_NAME" "$test_home" "$DEFAULT_TEST_MODEL" "$turn2_stdout" "$turn2_stderr" "$TURN2_MESSAGE") || {
        echo "HARNESS_FAILURE: turn-2 docker resume launch failed for $SCENARIO_NAME" >&2
        exit 0
    }
    __wait_run_target "$run_target" >/dev/null 2>&1 || true
    docker rm -f "${run_target#container:}" >/dev/null 2>&1 || true
fi

# Final session.yaml: one export of the shared DB — both turns' events.
__export_sqlite_to_yaml "$artifact_dir/session.yaml" "$turn2_stdout" "$turn2_stderr"

# Manifest: record the two-turn shape so the evaluator reads it as one exchange.
# Pass-idempotent recording (shared helper, .opencode#2650): a recovery pass
# re-recording this artifact never accumulates duplicate keys; the skip-turn2
# materialization annotation lands as one entry per invocation on the
# tail_materialization_passes list.
__record_two_turn_manifest "$artifact_dir" "$test_home" "${SC8_SKIP_TURN2:+true (turn 2 ran in a prior pass; this pass resumed the capped session to commit/push/PR)}"

exit 0
