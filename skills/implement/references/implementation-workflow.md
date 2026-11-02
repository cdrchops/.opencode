<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490 (restructured from the pre-rip reference, tag pre-rip); #2557 build-verification row + language/toolchain row; submodule execution boundary, .opencode#2563; #2551 test-value gate at the RED step; test-quality rows, .opencode#2601; docs-currentness step, .opencode#2670; issues-data remediation-first clause in suite-green, .opencode#2681; verify-pass gloss retirement, .opencode#2660 -->

# Implementation Workflow Reference

Consult at implementation start and before every mid-cycle change.
Work is performed in the agent's own context unless a scoped task genuinely
benefits from a clean-room dispatch — judgment, not ritual.

## Pre-implementation

| Step | How | Purpose |
|------|-----|---------|
| baseline | run the smoke tier (plus regression for the target area); record results | confirm a green baseline — a failing baseline is a defect to report, not code around |
| language/toolchain | identify the languages and build tools of the files about to be modified; load their cards (where cards exist) and `programming-principles` | language standards shape the change before the first edit, not after the first defect |
| authorization | check floor vocabulary + current session state | confirm the change's scope is authorized before modifying files |
| branch | `git-workflow-branch` conventions | feature branch exists before the first file modification |
| docs-currentness | for every surface the change implements against that is documented outside this repository — library APIs, language features, configuration formats, wire formats, dependency versions; the applicable set is the agent's judgment at cycle time — consult the surface's current authoritative documentation (official docs at the current version, the live package registry, or the consumed source and type hints) before the first code-write of that surface, per cycle (a mid-cycle change touching a new such surface re-triggers); state in chat what the current documentation established, briefly and discriminatingly; memory, training data, prior sessions' knowledge, similar-library analogy, and stale posts are not verification; a witnessed deprecation — Read [the deprecation encounter protocol](../../guidelines/deprecation-encounter-protocol.md); composes with the consumed-framework docs pass ([implement](../SKILL.md) item 6) | the change never rests on unverified knowledge of the externally-documented surfaces it implements against — memory and training data are not verification |

## Submodule execution boundary

In a parent repo with submodules, build, test, and verification runs through
the parent repo's own build framework. The agent does not execute a
submodule's own build tooling (its test runner, gates, or quality bars)
directly — foreign verification machinery enforces or silently skips
standards it does not own. The parent's own suite is the gate; the submodule
evolves its CI on its own tracker.

## RED-GREEN chain (per plan item / SC)

| Step | How | Purpose |
|------|-----|---------|
| red | write or run the failing assertion; confirm it fails for the stated reason | the defect is demonstrated, not assumed |
| test-value gate | the RED assertion targets application behavior — not source-content inspection of the agent's own files, not an environment/framework re-read tautology, not an assertion-shaped placeholder (implement card, Test value) | fabricated evidence never enters the chain |
| test-quality gate | the item's tests cover the edge cases and error conditions relevant to the item's behavior; where the change crosses a module boundary at least one assertion crosses it; no assertion's expected value changes without the asserted behavior changing (implement card, Test value) | a green suite that never exercised the failure shapes or crossed the boundary is not evidence for the item |
| green | minimal change that turns it green | no speculative additions |
| post-regression | re-run the affected tiers (smoke + changed-area regression) | nothing previously working broke |
| verify-inline | the executed check's output is the evidence | never assert success without a run |
| commit | stage the item's files; atomic, descriptive message | one item, one commit — the next item's RED follows this commit, never a later batch RED |

## Test tiers

Default per implementation cycle and per PR: smoke + regression. The full
suite is never the default — running everything every cycle leaves no
capacity for the work itself.

| Tier | Contents | When |
|------|----------|------|
| smoke | fastest end-to-end signals: the system builds/boots and the touched path basically works | every cycle, before commit |
| regression | tests covering the changed area and its direct dependents | every cycle, before commit and PR |
| full | the entire suite | release boundaries, explicit developer request, or when tiered runs cannot isolate a failure |

Choosing tiers for a given change is judgment — what changed decides what
regression covers. No script decides scope.

## Post-implementation

| Step | How | Purpose |
|------|-----|---------|
| test-contract currency | a behavior change updates its dependent tests in the same cycle — when behavior is spec-removed, the stale tests are removed/updated on the same branch | tests contract on behavior; a merged behavior change that leaves its old tests behind re-breaks the suite for every later PR |
| structural | project-local lint/typecheck commands | cheap mechanical facts first |
| build verification | when the change affects build configuration or packaging (or the deliverable is a build artifact): a shallow temp-copy checkout (`git clone --depth 1`) of the tree; the repo's canonical build command sourced from the repo's declared build manifest (ask rather than guess when the manifest does not declare one, and record the confirmed command); assertion that the final outputs exist and are sound (e.g. the built artifact present, its contents inspected) | "lint passed" is not "build works" — the built artifact is the deliverable, verified in a pristine checkout, never asserted from the working tree alone |
| suite-green | run the affected tiers (smoke + regression); every failure is remediated or dispositioned via a filed fix — never passed through as "pre-existing" (#2553). A failure whose remedy is issue-store hygiene (workspace-local repair of issue-store data on the store's `issues-data` branch — YAML validity, record fields, store metadata; agent-owned and authorization-free per the store's workspace guide) routes remediate-in-place: the producing agent repairs the store in the same working session via the store's own tooling, and the gate proceeds on that repair. The filed-fix route stays for failures whose remedy requires implementation authorization — any change outside the issue stores. Full suite only at release boundaries or explicit developer request | a red suite at the PR boundary ships the regression forward |
| verify pass | dispatch the `verify` card's single fresh-context reviewer | zero-finding verdict under the verify card's FAIL path; churn rule applies |
| PR prep | `git-workflow-pr` conventions | review context for the human gate |

Escalation: any step that cannot complete honestly stops the cycle — report
the state, the blocker, and what is needed; never fabricate a pass.
