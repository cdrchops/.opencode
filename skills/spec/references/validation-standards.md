<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2550; criteria-depth restoration, .opencode#2601; spin-bounded loop, .opencode#2606; state-decidability class, .opencode#2646; non-convergence judgment, count trigger, re-evaluation outcomes, finding bar, validation record, .opencode#2660 -->

# Validation Standards

Criteria set for the spec card's validation dispatch — one fresh-context
reviewer reads a spec against this page and returns PASS or FAIL. These are
defect descriptions for reviewer judgment, not patterns to scan for: there are
no keyword lists, no trigger-word tables, and no scripted checks here. A
lexical check is gamed by rephrasing; judgment is not.

## Verdict contract

- **PASS** — the reviewer reports zero findings, and no caveat, concern, or
  note is attached to any criterion's verdict. A PASS with any disclosed
  observation is not a verdict.
- **FAIL** — any reported finding produces FAIL: an enumerated defect class
  below, or any other correction, imprecision, factual error, or gap affecting
  the artifact's correctness or its stated requirements. The verdict names
  each finding and its ground. A FAIL without named findings is not a verdict.
- **Findings are what the reviewer reports.** A substantive observation about
  the artifact is always reported as a finding — the non-finding-note
  disclosure path does not exist.
- The reviewer reports only findings affecting correctness or the stated
  requirements — the same anti-churn binding as the verify card's reviewer.
  Style preferences, phrasing taste, and hypothetical improvements are not
  findings. Where the audited artifact is a spec or a plan, that
  "correctness" prong means the artifact's factual accuracy and the
  completeness of its impact enumeration; where the audited artifact is a
  code deliverable, the prong keeps its existing meaning — the deliverable's
  behavior, and the defects that affect correctness or the stated
  requirements.
- **The finding bar is class-determined.** A defect this page enumerates —
  any of its defect classes or analysis families, whether or not it misstates
  fact — is a finding, and within that bucket a factual defect (a statement
  that misstates fact) is a finding regardless of how small its effect is. A
  preference — style, phrasing taste, a hypothetical improvement — is never a
  finding. No third category exists: a substantive observation is reported as
  a finding, and nothing is recorded as an observation without being a
  finding. The same defect class is classified the same way in every round of
  a loop — the validation record's per-round classification of each
  adjudicated class is what makes that checkable.

## Defect classes

A criterion is defective when it exhibits any of the following:

1. **Invented requirement.** The criterion cannot be traced to a developer
   statement or an observed failure recorded in the spec's provenance — it
   encodes something nobody asked for. A criterion that is the direct
   remediation of the stated problem or observed failure is traceable; a
   property of the solution with no bearing on the stated problem is not.
   This is scope creep stated as a criterion.
2. **Untestable criterion.** No check exists that could show the criterion
   satisfied or violated: the criterion states a goal without any stated or
   derivable verification instrument, so completion would be asserted rather
   than demonstrated.
3. **Either/or criterion.** An alternative is presented as one requirement —
   the criterion is satisfied by A or by B, so a deliverable satisfying only
   one branch passes. A requirement that offers the implementer a choice
   between materially different outcomes is two criteria or an undecided
   design question, not one criterion.
4. **Ambiguous criterion.** Two reasonable readers produce two different
   understandings of what satisfies it, and the spec itself resolves neither.
5. **Incapable instrument.** The criterion's verification instrument could
   not in principle detect the criterion's failure: an instrument that
   answers a weaker question than the criterion asks produces no evidence
   for it. Checking that a thing exists cannot verify what the thing says;
   matching a pattern cannot verify that meaning was conveyed; reading an
   artifact cannot verify behavior that only exists at runtime. The
   instrument must be able to observe the failure the criterion guards
   against, or the criterion is unverified regardless of how the check
   comes out.
6. **Self-containment violation.** The spec does not read standalone:
   required content lives only in comments or discussion, superseded text
   survives alongside its replacement, or the body carries process or
   tracking content outside the footer allowlist.
7. **Trivially-true restatement.** The criterion restates existing behavior
   or a tautology, so it can never fail and verifies nothing.
8. **State-undecidable criterion.** The criterion's verdict cannot be decided
   from the current state of the deliverable and its evidence — for example a
   trigger on an append-only record of historical events with no rule mapping
   the record to an implemented-or-not answer. A criterion must be decidable:
   the evidence either shows the requirement in force and holding, or it does
   not. Where the requirement is conduct, the record's post-remediation
   continuation is the compliance evidence: a violation window whose
   cause-level fix has landed in the deliverable, whose record discloses the
   window, and whose subsequent supervised cycles demonstrate the requirement
   holding resolves the criterion as implemented — the disclosed history is
   the remediation record, never a permanent FAIL and never a developer gate.
   A violation recurring after the cause-fix without remediation resolves not
   implemented, and the remediate loop continues. The anti-rationalization
   intent such criteria carry is preserved by full disclosure and by the
   post-fix continuation evidence — never by permanence, never by injecting
   the developer into verdict resolution (merge remains the human gate).

