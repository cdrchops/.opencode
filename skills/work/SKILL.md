---
name: work
description: "Load before any file modification, branch creation, or implementation start in any repo. Routes every change through spec → plan → implement → PR — the short path when the change meets the short-path criteria stated in this card, the full path otherwise — and checks authorization at each stage boundary. Load when the developer's request names a stage — a spec, a plan, a discussion, or approval before implementation: that stage runs before implementing. Also load when unsure which stage applies: halt with an open-ended clarification request rather than guess — that is, when the request does not say what to build at all."
license: MIT
provenance: AI-authored, .opencode#2490; #2525 pipeline continuation; recomposition void, .opencode#2661; #2657 path selection, criteria set, and work record; criterion-assessment binding, #2657 (RC-2 self-certification observed in two runs of 2026-10-31)
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; #2525 pipeline continuation on terminal authorization; recomposition void in the authorization check, .opencode#2661; #2657 path selection, criteria set, and work record; criterion-assessment binding, #2657 (RC-2 observed in two runs of 2026-10-31) -->

# work — the change gate

Consult before touching files.

1. **Path selection (judgment, not thresholds).** Two inputs decide the path,
   in this order. A stated stage request decides it outright: when the
   developer's request names a stage — a spec, a plan, a discussion, or
   approval before implementation — that stage runs before any
   implementation, whatever the change's size, and the agent's judgment of the
   change's size never overrides it. Otherwise the change's need decides it,
   by the criteria below. The criteria are assessed before implementation
   begins, on the developer's request and the agent's own understanding of the
   change it describes; what the work turns out to need is the short path's
   end, below.

   **Short-path criteria — every one holds, or the change takes the full
   path:**
   1. the request names no stage;
   2. the change touches one file;
   3. the request leaves no material choice open about what to build, and the
      agent supplies no product decision the developer did not state;
   4. the change's completion is decidable from the request's own statement —
      the file now contains what the request said — with no acceptance
      criterion, test, or evaluation the developer did not state;
   5. the change alters no credential, authentication or authorization check,
      dependency, or deployment surface;
   6. the change touches no surface the developer did not name.

   A failed criterion — and the agent's uncertainty about one — sends the
   change to the full path. The assessment binds: once the work's own facts
   have established a criterion's outcome — a second file the change needs, a
   second concern, an unnamed surface — the finding stands; redefining the
   change (restricting its files, concerns, or scope) so a found failure
   reads as a pass is self-certification, and takes the full path the same
   as the failure does. These criteria are the definition of the short
   path; no other card states a competing one. One exception: for a
   developer-directed edit to this deck whose content leaves a material open
   choice, the agent asks one question in the deck-governance card instead of
   taking the full path.

   - *Short path*: a request that names no stage and meets every criterion
     above — a trivial fix, a typo, a config tweak — verified at PR review.
   - *Full path*: everything else — a feature, a multi-part change, anything
     with success criteria; spec before code.

   **The short path ends when the work outgrows it.** When the work acquires
   a second file, a second concern, a derived success criterion, a product
   decision the developer did not state, or a surface the request did not
   name, the agent extends the scope statement in the work record with the
   expanded scope, re-applies these criteria, and takes the full path from
   the earliest missing stage — producing that stage's artifact — before any
   further implementation edit.

   **No ceremony, and no waived stage.** The agent performs no evidence hunt,
   archaeology, or card load the developer's instruction already satisfied,
   and the agent does not re-ask for what the instruction carries. The agent
   waives no stage on either path: on the short path a stage's artifact takes
   the collapsed form rule 4 names, and a missing artifact is produced
   cheaply; on the full path each stage produces its own artifact.
2. **A stated stage request is not a specification.** It requests the
   pipeline. It does not satisfy the spec stage, and the stage it names runs
   before any implementation it also directs. A request that names no stage
   and names what to build may serve as the short path's scope — subject to
   rule 1.
3. **Authorization check.** The vocabulary in `floor.md` defines authorization.
   Without authorization at the required scope, the agent prepares the
   spec/proposal and stops at the boundary. A question, complaint, or
   confirmation is not authorization. A developer's directive satisfies a
   stage's content; it never suppresses a stage — no directive, however
   emphatic and however small the change, removes a stage from the pipeline.
   A recomposition voids any implementation or PR authorization carried for
   the pre-split scope — the parts wait for the authorization the developer
   states at split time; Read [the issues skill](../issues/SKILL.md).
4. **The work record and the scope statement.** Every change records its path
   and scope before implementation.
   - **The work record** is one file in the repository's own git directory —
     the path `git rev-parse --git-path work-record.md` reports — which is
     not a working-tree path, so the record never appears in the repository's
     status and needs no ignore-rule entry. It is scratch: the agent never
     commits it, and the cleanup card removes it. It holds two parts.
   - **The provenance** — the verified trunk tip, which the
     `git-workflow-branch` card writes at its trunk-freshness step, before
     the branch exists, and the branch, the base tip, and the issue where
     one exists, which the same card records alongside that tip at its
     provenance step once the branch exists.
   - **The scope statement** — the path taken, the criteria that selected it,
     what changes, what "done" is checked against, what is out of scope, the
     order of the work, and any reason a card requires recorded for a
     departure from a default — the agent writes before the first edit. On
     the full path the spec artifact carries the scope and the scope
     statement points at it; on the short path the scope statement is the
     spec artifact itself, discharging the spec and plan stages together for
     a one-file change whose completion the request has decided.

   The check that "done" is verified against is the criterion the `verify`
   card's fresh-context reviewer measures the scope statement against, and
   the verdict unit on the short path; this card is that statement's criteria
   reference. The developer's work order is the authorization for the
   implementation the scope describes: the agent records the scope and does
   not ask the developer to approve it again. A developer who wants to
   approve the scope before implementation asks for that stage, and rule 1
   routes the request to the full path.
5. **Route.**
   - Short: `git-workflow-branch` → `implement` → `verify` → `git-workflow-pr`
   - Full: `explore` → `spec` → developer approval → `plan` → `implement` →
     `verify` → `git-workflow-pr`
6. **Boundaries.** Spec approval, plan approval, and merge are human gates —
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
   the pipeline exists to produce. **The missing-artifact clause applies to a
   change on the full path:** on the short path the scope statement is the
   spec artifact, and the short path reaches the verify and PR-readiness
   gates with it.
7. **Deprecation encounters.** A deprecation witnessed during the change is
   triaged per [the deprecation encounter protocol](../guidelines/deprecation-encounter-protocol.md)
   — new code never builds on deprecated surface; the encounter-carrying
   cards (implement, programming-principles, research, systematic-debugging,
   spec, plan) hold the domain slices.

Unsure which path fits? That is a request that does not say what to build at
all — the agent halts with an open-ended clarification request. A request
that says what to build but leaves a material open choice takes the full
path; a failed criterion is not a reason to halt.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
