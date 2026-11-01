---
name: skill-creator
description: "Load before creating or editing ANY file under skills/, guidelines/, or floor.md — including adding or removing a rule, skill, artifact, or enforcement mechanism anywhere in the deck. Also load when writing or revising skill descriptions, or when deck content is found missing, stale, or conflicting. Enforces the admission gate, retirement gate, predicate classification, and vendor-card boundary. This card governs the deck itself."
license: MIT
provenance: AI-authored, .opencode#2490; .opencode#1925; instruction-stated-detail-sourcing clause, #2657 (harness-as-placement-ground-truth observed 2026-10-31)
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; .opencode#1925 -->

# skill-creator — deck governance

**Every deck edit passes this gate first.** The deck mutates through process,
not through casual edits — the historical record shows ~27,700 ungoverned
edits produced the doom loop this deck replaced.

## Admission gate — a new rule/skill/artifact enters only with ALL of:

1. **Observed failure** — a named incident or measured pattern, with evidence
   (session record, issue, database finding). No hypothetical failures.
2. **Consumer** — what reads or executes it, and when.
3. **Mechanism or trigger** — a skill-description trigger or a
   fact-decidable enforcement point.
4. **Predicate classification** — fact-decidable (scripts allowed: file
   exists, token in diff, tests pass) vs intent-decidable (scripts FORBIDDEN —
   judgment decides). Static checks on intent are the deck's founding defect.
5. **Domain match** — a protocol or paper adopted from another domain requires
   evidence in THIS domain (the DiMo lesson).
6. **Root-agnostic** — zero root-repo names or absolute paths; per-root facts
   arrive via session-init.
7. **What it replaces** — an admission that adds without retiring grows the
   deck; name the displaced content or justify the net-zero.
8. **Always-loaded surface discipline** — content enters `floor.md` or any
   always-injected file only if it must be visible **before any card
   dispatch** (definitions the proceed-or-halt decision depends on). Worked
   examples, stage mandates, and card-scoped directives are card-level; each
   slip fattens every session, and the slips add up.

## Developer-instruction carve-out

A **developer-directed** deck edit — one the developer explicitly requested in
the session — carries its own observed-failure evidence and authorization; the
gate governs agent-proposed deck content, not instruction execution. The gate's
standards still bind the *content* of what is written (frontmatter, predicate
classification, root-agnostic discipline hold), but the proposal-time evidence
hunt does not re-run at instruction-execution time: the agent never performs
archaeology to manufacture evidence for an edit the developer just directed,
whether or not that edit's content leaves a material open choice.

The no-halt clause is bounded. When a directed edit's content leaves a
material open choice, the agent asks one open-ended question about that
choice instead of choosing it. A detail the instruction already states —
which card, which numbered position, which file, which form — is not an open
choice, and not a research question either: its facts come from the
instruction alone. The test harness's own scripts, another issue's records,
and the deck's history are not sources for an instruction-stated detail —
reading them to decide a placement the instruction resolved converts the
hunt into the archaeology and the halt above (observed 2026-10-31,
.opencode#2657: a directed "add rule 6" edit whose instruction stated the
position drew the placement question twice more, the second time
"harvesting" the behavioral scenario script as the placement's ground
truth). The agent executes the stated detail as instructed, and a question
about it is the
halt the no-halt clause forbids (the directive is the edit's evidence, per
the exemption above; observed 2026-10-30, .opencode#2657: a directed
"add rule 6" edit whose instruction stated the position drew a history hunt
and a positioning question). That question is this card's stage output: the
deck-governance card is the gate for a deck edit, so the question is not a
step toward the full path. Neither clause of the carve-out reaches a request
that names a stage — the `work` card's stage rule governs such a request
instead, and the named stage runs before the edit.

## Card standards

- Frontmatter: `name`, `description`, `license`; provenance line.
- **Descriptions are the router**: state what the skill does AND when to load
  it, at both abstraction levels (domain framing + implementation framing —
  "before any code that contacts GitHub" catches what "GitHub operations"
  misses), deliberately pushy (agents undertrigger). **No user-phrase
  matching anywhere** — the floor's vocabulary table defines utterance
  meanings; descriptions match agent intent.
- Bodies stay lean; details go one level deep in `references/`.
- No TDTs, no dispatch-gate boilerplate, no artifact chains, no numeric size
  targets.

## Agent-facing cross-references

When deck prose points an agent at content in another deck file, use the
canonical form `Read [Text](path)`: bracketed descriptive text naming the
target content in place of `Text`, and a deck-relative path in place of
`path`. The link is a load directive, not a citation — it instructs the
reading agent to load the target. Other forms (`See `file.md``, bare `§N`,
bare file names, `Load [...]`) are nonconforming.
`./.opencode/tools/reference-integrity` validates that every such link
resolves. Forwards-only: existing content converts when touched.

## Retirement gate

Content with lost provenance (no consumer/trigger), a declining usage trend
across deployments, or structural obsolescence is retired. Absence in a live
database is NOT evidence — retention vacuums delete history; verdicts use
deep history. Resurrection via git history is cheap; hoarding is not.

## Vendor-card boundary

Vendor-generated cards (e.g. `hf skills add`) are referenced and regenerated
by their owning tool — never hand-edited. Card origins: deck-authored
(governed) / vendor-generated / project-local.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