## Analysis families

Beyond the per-criterion classes above, the reviewer judges the spec as a
whole against these failure shapes. A spec can satisfy every criterion
individually and still be defective at one of these levels; each family is a
judgment call about the artifact's substance, not a pattern to scan for.

- **Traceability, both directions.** Every success criterion traces to a
  stated requirement or an observed failure, and every stated root cause is
  covered by at least one criterion. An orphan criterion — one answering to
  nothing the developer said — is a finding; so is a root cause the criteria
  never test.
- **Causal sufficiency of the solution.** The spec's chosen approach follows
  from its stated root causes: every element of the fix answers to at least
  one cause the spec states, and the stated causes collectively call for
  the approach taken. A solution element no stated cause accounts for is
  scope creep arriving by another route; a stated cause the approach
  silently ignores breaks the chain between problem and fix.
- **Problem fit.** The spec solves the problem it states: the intent
  statement and the criteria describe the same defect, the stated root
  cause and the chosen fix aim at the same thing, and a reader who
  implemented every criterion as written would find the stated problem
  actually solved. An intent section that promises one thing while the
  criteria deliver another, or a diagnosis and a fix that point in
  different directions, is a finding even when every individual criterion
  is well-formed. The same family bounds what evidence can show: a
  deliverable that passes every criterion demonstrates code-matches-spec,
  never spec-matches-problem — spec correctness is judged by review
  against the problem, not by implementation success.
- **Fabricated claims.** A claim asserted without source evidence behind it:
  a current-state assertion never checked against the artifact or code it
  describes, or a negation claim ("nothing does X") whose exhaustiveness was
  never verified. A claim the writer could not have verified at write time
  is a finding regardless of whether it happens to be true.
- **Internal contradiction.** Two sections of the spec disagree — explicitly
  stated requirements that conflict, requirements that contradict each other
  in effect though not in words, or a scope statement that excludes what the
  criteria include (or the reverse).
- **Escape hatches.** Language that licenses the implementer to short-circuit
  the requirements: a qualifier that makes a hard requirement evadable, an
  "as appropriate" that hands the decision to the party being constrained,
  or a criterion written so that any outcome satisfies it.
- **Feasibility.** The spec references files, functions, libraries, or
  capabilities that do not exist in the codebase or environment it targets,
  or states a set of criteria that are each satisfiable alone but jointly
  impossible. A requirement built on a nonexistent surface cannot be
  implemented as written; a criterion set with no satisfying assignment
  cannot be satisfied at all.
- **Gap analysis.** Implicit preconditions the spec relies on without
  stating, and boundary conditions the criteria never exercise. The change
  may be correct on the stated path and still fail on the unstated one the
  spec silently assumes. The same family covers absence: prohibitions the
  stated problem implies but no criterion states — a requirement of
  "must not happen" is as verifiable as a requirement of behavior — and
  unchanged behavior the change puts at risk but no criterion preserves,
  which is how a fix ships with a silent regression.
- **Scope narrowness.** The spec fixes a symptom where its own analysis
  points at a cause, demands more than the minimum viable fix for the stated
  problem, or leaves a systemic implication of the change unaddressed when
  the problem statement covers it.
- **Research adequacy.** Alternatives bearing on the design were not ruled
  out — the spec commits to an approach without evidence the obvious
  alternatives were weighed — or claims about the current state of the code
  were made without verifying them against the code as it stands now.
- **Blast radius.** The change's impact enumeration is incomplete: affected
  consumers or dependents of what the change touches are unaccounted for,
  or non-code surfaces the change reaches — cross-references, tests,
  documentation — are missing from the plan of record.
- **Cross-reference sufficiency.** A claim cites a source the source does
  not actually support, or a load-bearing claim — one the spec's conclusions
  depend on — is left uncited.
