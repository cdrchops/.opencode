#!/bin/bash
# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Per-scenario fixture: 2657-sc5-directed-deck-edit-open-choice (SC-10, .opencode#2657).
# Sourced by behavior_run() with $1 = attempt workdir. See tests-v2 AGENTS.md
# §3 Step 0b.
#
# Shared fixture helpers live in the common fixture beside this one.
# shellcheck source=./2657-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/2657-common.sh"
#
# Scenario state: the deck checkout the harness already provides, with a git
# identity so the agent can commit the card edit it is directed to make. The
# target card (`skills/spec/SKILL.md`) is in that checkout. The run agent
# receives one developer-directed deck edit whose content leaves "substantial"
# undefined; the evaluation (separate clean-room dispatch) judges that the run
# asks one open-ended question about that choice and chooses nothing.

setup_2657_sc5_directed_deck_edit_open_choice() {
    local wd="$1"
    if [ -d "$wd/.opencode" ]; then
        git -C "$wd/.opencode" config user.email "test@test.dev" 2>/dev/null || true
        git -C "$wd/.opencode" config user.name "Test" 2>/dev/null || true
    fi
}

setup_2657_sc5_directed_deck_edit_open_choice "$1"
__2657_settle_trunk "$1"
