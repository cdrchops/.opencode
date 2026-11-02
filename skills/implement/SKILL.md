---
name: implement
description: "Load when executing an approved plan or making any change during the implementation work cycle — before starting work and before every mid-cycle change. Loads the implementation-workflow reference first (pre-implementation checklist, RED/GREEN chain, post-implementation gates). Run tests and show real output as evidence; use the project's connectors, libraries, and test frameworks from the floor inventory — bespoke reimplementation of what a library provides is a defect. Also load when implementation effort balloons into deep verification of a consumed framework's internals, verification tests of what the build system already guarantees, or methodology-only narration."
license: MIT
provenance: AI-authored, .opencode#2490; short-path inline default, .opencode#2645; docs-currentness pointer, .opencode#2670
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; #582 yaml-contract-format convention; #2550 SC-fidelity mandate; #2557 language/tool call out; #2551 consumables effort bound, fabricated-tests offender classes, narration-to-deliverable bound; test-quality + reverse drift, .opencode#2601; short-path inline default, .opencode#2645; docs-currentness pointer, .opencode#2670 -->

# implement — executing the work

1. **Read [the implementation-workflow reference](references/implementation-workflow.md)
   first** — at cycle start and again before any mid-cycle change.
2. **Load the cards in scope before any code is written.** Identify the
   languages and build tools the files about to be modified belong to and load
   their cards (where cards exist), and load `programming-principles` for the
   engineering-principles layer — the load happens before the first code
   modification, not after the first defect. The docs-currentness step in
   [the implementation-workflow reference](references/implementation-workflow.md)
   is part of this pre-implementation work.
3. **Per item: RED → GREEN → verify → commit.** Each RED is confirmed
   failing for the stated reason before its GREEN begins, and multi-item
   work runs per-item cycles — never batch RED then batch GREEN, which
   severs the failing state each GREEN is measured against.
   - RED: write or run the failing assertion; confirm it fails for the stated
     reason.
   - GREEN: the minimal change that turns it green — no speculative additions.
   - Verify: run the check; the output itself is the evidence. Never assert
     success without an executed check.
   - Test tiers: smoke + regression are the default for every cycle and PR —
     never the full suite (tier definitions in the implementation-workflow
     reference). Full-suite runs are for release boundaries or explicit
     developer request.
4. **Mid-cycle changes.** Re-consult the workflow reference first. A change
   beyond the current plan item's scope stops the cycle: report and get
   direction rather than expand silently.
5. **Library-first.** Check the floor's external-access inventory and the
   project's own frameworks before writing anything bespoke — connectors,
   official clients, and built-in credential handling replace hand-rolled
   equivalents.
6. **Consumables bound.** A consumed framework or dependency — anything the
   build tool bundles and provides — is implemented against its documented
   API at the declared version: one docs pass, and the resolved version is
   recorded. Deeper internals verification — bytecode disassembly,
   source-JAR extraction, dependency-internal tracing, API-migration
   archaeology beyond the migration docs — requires per-occurrence developer
   instruction; never self-directed diligence.
7. **Test value.** Tests assert behavior, are insensitive to internal
   structure, and cost less to write than the code under test warrants.
   Never test an artifact the build system already guarantees. The tests
   written for an item cover the edge cases and error conditions relevant
   to that item's behavior — the failure shapes the item's own analysis
   points at — and where the change crosses a module boundary, at least one
   assertion crosses that boundary rather than testing both sides in
   isolation. An assertion's expected value never changes without the
   asserted behavior changing: a test edited to expect the new output while
   the behavior it named did not change is a weakened assertion, not a
   passing one. Offender
   classes — each reads as verification while asserting nothing the
   application owns: (a) source-content inspection of the agent's own files
   ("does this file contain this string"); (b) environment/framework re-read
   tautologies (re-reading a pinned property, re-running a tool to confirm
   the tool does what it says); (c) assertion-shaped placeholders (assertion
   syntax over a body with no behavior under test). RED/GREEN evidence drawn
   from these classes is fabricated — replace it with a behavioral assertion.
8. **Narration-to-deliverable bound.** When a work cycle accumulates
   methodology-only turns — visible scaffolding, dumps, hypothesis chains
   producing zero deliverable code — beyond a small handful, stop: surface
   the narration-to-deliverable ratio and halt for direction with an
   open-ended clarification request per the floor's standing formula.
   Unbounded self-directed exploration is not diligence.
9. **Sub-agents are judgment, not ritual.** Dispatch one when a scoped task
   genuinely benefits; work inline when that is simply better. Dispatched work
   gets a clean-room prompt and a result back (YAML) — no chain theater.
   **Short-path inline default.** For short-path work — developer-specified
   small changes with no success-criteria machinery — the default is working
   inline in the agent's own context; a sub-agent dispatch for short-path
   work requires a scoped reason recorded in the work state.
10. **SC fidelity.** Implementation satisfies each criterion as written — no
    weakening, skipping, deferring, or reinterpreting a criterion to make it
    passable. Fidelity runs in both directions: the implementation adds no
    deliverable the spec or plan does not state, leaves no spec-required
    surface missing, and matches every interface contract the spec or plan
    states as written — a signature, command shape, flag, or other declared
    contract that is present but diverges from what was stated is a finding.
    Drift in any direction is reported — BLOCKED or a reported defect —
    never silently absorbed or silently added. An unimplementable criterion
    produces BLOCKED with the root
    cause; the criterion itself is never modified to admit the implementation.
11. **Behavioral evidence goes through the harness.** Evidence for a behavioral
   SC is produced only by the `tests-v2` behavioral harness — load the
   `behavioral-testing` card first and read
   `.opencode/tests-v2/AGENTS.md` as its step 1 requires (`with-test-home` +
   `behavior_run`, artifact + clean-room evaluation, 60-second supervision
   cycle). An ad-hoc `opencode run` is not behavioral
   evidence.
12. **Workflow fidelity.** Every step of the pre-implementation checklist, the
    RED/GREEN chain, and the post-implementation gates — including steps
    defined in the implementation-workflow reference — runs in order. A step
    that appears redundant or unnecessary is not grounds to skip, compress,
    reorder, or defer it; the cost of an extra step is negligible against the
    cost of a skipped one. A step that cannot complete stops the cycle per the
    reference's escalation rule — never silently omitted.

13. **Deprecation encounters.** A deprecation witnessed in the current
    environment (annotation, doc notice, changelog entry, compiler/linter
    warning, live research with sources) is an encounter, not ignorable noise.
    New code never builds on deprecated surface; a drop-in replacement inside
    code the change is already rewriting swaps in-passing — no ceremony; a
    load-bearing deprecation with no route around takes the temporary-use
    exception path (ticket + spec carve-out + escalation); everything else
    files or appends to a `[BITROT]` ticket via a sub-agent. Full protocol:
    [the deprecation encounter protocol](../guidelines/deprecation-encounter-protocol.md).

**Agent-to-agent format:** structured data one agent creates for another — or
ingests from another — defaults to YAML, marked by the bare `(YAML)` token at
each reference; tool I/O, CLI output, and external configuration keep their
native format; chat prose carries no token.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
