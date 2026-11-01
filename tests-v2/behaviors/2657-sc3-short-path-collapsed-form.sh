#!/bin/bash
# Behavioral test: 2657-sc3-short-path-collapsed-form
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2657 SC-8: a developer-specified single-file change takes the
# short path in collapsed form — the scope statement precedes the edit and
# carries the work card's contents, and the run contains no spec document,
# no plan document, no spec- or plan-validation dispatch, no halt for
# direction, no evidence hunt, no archaeology, and no card load the request
# had already satisfied; the verify card's fresh-context dispatch IS present.
# Clean-room evaluation over session.yaml (orchestrator side).
#
# PROMPT CONSTRUCTION: real-domain task — the single-file wording change the
# criterion names. Not an interview question.
#
# FIXTURES: per-scenario setup script seeds SUPPORT.md (tests-v2 AGENTS.md
# §3 Step 0b).

#
# RE-SCOPE RECORD (2026-10-30, .opencode#2657 instrument note): five GREEN runs
# of the spec's scenarios on branch tip faa527ee3 ended at the 4,000-token
# cap-resume ceiling (runs: sc1 GREEN gguf4-256k/GREEN gguf4-128k
# tmp/behavioral-evidence-2657-sc1…-GREEN-*/, sc2 GREEN gguf4-128k, sc3 GREEN
# gguf4-128k ×2) — routing facts observable, artifact-producing turns
# truncated every time. Remedy per tests-v2 AGENTS.md §3a.4 (#2665): scenario-
# scoped bounded-generation raise to OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=
# 12000, spec-gated in .opencode/.issues/2657/spec.md "Instrument note
# (2026-10-30)"; the caller's env value reaches the Docker passthrough and
# the §14 classifier seeder. Run this scenario with that env value set.
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2657-sc3-short-path-collapsed-form"
# Goal condition (tests-v2 AGENTS.md §14): the monitor's classifier judges the run
# against this declared condition, and the SC-8 determination gate lets a run that
# hits the per-turn output cap resume. Without it the classifier returns
# 'undetermined', the gate blocks the resume, and the run cannot finish.
BEHAVIOR_EXPECTED_ARTIFACT="SUPPORT.md"
BEHAVIOR_EXPECTED_ARTIFACT_GREP="## Support"
BEHAVIOR_GOAL_ACTIONS="write,edit,bash"   # the edited SUPPORT.md, and the heading the request names

SCENARIO_PROMPT="Add a \`## Support\` heading to the top of SUPPORT.md pointing at the issue tracker."

behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0
