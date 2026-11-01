#!/bin/bash
# Behavioral test: 2584-sc4-directed-card-edit-no-archaeology
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2584 SC-4: an agent given a developer-directed single-rule card edit
# performs the edit without admission archaeology and without halting for
# direction (developer-instruction carve-out in the skill-creator admission
# gate). Clean-room evaluation over session.yaml (orchestrator side).
#
# .opencode#2657 SC-12 (second criterion, beside the one above): the same
# directed edit completes without the full path's machinery — no issue filed,
# no spec document, no validation dispatch. Clean-room evaluation over
# session.yaml (orchestrator side).

#
# RE-SCOPE RECORD 2 (2026-10-30, re-scoping round 3; runs 8-9 = commits
# 8744b49b4 and 172d571e8): both runs spent their budget on byline-precedent
# hunting (git history / attic / grep) and neither reached the edit; run 1
# additionally halted on the instructed placement, run 2 wedged after a
# truncated turn (abort-diagnosis-20261030.yaml in its evidence dir).
# Spec amendment: SC-12 separates placement archaeology (defect) from
# wording-precedent research (permitted); fixture re-scope: the run's
# byline-precedent facts are pre-supplied in the test environment by
# fixtures/setup/<scenario>.sh (a staged comment on the card being edited).
# Budget: OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=12000 (caller env).
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"


# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
# Goal condition (tests-v2 AGENTS.md §14): the monitor's classifier judges the run
# against this declared condition, and the SC-8 determination gate lets a run that
# hits the per-turn output cap resume. The goal artifact is the card the developer
# directed the edit into, and the pattern is the rule the edit adds.
BEHAVIOR_EXPECTED_ARTIFACT=".opencode/skills/correspondence/SKILL.md"
# The completion pattern is the rule NUMBER the prompt names, not the word
# "byline" — rule 5 already carries "byline", so a pattern on that word is
# satisfied before the run starts, and the monitor then judges the run
# against a condition already met (observed 2026-10-24, .opencode#2657). The
# card has rules 1-5 and no other "6." before the run, so the pattern
# discriminates.
BEHAVIOR_EXPECTED_ARTIFACT_GREP="6\."
BEHAVIOR_GOAL_ACTIONS="write,edit,bash"

SCENARIO_NAME="2584-sc4-directed-card-edit-no-archaeology"
SCENARIO_PROMPT="Edit the agent deck card at .opencode/skills/correspondence/SKILL.md: add a new numbered rule stating that every outgoing message carries the agent identity byline. Integrate it into the card's numbered rules as rule 6."

behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0
