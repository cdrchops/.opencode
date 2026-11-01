#!/bin/bash
# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Per-scenario fixture: 2657-sc2-complicated-change-full-path (SC-7, .opencode#2657).
# Sourced by behavior_run() with $1 = attempt workdir. See tests-v2 AGENTS.md
# §3 Step 0b.
#
# Shared store bootstrap lives in the common fixture beside this one.
# shellcheck source=./2657-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/2657-common.sh"
#
# Scenario state: the search endpoint the request names, and the local issue
# store the spec stage reserves a number from. The run agent receives one
# one-line request that leaves the cache key, the expiry, and the
# invalidation policy unstated; the evaluation (separate clean-room dispatch)
# judges that a full-path spec artifact appears before the first edit to an
# implementation file.

setup_2657_sc2_complicated_change_full_path() {
    local wd="$1"
    mkdir -p "$wd/src"
    cat > "$wd/src/search.py" <<'PYEOF'
"""Search endpoint."""


def search(query):
    """Return the documents matching query."""
    raise NotImplementedError("search is not implemented yet")
PYEOF
    git -C "$wd" add src 2>/dev/null || true
    git -C "$wd" commit -q -m "seed: search endpoint" 2>/dev/null || true
    __2657_bootstrap_store "$wd"
}

setup_2657_sc2_complicated_change_full_path "$1"
__2657_settle_trunk "$1"
