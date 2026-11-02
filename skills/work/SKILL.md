---
name: work
description: "Load before any file modification, branch creation, or implementation start in any repo. Routes every change through spec → plan → implement → PR scaled to the change's need — trivial fixes take the short path, multi-part features take the full path — and checks authorization at each stage boundary. Also load when unsure which stage applies: halt with an open-ended clarification request rather than guess."
license: MIT
provenance: AI-authored, .opencode#2490; #2525 pipeline continuation; recomposition void, .opencode#2661
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; #2525 pipeline continuation on terminal authorization; recomposition void in the authorization check, .opencode#2661 -->

# work — the change gate

Consult before touching files.

1. **Path selection (judgment, not thresholds).** What does this change need?
   - *Short path*: single-file fix, typo, config tweak — the developer's request
     itself is the spec; it is verified at PR review.
   - *Full path*: feature, multi-part change, anything with success criteria —
     spec before code.
   The short path is the **default** for single-file, developer-specified
   changes — a developer's direct request is the spec; machinery beyond the
   short path (extra card loads, evidence hunts, approval-seeking) requires a
   reason visible in the work record. Excess ceremony is a within-stage
   defect signal, never thoroughness — it never licenses crossing the
   authorization boundary (the floor's vocabulary governs that boundary).
2. **Authorization check.** The vocabulary in `floor.md` defines authorization.
   No authorization at the required scope → prepare the spec/proposal and stop
   at the boundary. A question, complaint, or confirmation is not authorization.
   A recomposition voids any implementation or PR authorization carried for
   the pre-split scope — the parts wait for the authorization the developer
   states at split time; Read [the issues skill](../issues/SKILL.md).
3. **Route.**
   - Short: `git-workflow-branch` → `implement` → `verify` → `git-workflow-pr`
   - Full: `explore` → `spec` → developer approval → `plan` → `implement` →
     `verify` → `git-workflow-pr`
4. **Boundaries.** Spec approval, plan approval, and merge are human gates —
   and a developer-issued terminal-stage approval (`approved for pr`,
   `approved for implementation`, …) *is* that human gate for the upstream
   stages it carries, per the vocabulary in `floor.md`. It authorizes the
   item through every phase up to and including the named one; only merge
   remains human-only unconditionally. The pipeline-start rule applies only
   under an existing scope-bearing authorization from the floor's vocabulary;
   missing upstream artifacts (no spec, plan, or branch yet) trigger the
   pipeline itself, from the earliest missing stage, under that granted
   authorization — the rule runs the pipeline; it does not itself grant a
   stage. A stage boundary reached without a scope-bearing token is
   a halt, not an ambiguity — halt for authorization only on genuine
   ambiguity over which stage an existing token names. Downstream card
   gates (e.g. PR readiness) are reached by running the pipeline under
   authorization — they are never reasons to halt; the artifacts the gate checks are what
   the pipeline exists to produce.
5. **Deprecation encounters.** A deprecation witnessed during the change is
   triaged per [the deprecation encounter protocol](../guidelines/deprecation-encounter-protocol.md)
   — new code never builds on deprecated surface; the encounter-carrying
   cards (implement, programming-principles, research, systematic-debugging,
   spec, plan) hold the domain slices.

Unsure which path fits? Halt with an open-ended clarification request.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
