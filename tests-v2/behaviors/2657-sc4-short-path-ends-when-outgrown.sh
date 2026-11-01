#!/bin/bash
# Behavioral test: 2657-sc4-short-path-ends-when-outgrown
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2657 SC-9: a short-path change that acquires a second file ends
# the short path — the expanded scope statement precedes the second file's
# edit, and a full-path spec artifact appears between that statement and the
# run's next implementation edit. Clean-room evaluation over session.yaml
# (orchestrator side).
#
# PROMPT CONSTRUCTION: real-domain task — a one-line feature request whose
# work turns out to need a second file. Not an interview question.
#
# FIXTURES: per-scenario setup script seeds src/feature.py (the script the
# request names) and src/cli.py (the sibling module its argument parsing
# lives in — the second file the change turns out to need) plus the local
# issue store (tests-v2 AGENTS.md §3a, §3 Step 0b).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2657-sc4-short-path-ends-when-outgrown"
# Goal condition (tests-v2 AGENTS.md §14): the monitor's classifier judges the run
# against this declared condition, and the SC-8 determination gate lets a run that
# hits the per-turn output cap resume. Without it the classifier returns
# 'undetermined', the gate blocks the resume, and the run cannot finish.
BEHAVIOR_EXPECTED_ARTIFACT="src/cli.py"
BEHAVIOR_EXPECTED_ARTIFACT_GREP="json"   # the flag the request names; absent from the seeded parser
BEHAVIOR_GOAL_ACTIONS="write,edit,bash"   # the second file — the parser that must accept the flag

SCENARIO_PROMPT="Add a \`--json\` flag to src/feature.py so the feature script prints the feature as JSON."
# RE-SCOPE 2 (2026-10-30, run 1 aborted off-track): run 1 spent its opening
# turns in issue-store archaeology over the harness-injected story fixtures
# (bash loops grepping .issues/2313/.issues/9003/.issues/9905/.issues/9906)
# trying to establish which issue/object the bare one-line request named;
# the monitor classified off-track and the supervisor terminated it
# (abort-diagnosis-20261030.yaml). Re-scope per tests-v2 §3a.4: the prompt
# now names src/feature.py so the request's object is unambiguous and the
# run starts at the action step. The second-file acquisition is unchanged:
# the delegated parser lives in src/cli.py inside the fixture.

behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0
