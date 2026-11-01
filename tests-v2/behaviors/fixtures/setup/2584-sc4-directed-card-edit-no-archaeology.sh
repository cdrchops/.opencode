#!/bin/bash
# Per-scenario fixture: 2584-sc4-directed-card-edit-no-archaeology.
#
# Re-scope 2 (2026-10-30 re-scoping round 3, .opencode#2657 runs 8–9):
# pre-supply the byline-precedent facts the run agent went digging for in
# both prior runs (git log over the card's history, attic/ exploration, an
# 84-match grep for "attribution") — the boundary-state surface §3a.4
# sanctions, so the run starts at the edit itself. The precedents are staged
# AS A COMMENT in the test environment's copy of the card being edited (the
# deck itself is unchanged by the fixture; this is the test home's clone).
apply_2584_sc4_byline_precedents() {
    local wd="$1"
    local card="$wd/.opencode/skills/correspondence/SKILL.md"
    [ -f "$card" ] || { echo "HARNESS_FAILURE: fixture target card missing at $card" >&2; return 1; }
    if ! grep -q 'BYLINE-PRECEDENTS-FIXTURE' "$card"; then
        python3 - "$card" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
comment = """<!--
BYLINE-PRECEDENTS-FIXTURE (test-environment staging, .opencode#2657 2026-10-30)
Byline formats already used across this deck (the facts a directed byline
rule needs, stated here so the edit starts at the wording):
- format: "OpenCode (model-id)" — the platform byline; model ids seen:
  ollama-cloud/glm-5.3-flash, huggingface/zai-org/GLM-5.3-Flash.
- footer form used in this card's own body: a single line ending an
  outgoing message, beginning with the robot emoji, then the agent name in
  parentheses, then the status.
-->
"""
open(p, "w").write(s + "\n" + comment)
PYEOF
    fi
}
apply_2584_sc4_byline_precedents "$1"