- **Decomposition.** Judged at the criteria-set level: each criterion is
  atomic (one requirement, not several bundled so partial satisfaction
  passes), delivers a single deliverable, is binary verifiable (its
  satisfaction or violation is decidable from a check's outcome, not a
  reader's interpretation), is viable as a PR-gate item, carries no more
  ceremony than the change needs, and is not already covered by a prior
  criterion.
- **Safety.** Failure modes that could cause irreversible harm are
  accounted for: destructive operations without rollback paths, data-loss
  scenarios, irreversible operations without safeguards. A spec whose
  change can destroy state and says nothing about recovering from that
  destruction is defective here.

## Loop

FAIL → revise the named findings in the artifact in place → re-validate. The
revise → re-validate cycle repeats until a verdict with zero findings.
Findings are never negotiated away — each revision genuinely fixes every
named finding.

Each cycle, the agent running the loop judges — never a script — whether the
loop is spinning: findings recurring or reshuffling without genuine resolution
relative to the remediation performed. On spin, the revision step moves up a
level: diagnose the cause and attempt higher-level fixing of it —
artifact-level structural revision such as breaking up a composite success
criterion, splitting an over-fat spec, resolving a spec conflict,
restructuring into atomic work units, or re-evaluating the approach — and the
loop continues on the revised artifact. These cause classes are judgment
examples — exemplary and open, never a closed checklist.

Escalation to the developer fires when spin persists after genuine
higher-level fixing attempts, or when the validation cannot reach a
zero-finding verdict by revision. The escalation carries the specific
findings, the suspected cause class(es), the root cause, what was tried, and
what is needed to resolve them. Escalation and the clean PASS are the loop's
only exits.

Beside the spin judgment sit two further triggers. Both are judgments stated
as such — never a script — and both open the same structural re-evaluation
of the artifact before any further in-place revision:

- **The non-convergence judgment.** When the loop's rounds are incrementally
  progressing — each cycle remediating its findings yet producing genuinely
  new ones, with no obvious convergence — the agent running the loop stops
  in-place revision and runs the structural re-evaluation.
- **The count trigger.** When the artifact has needed more than four
  revisions to address findings, the loop runs the structural re-evaluation.
  The count mandates the examination and never decides its outcome — the
  re-evaluation's verdict is the judgment, and a re-evaluation may conclude
  that the artifact stands. The findings-are-fixed requirement and criteria
  invariance are never satisfied by a revision count.

The structural re-evaluation examines, at minimum: repo boundaries;
separation of concerns; atomic work-unit decomposition; fatness; and intent
wording/reachability. The factors are the minimum the examination covers —
exemplary and open, never a closed checklist — and the examination and its
verdict are judgment. It resolves to one of three outcomes, each recorded in
the owning issue's validation record, from which the loop resumes or
redirects:

- **Sound** — the artifact's structure stands: the findings are recorded and
  the loop resumes on the unchanged artifact.
- **Recompose** — the artifact's shape is the defect: the split is performed
  per the recomposition protocol the issues card carries, and in-place
  revision of the pre-split artifact is superseded. Until that protocol is
  implemented on a consuming surface, the Recompose outcome records its
  grounds and escalates to the developer for the split.
- **Intent-unreachable** — the intent statement is the defect: it is
  rewritten, and the loop continues on the revised artifact.

A re-evaluation is one of the higher-level fixing attempts the escalation
rule counts; escalation still fires when convergence remains unreachable
after it.

Every completed validation cycle — one fresh-context review of the artifact
as it then stood, its verdict, its findings, and the remediation or loop
state they produced — appends one entry to the owning issue's validation
record (YAML) at `.issues/{N}/audit/validation.yaml`. One record file per
issue — the owning issue being the issue whose artifact the loop validates —
with one top-level section per artifact under validation (spec, plan,
implementation). Each entry carries the round's findings; every defect class
the round adjudicated, with its classification — a finding or a preference —
and, for a finding, the remediation performed or the outcome reached,
including the terminal cycle; and, when a cycle ran the structural
re-evaluation, the re-evaluation's outcome and its grounds. The recorded
class is the criteria source's enumerated defect class or analysis family
wherever one applies; the recorded factual kinds (a stale citation, a wrong
count, a mis-scoped claim) are the entry's detail — exemplars of the class,
not a closed list; an adjudicated preference records the class or family it
was adjudicated under with its classification; and the same defect carries
the same label in every round, so that two rounds' entries for one defect
compare. A round whose entry lists no finding is a zero-finding round. The
record lives beside the artifact in the issue store and never inside the
spec or plan body, and it is never a second copy of the verdict — the
verdict is recorded once per the verify card's recording rule, and the
record is the loop's history. A cycle whose artifact belongs to no issue in
a store records its verdict per the verify card's own recording rule and
appends no store record. A cycle's judgment cites the record.

## Criteria invariance

This page is the deck's single validation criteria source. On-demand audits
of prior specs restate these criteria verbatim from this reference — an audit
never runs on a different or locally-authored bar. Changing the criteria set
is deck governance, never a dispatch-time edit.
