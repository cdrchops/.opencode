---
name: verify
description: "Load when checking a deliverable against its stated requirements before any completion or PR-readiness claim, or when auditing an existing artifact on demand — a spec, plan, or deliverable re-checked against the criteria set its producing card owns. Dispatches exactly ONE fresh-context reviewer — never the implementor — who reads the primary artifacts (spec/SCs, the diff, actual executed test output) and flags only gaps affecting correctness or stated requirements. FAIL → remediate → fresh re-review → repeat until a zero-finding verdict, with semantic spin detection; on spin, fix the diagnosed cause at a higher level; escalate when spin persists. Never proceed past an unremediated FAIL. One verdict record; no artifact chains."
license: MIT
provenance: AI-authored, .opencode#2490; #2518 criteria invariance; externally-documented-surface examination, .opencode#2670
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; #2518 criteria invariance; #582 yaml-contract-format convention; #2557 build evidence bar; behavioral-testing dispatch fix, .opencode#2578; artifact-presence gate, .opencode#2597; instrument-capability rule + criteria-set ownership, .opencode#2601; spin-bounded review loop, .opencode#2606; state-decidable verdict resolution, .opencode#2646; externally-documented-surface examination, .opencode#2670; finding bar, triggers, validation record, .opencode#2660 -->

# verify — the single verification pass

1. **Dispatch one reviewer.** Fresh context, budget comparable to the
   implementor. The reviewer reads the primary artifacts directly — spec/SCs,
   the diff, the executed test output — not the implementor's summaries.
2. **The churn rule (include verbatim in the reviewer prompt):** *Flag only
   gaps that affect correctness or the stated requirements. A reviewer
   prompted to find gaps will always report some — do not chase style,
   ceremony, or imagined requirements.*
3. **Verdict.** PASS / FAIL per SC, grounded in the reviewer's findings and
   the executed evidence. A PASS is a verdict with no findings — a verdict
   with any finding is a FAIL, and findings are never negotiated away. The
   finding bar is class-determined: a defect the audited artifact's criteria
   source enumerates — any of its enumerated defect classes or analysis
   families, whether or not it misstates fact — is a finding, and within that
   bucket a factual defect (a statement that misstates fact) is a finding
   regardless of how small its effect is; a preference — style, phrasing
   taste, a hypothetical improvement — is never a finding, and no third
   category exists: a substantive observation is reported as a finding. The
   same defect class is classified the same way in every round — the
   validation record's per-round classification of each adjudicated class is
   what makes that checkable. Where the audited artifact is a spec or a plan,
   the churn rule's "correctness" prong means the artifact's factual accuracy
   and the completeness of its impact enumeration; a code deliverable's prong
   keeps its existing meaning — the deliverable's behavior, and the defects
   that affect correctness or the stated requirements. Record it once — chat
   or PR description. No YAML artifact chains.
4. **FAIL path.** Remediate → fresh re-review → repeat until a zero-finding
   verdict. A finding whose ground is an append-only record — a recorded
   historical event in a supervision ledger, determination record, or audit
   log — resolves by state, not by developer disposition: the agent remediates
   the cause, completes the record's disclosure, and the criterion's verdict
   follows from the current evidence — the requirement in force and holding in
   the post-remediation continuation. Historical violation windows with landed
   cause-fixes and compliant continuation do not keep the criterion FAILED;
   recurrence without remediation does. The developer is never a verdict
   resolver — escalation is for spin, not for disposition (the spec card's
   validation standards carry the state-decidability rule). Never proceed past
   an unremediated FAIL: remediate and re-verify instead. Each cycle, the
   agent running the loop judges — never a script — whether the loop is
   spinning (findings recurring or reshuffling without genuine resolution
   relative to the remediation performed). On spin, the revision step moves up
   a level: diagnose the cause and attempt higher-level fixing of it —
   artifact-level structural revision such as breaking up a composite SC,
   splitting an over-fat spec, resolving a spec conflict, restructuring into
    atomic work units, or re-evaluating the approach — and the loop continues
    on the revised artifact. Escalation to the developer fires when spin
    persists after genuine higher-level fixing attempts, carrying the specific
    failing SCs, the suspected cause class(es), the root cause, what was
    tried, and what is needed.

    Beside the spin judgment sit two further triggers. Both are judgments
    stated as such — never a script — and both open the same structural
    re-evaluation of the artifact before any further in-place remediation:
    the **non-convergence judgment** — when the loop's rounds are
    incrementally progressing, each cycle remediating its findings yet
    producing genuinely new ones, with no obvious convergence, the agent
    running the loop stops in-place remediation and runs the re-evaluation —
    and the **count trigger** — when the artifact has needed more than four
    revisions to address findings, the loop runs the re-evaluation; the count
    mandates the examination and never decides its outcome, and the
    findings-are-fixed requirement and criteria invariance are never
    satisfied by a revision count. The structural re-evaluation and its three
    recorded outcomes (Sound, Recompose, Intent-unreachable), and the
    per-cycle validation record `(YAML)` at `.issues/{N}/audit/validation.yaml`,
    are the spec card's validation standards' canonical statement —
    [validation standards](../spec/references/validation-standards.md) §Loop:
    each review cycle appends its entry per that rule, never a second copy of
    this card's verdict and never inside the audited artifact — the verdict
    itself is recorded once, above; a cycle whose artifact belongs to no
    issue in a store records the verdict per this card's own recording rule
    and appends no store record. A re-evaluation is one of the higher-level
    fixing attempts this rule counts; escalation still fires when convergence
    remains unreachable after it.
