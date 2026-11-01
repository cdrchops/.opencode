---
name: behavioral-testing
description: "Load for ANY opencode behavior testing — running a behavioral SC, verifying agent behavior, executing or monitoring an `opencode run`, evaluating session evidence, or deciding how to produce behavioral evidence at all. Also load when a spec SC is classified behavioral, when a test scenario script under tests-v2/ is authored or run, when a behavioral test needs a real remote API (the harness provisions a self-contained GitBucket container — §12), or when a behavioral run stalls, times out, or fails. Routes to the tests-v2 behavioral harness — never an ad-hoc `opencode run`."
license: MIT
provenance: AI-authored, .opencode#2517; #2538 isolation mandate + evaluator contract restored from pre-rip deck; #2570 supervision-cycle absoluteness + no-output-filtering; one-update-per-poll no-gaps clause, .opencode#2683; standalone-update-turn rule, developer directive 2026-10-30; wording r2 (BAD/GOOD turn shapes + all-polling-loops scope), developer directive 2026-10-31; cadence 60s into the shape block, developer directive 2026-10-31
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2517; #2538 clean-room isolation mandate and evaluator contract restored from pre-rip verification-before-completion; #2557 supervision poll discipline (≤60s, semantic check per poll, per-poll report); one-update-per-poll no-gaps clause (POLL<n> header, aborted-poll coverage), .opencode#2683 developer directive -->

# behavioral-testing — the tests-v2 harness gate

