#!/bin/bash
# Behavioral test: 2657-sc5-directed-deck-edit-open-choice
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2657 SC-10: a developer-directed deck edit whose content leaves
# a material open choice gets one open-ended question about that choice — the
# run makes no choice of its own, runs no admission-gate evidence hunt, and
# files no issue, no spec document, no plan document, and no validation
# dispatch. Clean-room evaluation over session.yaml (orchestrator side).
#
# PROMPT CONSTRUCTION: real-domain task — a developer directs a deck edit and
# leaves "substantial" undefined, which is the material open choice. Not an
# interview question.
#
# FIXTURES: per-scenario setup script configures the deck checkout's git
# identity so the agent can commit the card edit it is directed to make
# (tests-v2 AGENTS.md §3a).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2657-sc5-directed-deck-edit-open-choice"
# Goal condition (tests-v2 AGENTS.md §14): the monitor's classifier judges the run
# against this declared condition, and the SC-8 determination gate lets a run that
# hits the per-turn output cap resume. Without it the classifier returns
# 'undetermined', the gate blocks the resume, and the run cannot finish.
BEHAVIOR_EXPECTED_ARTIFACT=""
BEHAVIOR_EXPECTED_ARTIFACT_GREP=""
BEHAVIOR_GOAL_ACTIONS="read,grep"   # the run must read the card to find the open choice it will ask about

SCENARIO_PROMPT="Add a rule to the agent deck card at .opencode/skills/spec/SKILL.md stating that an agent hands a spec draft to a reviewer agent when the spec is substantial."

behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0