5. **Own-test execution stays with the implementor.** Running tests and showing
   output is fact work, not review — it happens in `implement`, and the
   reviewer consumes its output.
6. **Test-value judgment lives here.** Whether a test asserts behavior the
   build tool already guarantees is intent-decidable — the reviewer judges it;
   no script decides it.
7. **Build evidence for build-affecting changes.** When the change affects
   build configuration or packaging (or the deliverable is a build artifact),
   the executed evidence includes the build run's output (the canonical build,
   sourced from the repo's declared build manifest, run in the shallow
   temp-copy checkout) and the final-outputs assertion — the built artifact
   exists and is sound. The reviewer consumes these as executed evidence, not
   assertions; a review claiming build verification without the build's real
   output is an unverified claim.
8. **Criteria invariance.** Every audit and re-audit runs on the same declared
   criteria set: re-audit prompts restate it verbatim, and the pass condition
   is never re-authored at dispatch time. Post-verdict notes and directives
   feed the loop's revision step (fix the artifact), not a new bar. Changing
   the bar itself is deck governance — amend the criteria set so every audit
   runs on it. A directive that redefines the bar mid-stream is a
   halt-and-clarify trigger, not a re-dispatch trigger.
9. **Criteria-set ownership.** The audited artifact's producing card owns
   that artifact's audit criteria reference, and the reviewer reads the
   owning card's reference before judging — the artifact is measured against
   the bar its own producer card declares, not one invented at dispatch
   time. The spec card's
   [validation standards](../spec/references/validation-standards.md) are
   the criteria set for spec audits, and the plan card's
   [plan validation standards](../plan/references/plan-validation-standards.md)
   are the criteria set for plan audits. This composes with criteria
   invariance: ownership names which declared set applies; invariance binds
   re-audits to that same set.
10. **Artifact-presence gate.** An audit requires the audited artifact present
    at a verified local path, verified before the audit's substance begins.
    When the artifact is absent locally, the auditor performs the mirror-repair
    per the `issues` card and proceeds with the audit — absence of a local
    artifact is never a fail reason or halt ground by itself.
11. **Instrument capability.** Evidence from an instrument that could not in
    principle detect the criterion's failure mode is not evidence the
    reviewer can consume: a check that answers a weaker question than the
    criterion asks verifies nothing, however cleanly it runs. Existence
    cannot verify content, pattern-match cannot verify meaning, and reading
    cannot verify runtime effect. The behavioral-provenance rule below is an
    instance of this rule applied to behavioral SCs — reading a session
    transcript cannot substitute for the harness's recorded runtime evidence,
    which is why ad-hoc runs produce nothing consumable.
12. **Behavioral evidence provenance.** Evidence for a behavioral SC is
    accepted only from the `tests-v2` harness — load the `behavioral-testing`
    card first and read `.opencode/tests-v2/AGENTS.md` as its step 1 requires
    (session.yaml from `behavior_run`, plus the clean-room evaluation). An
    ad-hoc `opencode run` produces no evidence the reviewer can consume.
13. **Externally-documented-surface usage.** The reviewer's diff examination
    includes the change's usage of surfaces documented outside the repository —
    library APIs, language features, configuration formats, wire formats,
    dependency versions — judged for adequacy against their current
    documentation. Usage the current documentation contradicts is a correctness
    finding, flagged under the churn rule: it affects correctness, and the
    anti-churn binding is unchanged.

**Agent-to-agent format:** structured data one agent creates for another — or
ingests from another — defaults to YAML, marked by the bare `(YAML)` token at
each reference; tool I/O, CLI output, and external configuration keep their
native format; chat prose carries no token.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