1. **Harness only, scoped per tier (.opencode#2582).** Scenario scripts carry a
   tier designation (`SCENARIO_TIER`): tier-2 (Docker harness) and tier-3 (host
   harness) behavioral evidence is produced by `.opencode/tests-v2/` — read
   [`tests-v2/AGENTS.md`](../../tests-v2/AGENTS.md) first, every time. Scenario
   scripts via `behavior_run()`, environment via `with-test-home`; an ad-hoc
   `opencode run` is never behavioral evidence for tier-2/tier-3. Invoke only
   as `bash .opencode/tests-v2/behaviors/<scenario>.sh` from the project root —
   never bare `opencode run` (SQLite session conflicts with the desktop app),
   never inline or from-scratch test infrastructure.
   **Tier-1 (simple card changes, eligibility by agent judgment — never a
   scripted checklist):** evidence is a recorded clean-room sub-agent dispatch
   that verifies the change directly — the dispatch prompt, the criterion
   judged, and the returned verdict are persisted into the owning issue's
   artifact area (audit dir). No harness run is required for tier-1 evidence.
2. **Clean-room isolation is inviolable.** The test home is built from the
    pushed effective commit — never from session state. Do NOT pass session
    credentials through the `env -i` allowlist, do NOT inject config entries
    or secrets into the seeded test environment (including via per-scenario
    fixtures), do NOT weaken isolation to make a failing test pass. If a
    behavioral SC needs something the isolated environment cannot provide,
    that is a spec problem — re-scope the SC at the spec, never the isolation.
    (Observed regression, #2538: a fixture was authored to inject an MCP entry
    into the seeded test config and an allowlist credential passthrough was
    proposed; both ruled a bypass of the isolation the harness exists to
    enforce.)
    **Docker-tier isolation contract (tier-2, .opencode#2582):** containers run
    as the invoking uid:gid, the only host mount is the project's `tmp/`
    (mounted at the same absolute path), no production folder (`.tools/`, repo
    worktree outside `tmp/`, `$HOME`, either `.issues/` store) is mounted into
    or copied into the container, the test home starts bare of agent-managed
    tooling (no binary/uv copies), and the image's baked base tools (pinned
    upstream versions) are the harness's instruments. **Host-path isolation
    mandates** — the snap prohibitions (`snap run`, `/snap/bin/opencode`),
    `USER=opencode-test-user`, and the production-DB sha256 check — apply to
    **tier-3 (host) runs**; on the Docker tier the equivalent protections are
    structural (the container cannot reach production paths at all).
3. **Scenario authoring.** Copy `template.sh`; the script is an artifact-only
   generator — it runs `behavior_run`, exits 0, and NEVER evaluates output.
   `SCENARIO_NAME` is kebab-case and MUST match any
   `fixtures/setup/<name>.sh` fixture filename; prompt references to issue
   content require fixture files under `fixtures/issues/{N}/` (§3). Every run
   follows the ordered precondition cycle: commit → push → fetch/verify →
   run (§4).
4. **Artifacts.** Harness output lands where `behavior_run` writes it
   (`./tmp/behavioral-evidence-<scenario>-<phase>-<model>/`, tests-v2/AGENTS.md
   §2); preserve verification artifacts issue-keyed under
   `{project_root}/tmp/{issue-N}/artifacts/`. Never fabricate, move, or
   synthesize artifacts — a missing export is remediated per §10, never
   reconstructed.
5. **Standard evaluator sub-agent.** After every behavioral run, dispatch the
   clean-room evaluator — Read [Clean-Room Behavioral
   Evaluation](references/behavioral-evaluation.md). It receives ONLY the
   artifact directory and the SC criteria — no orchestrator context, no
   expected outcomes, no cached results — reads `session.yaml` as the PRIMARY
   source, writes `evaluation-<timestamp>.yaml` into the artifact directory,
   and returns the YAML verdict record. "Artifact generated" is NEVER a valid
   PASS verdict for a behavioral SC.
6. **Two-SC pattern.** Artifact generation (run, produce `session.yaml`) and
   clean-room evaluation (separate sub-agent reads the artifacts) are separate
   SCs and separate dispatches — never merged.
7. **Prompts are real-domain tasks.** Interview/prose-recall prompts are a
   hard FAIL (§11).
8. **Default model is single-sourced.** `DEFAULT_TEST_MODEL` in
   `default-model.sh` runs every test; model-shopping is prohibited (R-20,
   §10.6). Remediation targets the defect classes, never model selection.
8a. **Pre-supplied environment.** The harness pre-supplies everything the
   scenario's task needs — deck-mandated CLIs baked into the image,
   authenticated remote, bootstrapped store, seeded credentials/env
   (tests-v2/AGENTS.md §3a). Run time spent on environment discovery
   (finding CLIs, reverse-engineering APIs, deriving auth shapes,
   discovering store layout) is a harness/scenario defect to fix at the
   fixture/image layer — never model behavior, never prompt-tolerated.
 9. **Supervise every run — 60-second poll cycle, update follows the poll's reminder mid-flow.**
    Launch the run in background. **The supervision cycle is ONE continuous
    loop, never a pair of alternating turns: (1) a tool call — `sleep 60`, then
    `.opencode/tests-v2/poll-run.sh
    <pinned-session-db> <poll#>` — whose output ENDS WITH THE REMINDER to
    deliver the analysis in chat (the poll script prints it); (2) immediately
    after, the analysis is delivered as an in-chat text update — plain text,
    NO tool call attached to the analysis — and then the loop CONTINUES with
    the next poll call in the same working flow.** The update is mid-flow,
    never a stopping point: ending the turn after the update — yielding to the
    operator mid-run, waiting for a nudge — is itself the supervision defect
    (observed 2026-10-20, #2647 family: the "two turns" wording read as
    turn-terminal and the supervisor stopped twice; the developer had to
    prompt "why did you stop?" both times). The reminder block in the poll
    output is the trigger; never chain another tool call before delivering the
    update. **The 60-second cycle is absolute — no longer sleeps (240s/300s+)
   between polls, ever (observed defect, #2570). Never pipe, grep, head, tail,
   or otherwise filter or truncate the poll output — the trailing reminder is
   the update trigger, and filtering it out silently suppresses the update
   turn (observed defect, #2570: a `grep | head` poll invocation dropped the
   reminder and produced a run of bare bash calls with zero in-chat updates).**
   **This mandate binds ANY operation under the agent's active supervision in a
   working turn — model runs and background jobs (reindex, export, migration)
   alike, with no duration or operation-kind qualifier (observed defect,
   #2619: a reindex was policed at escalating 90–270s intervals with updates
   riding in tool outputs).** Within the bound scope the 60-second interval is
   a **ceiling, not a target** — it never escalates while the supervised
   operation is pending. The per-poll in-chat text update is **unconditional**:
   a poll with no new evidence still delivers its update — "no change" stated
   plainly is the update (the developer cannot read tool outputs or agent
   reasoning; an unreported interval is invisible time).
   **The update is the cycle's structural step (.opencode#2678):** a
   supervised cycle advances exactly tool call (sleep + poll) → standalone
   text update (no tool call attached) → next tool call — a tool call
   directly following another tool call of the same supervised cycle, with no
   intervening text update in between, is the defect in the supervisor's own
   transcript, regardless of what the analysis concluded and regardless of
   content; the skipped-update failure is self-observable in that shape.
   **The update is a STANDALONE turn (developer directive 2026-10-30, wording
   r2 2026-10-31):** the analysis text is issued in a turn with no tool call
   attached — never as prose preceding the next poll call in the same
   message. The transcript shapes, concretely:
   - BAD: one message carrying prose + the next `sleep`/`poll-run.sh` tool
     call (or any other tool call) — the analysis in it is undelivered.
   - GOOD: turn A — the poll tool call, alone (its sleep is **60 seconds —
     never longer**; the ≤60 s cadence floor is .opencode#2557); turn B —
     only the analysis text, opening `POLL <n>`; turn C — the next poll
     tool call (sleep 60 again).
   This binds EVERY supervised polling loop, not only behavioral runs —
   structural suite supervision (e.g. watching `test-enforcement.sh`
   progress) uses the same turn shapes even when `poll-run.sh` is not the
   polling instrument, because the reminder text cannot fire there; the
   card clause is the anchor in that case. Tool-call turns collapse in the
   developer's UI to the bare
   command line, so an analysis riding in the same message as a tool call
   never reaches the developer; an update delivered inside a tool-call turn
   is an undelivered update, whatever the supervisor's own transcript shows
   — this riding form is the recurring regression the rule names.
   **Never kill by name pattern.** Run cleanup and abort kill only the PIDs the
   agent itself launched — record the PID at launch and re-verify survivors by
   PID (`kill -9 <pid>`, `ps -p <pid>`), never by a name match. A pattern kill
   (`pkill -9 -f opencode`, or any pattern broad enough to match unrelated
   processes) kills every matching process on the machine — observed
   2026-10-11: a cleanup pass pattern-matched `opencode` and terminated the
   developer's main opencode session mid-work. Scoped diagnosis greps are fine;
   kill signals are PID-addressed only.
   The supervision loop is continuous — it does NOT yield to the
   developer between polls; mid-cycle yielding exits the loop and is the
   defect corrected in #2561. The cycle ends only when monitoring is
   conclusive: run completion, a handled hard-abort signal, the
   evidence-sufficiency early exit, or the verdict-confirmed conclusion
   (below). The developer's UI
   collapses Shell calls to bare command lines, so tool results, echo-carried
   updates, and text riding in tool-call turns all fail to surface (verified
   live, #2557; the standalone text turn is the only delivery that works). The
    update states: what the run agent is doing right now, what it intends next,
    whether that serves the scenario's goal, and which hard-abort signals (§14)
    have fired — read from the agent's actual words and work, not counters.
    **One update per poll — hard mandate, gap = boundary violation (.opencode#2683
    developer directive, 2026-10-29, strengthened ×2 after repeated
    regressions):** every poll invocation — natural, empty, errored, or
    aborted mid-call (including a developer interrupt killing the sleep/poll
    call) — is followed by its own standalone in-chat text update before ANY
    next tool call, opening with `POLL <n>`. On interruption, the
    interrupted poll's update is reconstructed in the SAME turn from the
    live session DB (a direct sqlite/timeline read) and delivered first —
    the supervisor never leaves a poll number unaccounted for: the
    transcript must read poll(1) report(1) … report(N-1) report(N) for every
    N dispatched. This is not a style preference: a poll tool call followed
    by another tool call with no intervening text update is a boundary
    violation in the supervision record, self-observable in the
    transcript's shape, to be reported even when discovered after the
    fact. The update text comes BEFORE the next poll call, never chained
    inside a tool call, never folded into tool output; filtering or
    truncating poll output (which suppresses the update trigger) is itself
    a supervision defect (#2570).
   **The loop is CONTINUOUS until conclusive (#2561 developer correction):
   never yield to the developer mid-cycle — a poll cycle ends only when the
   run is conclusive (run completion, a fired hard-abort signal handled, the
   evidence-sufficiency early exit, or the verdict-confirmed conclusion), not
   on a schedule or after each
   update. The per-poll sequence is: poll tool call → analyze its evidence →
   report in chat → next poll tool call, repeating inside the working turn.**
   **Verdict-confirmed conclusion — MANDATORY, same cycle (.opencode#2594).**
   When a poll's semantic check confirms the SC's verdict state — **green**
   (the scenario's goal condition observed met in the run agent's actual
   words and work) or **red** (the goal condition observed failed, or a
   run-fatal defect observed) — the supervisor MUST conclude the run in that
   same cycle: PID-addressed kill of the run process tree (re-verify gone by
   PID), §10.5 export when the artifact set is incomplete, and a recorded
   confirmation in the evidence directory naming the confirming poll, the
   event citations, and the verdict state — then proceed to evaluation.
   Polling past the confirming poll is a supervision defect: once the
   outcome is known, further cycles cannot change the verdict and are waste
   by definition (observed defect, #2594: green confirmed at poll 47, polls
   continued through 50). Post-confirmation tail hygiene by the run agent is
   not evidence — do not wait for it. This trigger is stronger than the
   evidence-sufficiency early exit (#2538): sufficiency judges value;
   verdict-confirmed is mandatory once the outcome is known. The
   confirmation judgment is intent-decidable — judgment on the event
   stream, never a scripted pattern match; the post-confirmation actions are
   mechanical.
    **Keep the todo list current with the run's state** — it renders
   persistently between updates. **Pin the polled DB to the active run's test
   home** (env-passed path, not newest-by-mtime): a zombie run from a prior
   kill can outlive its supervisor and pollute mtime-based selection — kill
   survivors with `kill -9` by PID and re-verify with `pgrep`. Activity or
   uptime proxies are INADMISSIBLE as the check; counters alone are not a
   finding. **When the DB is flat, distinguish generating from stalled by
   inference-load evidence — GPU utilization (`nvidia-smi`) and `ollama ps`:
   a busy GPU is generation in progress; an idle GPU with a flat DB is a
   stall signal. **Layered hang diagnosis (`.opencode#2547`): a hang verdict
   requires converging signals — session-DB flatness, WAL-growth stall, GPU
   utilization, and the ollama service log (`journalctl -u ollama`) — never a
   single one: a frozen WAL has a legitimate post-smoke steady state, and the
   server log is the tiebreaker (active `n_gen`/task activity in
   `journalctl -u ollama` means the run is generating regardless of
   client-side flatness). A server restart or error in the service log during
   a run marks the run environment-suspect: abort by PID, export, diagnose —
   never blind retry. Read-only host checks (`journalctl -u ollama`,
   `nvidia-smi`) are sanctioned per-poll supervision surfaces (developer
   direction, 2026-10-14); no host-state mutation. Abort completeness: after
   any run kill, enumerate survivors by recorded-PID descendants AND by
   test-home environment (a command-line check misses env-only carriers —
   observed orphan), kill them, and verify zero before proceeding. Orchestrated
   SC-verification runs launch with `BEHAVIOR_SEMANTIC_MONITOR=1` so
   determination records exist — a resume is permitted only when the record
   carries a non-undetermined classification or a valid recorded orchestrator
   decision, and a run whose record carries neither cannot resume through the
   §10.7 path (SC-8 determination gate).**
   **Cadence and gap claims are computed, never estimated:** record the nested
   run's launch time and every poll time, and derive any cadence or gap
   statement from those recorded timestamps — an assertion of compliance (or a
   "no gap" framing) built from an elapsed-time impression is a fabricated
   finding. If the run completed before the first poll, state that plainly,
   take the early-exit path, and report the actual timeline. **No blocking
   action longer than 60 s starts while a run is active** —
   dispatch clean-room evaluations at run boundaries (after the run ends),
   never mid-run. Abort on the hard-abort signals and record the diagnosis in
   the next update. **Early exit on evidence sufficiency (#2538):** when a
   poll's judgment finds the SC's evidence surface already complete and
   further running adds no value, conclude the run — kill, export per §10.5,
   record the sufficiency judgment, and proceed to evaluation. Waiting out a
   run whose evidence is captured burns inference for nothing. Whether the
   evidence surface is complete is a judgment call — never scripted. **Verdict
   for ceremony-escalation aborts:** a run aborted for ceremony escalation
   (self-inflicted detours — summoned machinery, tooling debugging, store
   initialization — the task never requires) whose root cause traces to deck
   wording is a **FAIL** verdict, remediated by the easy deck correction, and
   the scenario re-runs — never reclassified as inconclusive or worked around
   in the prompt.
10. **Timeouts and recovery.** Bash-tool timeout ≥ 600000 ms; on timeout,
    session resumption (`--continue`/`--session`) is the first-line recovery
    (§10.7); the §10 remediation paths replace model excuses and blind retries.
11. **Remote API tests are self-contained.** A behavioral SC requiring real
    remote API behavior opts into the harness's provisioned GitBucket container
    (`BEHAVIOR_NEEDS_REMOTE`; mechanics in tests-v2 §12) — no external server,
    no mock stand-in by default. For scenarios needing real **GitHub**-side
    repo targets, use the designated throwaway test repos (`test-submodule-1`,
    `test-submodule-2`) in the authenticated owner's namespace — owner
    resolution is deployment-local, never hardcoded — and never target
    production repos (developer direction, 2026-10-14).

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
