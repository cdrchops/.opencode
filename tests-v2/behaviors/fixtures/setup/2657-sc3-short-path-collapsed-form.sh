#!/bin/bash
# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Per-scenario fixture: 2657-sc3-short-path-collapsed-form (SC-8, .opencode#2657).
# Sourced by behavior_run() with $1 = attempt workdir. See tests-v2 AGENTS.md
# §3 Step 0b.
#
# Shared fixture helpers live in the common fixture beside this one.
# shellcheck source=./2657-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/2657-common.sh"
#
# Scenario state: the file the request names. The run agent receives one
# developer-specified single-file request; the evaluation (separate clean-room
# dispatch) judges that the scope statement precedes the edit and that the
# run carries no full-path machinery and no ceremony.

setup_2657_sc3_short_path_collapsed_form() {
    local wd="$1"
    cat > "$wd/SUPPORT.md" <<'EOF'
# Support

Report problems through the tracker.
EOF
    git -C "$wd" add SUPPORT.md 2>/dev/null || true
    git -C "$wd" commit -q -m "seed: support page" 2>/dev/null || true
}

setup_2657_sc3_short_path_collapsed_form "$1"
__2657_settle_trunk "$1"
