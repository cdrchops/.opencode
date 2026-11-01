---
name: plan
description: "Load when writing an implementation plan from an approved spec — per-SC items with RED/GREEN cycles, dependency ordering, verification instruments. Plans derive entirely from the spec: a plan item without a spec source is scope creep. Plans state how to implement; implementation status lives in pipeline state, never in the plan body."
license: MIT
provenance: AI-authored, .opencode#2490; recomposition supersession, .opencode#2661; single-sourcing discipline, .opencode#2660
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; #2550 consume-validated-specs mandate; #2557 language/tool call out; route-to-repair clause, .opencode#2597; validation dispatch, .opencode#2601; recomposition supersession, .opencode#2661 -->

# plan — implementation planning

1. **One item per SC.** Each item states: deliverable, RED (the failing
   assertion, written against current behavior), GREEN (the change), and the
   verification instrument (a check the agent can run — never prose recall).
2. **Load the cards in scope.** Identify the languages and build tools the
   plan's items touch and load their cards (where cards exist), and load
   `programming-principles` for the engineering-principles layer — conventions
   and packaging expectations shape item decomposition and per-item
   verification.
3. **Dependency order.** Sequence items so each RED/GREEN cycle builds on
   verified prior state. Needs-based sizing: no padding items, no filler.
4. **Derivation guard.** Every item traces to an SC. Untraceable items are
   removed, not justified.
5. **No status tracking in the body** — no STATUS fields, completion markers,
   or progress indicators. State lives in the pipeline, not the plan. The
   plan's artifact discipline holds the single-sourcing parallel: the plan
   states each operative fact once, in the item or section that owns it —
   ordering facts in the dependency order, rules in the items, checks in the
   instruments, measured history deferred to the issue's validation record
   where the record rule applies — and every other mention points at its
   owner.
6. **Consume validated specs only.** Plan items trace to the spec's SCs.
   Before planning, judge each SC against
   [the validation standards](../spec/references/validation-standards.md)
   defect
   classes — reviewer judgment, never pattern matching. A defective or
   ambiguous criterion produces BLOCKED naming the criterion and the defect;
   the plan never routes around a defective criterion and never reinterprets
   it to make it plannable. When the spec's local record is absent, the plan
   consumes it only after the `issues` card's mirror-repair — the route runs
   through that repair before the plan work proceeds.
7. **Validate before implement.** On the full path, before `implement`
   consumes the plan, the plan passes one validation dispatch: the writer
   first applies
   [the plan validation standards](references/plan-validation-standards.md)
   to the completed draft in their own context and remediates what they
   find — a duty-of-care pass that spends the fresh-context dispatch on
   judgment-level defects rather than mechanical-consistency ones; it never
   replaces the dispatch, and a self-passed verdict is no verdict. Then a
   reviewer with no prior context on the plan reads it against the same
   reference and returns PASS or FAIL. On FAIL, revise the named findings in
   place and re-validate; the loop repeats until a zero-finding verdict, per
   the reference's loop section. A change on the short path — the path
   [the change gate](../work/SKILL.md) defines — produces no plan and runs no
   dispatch.
8. Plans wait for the developer's authorization before `implement` when the
   scope requires it; a change on the short path executes directly under the
   [change gate](../work/SKILL.md). A terminal-stage approval (`approved for
   pr`, `approved for implementation`, …) from the vocabulary in `floor.md`
   carries the item through plan into implement — the stage is not re-asked.
9. **Deprecation encounters at planning time.** Items touching a witnessed
   deprecation follow [the deprecation encounter protocol](../guidelines/deprecation-encounter-protocol.md):
   items never build new code on deprecated surface; an in-passing drop-in
   swap rides inside the item it already belongs to; a load-bearing
   deprecation surfaces as the spec's temporary-use exception — the plan's
   implementable content is unchanged, and an encounter never adds plan items.
10. **Recomposition supersession.** At a recomposition (the issues card's
    protocol) a plan derived from the pre-split spec is superseded: new
    plans derive from the parts' specs; delivered items keep their delivered
    state in the work's implementation history, and plan state never
    migrates to the parts.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
