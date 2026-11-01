#!/bin/bash
# poll-run.sh — supervision poll for an active behavioral run (card §9).
# Reads the active run's session DB (SQLite export), prints a digest of what
# the run agent is doing, and ENDS WITH THE REMINDER BLOCK: the orchestrator
# MUST deliver a text-only in-chat update (semantic analysis of this poll's
# evidence) before the next poll call, then CONTINUE POLLING IMMEDIATELY in
# the same working flow — the update is mid-flow, never a stopping point
# (#2561: silent 30-minute blocking runs are a supervision defect; observed
# 2026-10-20, #2647 family: "the next turn" wording read as turn-terminal and
# the supervisor stopped twice).
#
# Usage: poll-run.sh <path-to-session.yaml> [poll_number]
#   The DB path is the active run's test-home session export — pin it to the
#   run you are supervising (env-passed path, never newest-by-mtime).

set -euo pipefail
DB="${1:?usage: poll-run.sh <session.yaml> [poll_number]}"
POLL="${2:-?}"

python3 - "$DB" "${2:-?}" <<'PYEOF'
import json, sqlite3, sys, time

db_path, poll = sys.argv[1], sys.argv[2]
con = sqlite3.connect(db_path)
cur = con.cursor()
# Live session DB (tests-v2 AGENTS.md §14): the event table's
# message.part.updated events carry the parts — tool calls, text,
# reasoning. Extract from the documented event stream.
tool_calls, texts, reasoning_chars = [], [], 0
for (typ, data) in cur.execute("select type, data from event order by id"):
    if not typ.startswith("message.part.updated"):
        continue
    p = (json.loads(data) or {}).get("part") or {}
    t = p.get("type")
    if t == "tool":
        st = p.get("state") or {}
        tool_calls.append(f"{p.get('tool','?')} [{st.get('status','?')}] {str(st.get('title',''))[:70]}")
    elif t == "text" and (p.get("text") or "").strip():
        texts.append(p["text"].strip())
    elif t == "reasoning":
        reasoning_chars += len(p.get("text") or "")
print(f"POLL {poll} ts={int(time.time())} tools={len(tool_calls)} reasoning_chars={reasoning_chars}")
print(f"latest_tool_call: {tool_calls[-1] if tool_calls else 'none-yet'}")
print("recent_tool_calls (oldest→newest):")
for t in tool_calls[-8:]:
    print(f"  - {t}")
if texts:
    print("latest_agent_text (excerpt):")
    print("  " + texts[-1].replace("\n", "\n  ")[:600])
PYEOF

cat <<'NEXTCYCLE'
=== BEFORE YOUR NEXT POLLING CYCLE — DO THIS FIRST, IN THIS ORDER ===
  1. NOW: report THIS poll's analysis to the developer in a STANDALONE
     text-only turn (opens "POLL <n>"; NO tool call in that turn).
  2. THEN: launch the next polling cycle (sleep 60 + this script) as its
     own turn. Text first, tool call second — never bundled.
  Order and unbundled turns are enforced by the developer directive
  2026-10-31: an analysis bundled with a tool call is undelivered.
===============================================================
NEXTCYCLE

cat <<'REMINDER' >&2

=== ORCHESTRATOR REMINDER (card §9, .opencode#2561; #2570; directive 2026-10-30; wording r2+r3 2026-10-31) ===
TURN STRUCTURE, FIRST (the rule most often violated):
  BAD:  analysis prose riding in the same turn as the next tool call.
  GOOD: turn A — poll tool call (sleep 60 SECONDS, never longer;
        the ≤60s floor is .opencode#2557), nothing else in the message;
        turn B — ONLY the analysis text, opening "POLL <n>", no tool call;
        turn C — next poll tool call (sleep 60 again).
  A tool-call turn collapses in the developer's UI to the bare command line,
  so analysis attached to any tool call is UNDELIVERED. Every poll's
  analysis is turn B: text only. The cycle: poll → text turn → poll.
This poll's evidence now requires YOUR semantic analysis. Deliver it NOW as
an in-chat text update (plain text, no tool call attached to the analysis),
stating:
  1. what the run agent is doing right now (from its actual words/work),
  2. what it intends next,
  3. whether that serves the scenario's declared goal condition,
  4. which hard-abort signals (tests-v2 AGENTS.md §14) have fired, if any.
The update is MID-FLOW, never terminal: after delivering it, immediately
issue the next poll cycle (sleep 60 + poll-run.sh) in the same working
session. Do NOT end the workflow, do NOT yield to the operator, do NOT wait
for input — stopping after the update is itself the supervision defect this
reminder exists to prevent. Ordering rule stands: the update text comes
before the next poll call — never chain a tool call before delivering it.
Delivery rule (developer directive 2026-10-30): the update
is a STANDALONE TURN — a turn whose entire content is the analysis text,
with NO tool call attached. Tool-call turns collapse in the developer's UI
to the bare command line, so an analysis riding in the same message as a
tool call never reaches the developer — an update delivered in a tool-call
turn is an undelivered update, whatever the supervisor's transcript shows.
The cycle is therefore: poll tool call (alone in its turn) → text-only
update turn → next poll tool call.
This reminder is emitted on stderr as well as stdout so it survives output
filtering — filtering or truncating poll output is itself a supervision
defect; never pipe poll output through grep/head/tail.
=========================================================
REMINDER

cat <<'REMINDER'

=== ORCHESTRATOR REMINDER (card §9, .opencode#2561; #2570; directive 2026-10-30; wording r2+r3 2026-10-31) ===
TURN STRUCTURE, FIRST (the rule most often violated):
  BAD:  analysis prose riding in the same turn as the next tool call.
  GOOD: turn A — poll tool call (sleep 60 SECONDS, never longer;
        the ≤60s floor is .opencode#2557), nothing else in the message;
        turn B — ONLY the analysis text, opening "POLL <n>", no tool call;
        turn C — next poll tool call (sleep 60 again).
  A tool-call turn collapses in the developer's UI to the bare command line,
  so analysis attached to any tool call is UNDELIVERED. Every poll's
  analysis is turn B: text only. The cycle: poll → text turn → poll.
This poll's evidence now requires YOUR semantic analysis. Deliver it NOW as
an in-chat text update (plain text, no tool call attached to the analysis),
stating:
  1. what the run agent is doing right now (from its actual words/work),
  2. what it intends next,
  3. whether that serves the scenario's declared goal condition,
  4. which hard-abort signals (tests-v2 AGENTS.md §14) have fired, if any.
The update is MID-FLOW, never terminal: after delivering it, immediately
issue the next poll cycle (sleep 60 + poll-run.sh) in the same working
session. Do NOT end the workflow, do NOT yield to the operator, do NOT wait
for input — stopping after the update is itself the supervision defect this
reminder exists to prevent. Ordering rule stands: the update text comes
before the next poll call — never chain a tool call before delivering it.
Delivery rule (developer directive 2026-10-30): the update
is a STANDALONE TURN — a turn whose entire content is the analysis text,
with NO tool call attached. Tool-call turns collapse in the developer's UI
to the bare command line, so an analysis riding in the same message as a
tool call never reaches the developer — an update delivered in a tool-call
turn is an undelivered update, whatever the supervisor's transcript shows.
The cycle is therefore: poll tool call (alone in its turn) → text-only
update turn → next poll tool call.
This reminder is emitted on stderr as well as stdout so it survives output
filtering — filtering or truncating poll output is itself a supervision
defect; never pipe poll output through grep/head/tail.
=========================================================
REMINDER
