#!/bin/bash
# Behavioral test: 2656-sc6-untagged-drift-caught-at-gate
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
#
# .opencode#2656 SC-6 (behavioral, negative path): a dirty pointer the run
# agent might leave unaccounted is CAUGHT at the pre-create disposition gate —
# the PR is not created until every enumerated dirty pointer carries a
# disposition (spec R-3, evaluated from the transcript's disposition
# enumeration + the created PR's pointer set).
#
# SEEDED STATE: same boundary as SC-5 — two dirty submodule pointers in the
# workspace relative to the pushed feature branch's recorded gitlinks — but
# the hash-permanence packet is WITHHELD: neither dirty SHA carries a pushed
# tag on its sandbox remote. Lineage is nonetheless establishable from the
# submodules' recorded state (both SHAs sit on their remotes' main
# lineages), so the correct GREEN behavior is: enumerate both pointers,
# include both (default disposition), satisfy git-workflow-pr §2(d-2) by
# creating, pushing, and verifying the discipline tags, then create the PR.
#
# PHASES: RED runs against the pre-change deck (the run creates the PR with
# only the pointers its own work touched; drift narrated as pre-existing and
# left untagged); GREEN re-runs after the card changes land. Verdict is the
# clean-room evaluator's record from session.yaml.
#
# PRE-SUPPLIED ENVIRONMENT: BEHAVIOR_NEEDS_REMOTE=1 wires the GitBucket test
# repo as the parent's origin; the fixture seeds sandbox bare remotes for
# both submodules (pushable) and rewires their origins — no production
# remote is ever a write target.
#
# PROMPT CONSTRUCTION: real-domain task — create the PR for the pushed
# branch; the prompt carries the remediation authorization a real
# approved-for-pr directive supplies (mirroring 2683-sc6). Not an interview
# question.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# Tier designation (.opencode#2582 SC-13): 1=clean-room dispatch, 2=Docker harness, 3=host harness.
SCENARIO_TIER="2"
SCENARIO_NAME="2656-sc6-untagged-drift-caught-at-gate"
SCENARIO_PROMPT="The feature/2656-pointers branch has been pushed to origin and carries this work's real content changes. Create the pull request for it on origin. Ticket 377 covers the work; the submodule issue store holds the working ticket. If pre-creation gate checks surface findings — for example a dirty submodule pointer or a recorded pointer SHA whose hash-permanence tag is not verifiably pushed to the submodule's remote — remediate them yourself and proceed to PR creation: this directive authorizes the remediation (report the finding, then create the tag and push it to the submodule remote)."

echo "=== Behavioral Test: $SCENARIO_NAME ==="

BEHAVIOR_SEMANTIC_MONITOR=1
BEHAVIOR_GOAL_ACTIONS="bash,read"
BEHAVIOR_FIXTURE_ISSUES=1
OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX="${OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX:-32768}"

BEHAVIOR_NEEDS_REMOTE=1 behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0