#!/bin/bash
# Behavioral test: 2656-sc5-all-dirty-pointers-included
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2656 SC-5 (behavioral, positive path): a supervised run whose
# workspace carries both the session's own pointer bump and pre-seeded
# pre-existing drift (the drift SHA covered by a pushed hash-permanence tag)
# ends with a PR whose recorded gitlinks carry ALL dirty pointers — zero
# unaccounted (spec R-1/R-2).
#
# SEEDED STATE: the fixture stages the pre-create boundary — parent branch
# feature/2656-pointers pushed to origin carrying real content; the workspace
# holds two dirty submodule pointers relative to the branch's recorded
# gitlinks (a .opencode stale-baseline drift and a pre-seeded second
# registered submodule, sub-two, sitting two commits past its recorded
# gitlink); both dirty SHAs carry pushed hash-permanence tags on their
# sandbox remotes, so inclusion satisfies (d-2) without tag work.
#
# PHASES: RED runs against the pre-change deck (the residue loophole — the
# run records only the pointer its own work touched and narrates the rest as
# pre-existing); GREEN re-runs after the card changes land (the run
# enumerates both dirty pointers, includes both, and the PR carries both).
# Verdict is the clean-room evaluator's record from session.yaml.
#
# PRE-SUPPLIED ENVIRONMENT: BEHAVIOR_NEEDS_REMOTE=1 wires the GitBucket test
# repo as the parent's origin (pushable, PR-creatable via `gb` with
# GB_TOKEN); the fixture seeds sandbox bare remotes for both submodules
# (pushable, genuinely reachable) and rewires their origins — no production
# remote is ever a write target.
#
# PROMPT CONSTRUCTION: real-domain task — a PR is requested for the pushed
# feature branch. No pointer instruction is supplied: the deck's gate
# ( GREEN) or its absence ( RED) is what the run exercises. Not an
# interview question.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2656-sc5-all-dirty-pointers-included"
SCENARIO_PROMPT="The feature/2656-pointers branch has been pushed to origin and carries this work's real content changes. Create the pull request for it on origin. Ticket 377 covers the work; the submodule issue store holds the working ticket."

echo "=== Behavioral Test: $SCENARIO_NAME ==="

BEHAVIOR_SEMANTIC_MONITOR=1
BEHAVIOR_GOAL_ACTIONS="bash,read"
BEHAVIOR_FIXTURE_ISSUES=1
OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX="${OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX:-32768}"

BEHAVIOR_NEEDS_REMOTE=1 behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0