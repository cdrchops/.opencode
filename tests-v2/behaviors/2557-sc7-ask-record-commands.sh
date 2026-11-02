#!/bin/bash
# Behavioral test: 2557-sc7-ask-record-commands
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2557 SC-7: when the repo's declared canonical build/test command
# cannot be discovered from its build manifest, the agent asks the developer
# and records the confirmed command in the repository's build manifest rather
# than guessing.
#
# TWO-TURN DESIGN (§10.7 cross-invocation resumption):
#   Turn 1 (behavior_run, fresh home): the repo's AGENTS.md declares no
#     build/test commands — the agent must ask rather than guess.
#   Turn 2 (with-test-home --resume-home + `run --continue`, same home): the
#     developer's confirmation arrives; the agent records the confirmed
#     command in the build manifest and runs it.
#   The home's session DB accumulates BOTH turns' events; the final
#   session.yaml export covers the full exchange (the ask, the confirmation,
#   and the recorded result). The turn-2 resume intentionally bypasses
#   behavior_run's fresh-session isolation assert (R-22) — resumption is the
#   sanctioned multi-turn path (§10.7); the shared-DB export is the evidence.
#
# PROMPT CONSTRUCTION: real-domain task — run the suite; the developer's
# confirmation is a real reply, not an embedded hint. Not an interview question.
#
# FIXTURE: fixtures/setup/2557-sc7-ask-record-commands.sh creates a Python
# project whose AGENTS.md has NO commands section.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2557-sc7-ask-record-commands"
SCENARIO_PROMPT="Run this repo's test suite and make sure it's green."
TURN2_MESSAGE="The canonical test command is: pytest -q. Record it where the repo declares its commands, then run the suite and tell me the result."

echo "=== Behavioral Test: $SCENARIO_NAME (turn 1: ask) ==="
BEHAVIOR_EXPECTED_ARTIFACT="AGENTS.md"
BEHAVIOR_EXPECTED_ARTIFACT_GREP="pytest -q"
BEHAVIOR_GOAL_ACTIONS="edit,write,bash"
BEHAVIOR_FIXTURE_ISSUES=0 \
behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"

# --- Turn 2: resume the same test home with the developer's confirmation ----
# Discover the artifact dir behavior_run actually wrote (ls-newest match, NOT
# __artifact_dir — re-calling it suffix-walks to a fresh -N path that never
# received behavior_run's files, which silently broke the turn-2 resume once).
artifact_dir=$(ls -dt "$PARENT_REPO_DIR"/tmp/behavioral-evidence-"$SCENARIO_NAME"-* 2>/dev/null | head -1)
test_home=$(grep '^TEST_HOME=' "$artifact_dir/stderr.log" 2>/dev/null | head -1 | sed 's/^TEST_HOME=//' || true)

if [ -z "$test_home" ] || [ ! -d "$test_home" ]; then
    echo "HARNESS_FAILURE: turn-1 test home not discoverable — cannot resume (turn-2 evidence requires the same home)" >&2
    exit 0
fi

echo "=== Behavioral Test: $SCENARIO_NAME (turn 2: record) ==="
turn2_stdout="$artifact_dir/turn2-stdout.log"
turn2_stderr="$artifact_dir/turn2-stderr.log"

TEST_WORKDIR="$test_home/project" \
bash "$SCRIPT_DIR/../with-test-home" --resume-home "$test_home" \
    "$test_home/bin/opencode" run --continue "$TURN2_MESSAGE" \
    --model "$DEFAULT_TEST_MODEL" --log-level INFO --print-logs \
    > "$turn2_stdout" 2> "$turn2_stderr" || true

# Final session.yaml: one export of the shared DB — both turns' events.
__export_sqlite_to_yaml "$artifact_dir/session.yaml" "$turn2_stdout" "$turn2_stderr"

# Manifest: record the two-turn shape so the evaluator reads it as one exchange.
# Pass-idempotent recording (shared helper, .opencode#2650): a recovery pass
# re-recording this artifact never accumulates duplicate keys.
__record_two_turn_manifest "$artifact_dir" "$test_home"

exit 0
