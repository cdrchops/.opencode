#!/bin/bash
# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Per-scenario fixture: 2657-sc1-stage-request-runs-stage (SC-6, .opencode#2657).
# Sourced by behavior_run() with $1 = attempt workdir. See tests-v2 AGENTS.md
# §3 Step 0b.
#
# Shared store bootstrap lives in the common fixture beside this one.
# shellcheck source=./2657-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/2657-common.sh"
#
# Scenario state: an upload client the request names, a docs/ directory the
# named spec file goes in, and the local issue store the spec stage reserves
# a number from. The run agent receives one request that names a stage; the
# evaluation (separate clean-room dispatch) judges that the spec file was
# written and no implementation file was edited.

setup_2657_sc1_stage_request_runs_stage() {
    local wd="$1"
    mkdir -p "$wd/src" "$wd/docs"
    cat > "$wd/src/upload.py" <<'PYEOF'
"""Upload client."""


def upload(path):
    """Send the file at path to the service."""
    raise NotImplementedError("upload is not implemented yet")
PYEOF
    cat > "$wd/docs/architecture.md" <<'EOF'
# Architecture

The upload client lives in `src/upload.py` and is the only component that
talks to the service.
EOF
    git -C "$wd" add src docs 2>/dev/null || true
    git -C "$wd" commit -q -m "seed: upload client and docs" 2>/dev/null || true
    __2657_bootstrap_store "$wd"
}

setup_2657_sc1_stage_request_runs_stage "$1"
__2657_settle_trunk "$1"
