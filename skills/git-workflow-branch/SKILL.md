---
name: git-workflow-branch
description: "Always load before creating any git branch or starting any work on a task in any repo — however small the task seems. Branch naming, trunk-freshness checks, submodule sync, provenance recording. Never commit directly to the trunk-identified primary branch; the feature branch exists before the first file modification."
license: MIT
provenance: AI-authored, .opencode#2490; submodule discipline rules, .opencode#2563; scope-boundary provision, .opencode#2639; tagged-SHA pointer discipline, .opencode#2683
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; submodule discipline rules, .opencode#2563; scope-boundary provision, .opencode#2639; tagged-SHA pointer discipline, .opencode#2683 -->

# git-workflow-branch

1. **Branch before files.** Create the feature branch before any modification:
   `feature/<issue>-<slug>` (or `<issue>-<slug>` for parent-repo submodule work).
   Issues sharing an authorization scope share **one** feature branch — name it
   after the scope's primary issue; one branch per issue is the violation.
   **Scope boundary.** The authorization scope is the developer directive that
   produced the work — the single message covering it — never a per-item
   decomposition of that directive. A later message that adds work while that
   scope is unfinished extends that scope: its commits land on the scope's
   open branch, and no new branch opens.
2. **Trunk freshness.** Before any work in the repo: (a) pull the parent
   repo's trunk to its remote tip; (b) sync each submodule's pointer to that
   submodule's remote trunk tip — the tracked-branch tip per `.gitmodules`,
   fetched from the remote, **not** the recorded pointer (syncing to the
   recorded pointer reproduces possibly-stale state, which is the bitrot trap
   itself); (c) when the parent has nothing to contribute beyond pointer
   bumps, create no branch and make no commit — the drift rides with the next
   real parent change. Verify the trunk tip before branching — sync and rebase
   if the trunk moved; state the verified tip in the work record, whose
   provenance part the agent writes at this step, before the branch exists.
   When scanning
    branches, `issues-data` is a reserved orphan-branch issue-store ref, checked
   out in a linked worktree (the `+` marker in `git branch -a`) — never a
   feature-branch naming or cleanup candidate (#2548 C8). **Registration
   scope:** this sync applies to *registered* submodules — entries git's own
   submodule mechanism tracks. A checkout the workspace root does not track
   (a gitignored or otherwise unregistered sub-repository) is not a
   submodule: it has no pointer to sync. A tip this step stages for pointer
   capture follows the tagged-SHA pointer discipline (rule 3).
   **Bounded verification.** Trunk-freshness verification is bounded and
   read-only: verify the working repo's trunk tip against its remote (fetch
   and compare) and proceed to the branch decision on that evidence. A
   submodule-pointer or store sync failure encountered during the same pass
   is recorded, not remediated, and does not block the branch decision. If
   the working repo's own trunk tip cannot be verified because its remote is
   unreachable, record the failure and halt the branch decision for
   developer direction rather than branch on unverified freshness.
3. **Submodules — real-work sequence.** When the parent repo has real content
   beyond pointer bumps, work proceeds in this fixed order: sync (per rule 2)
   first, then feature-branch creation, then an immediate pointer-capture
   commit — **pointer-only commits are sanctioned at branch level as capture
   commits** — and only then commence work. At the review surface the
   pointer-only prohibition applies (see `git-workflow-commit` #5 and
   `git-workflow-pr`): the pointer rides with real changes in the squashed
   per-issue commit, never as a standalone parent PR.
   **Tagged-SHA pointer discipline (restored, .opencode#2683).** Before a
   parent commit records a submodule pointer, the recorded SHA carries a
   pushed annotated hash-permanence tag `<parent-repo>/<issue-number>-<submodule-dir>`
   in the submodule repository: create the tag if the commit is untagged
   (idempotent — a present tag is verified, never re-created; a name that
   exists pointing elsewhere is reported, never silently re-created),
   push it to the submodule's remote, and verify it on the remote
   (`git ls-remote --tags`). The tag targets the commit the gitlink records —
   not the submodule working tree's HEAD when the two differ. Every recorded
   pointer stays name-reachable through branch cleanups and release flows;
   `git-workflow-pr` §2 blocks a PR whose bumps carry unverified pointers,
   and `git-workflow-cleanup` runs the idempotent tag-if-untagged backstop
   before branch deletion. Push failure on a pull-only origin (#2667) is
   reported per that rule — no silent omission.
   **Registration scope:**
   the pointer-capture commit applies to *registered* submodules only; a
   checkout the workspace root does not track is not a submodule — it has no
   pointer to capture, and the agent does not move its HEAD to a remote trunk
   tip.
   **Pull-only delivery (#2667).** A registered submodule whose origin is
   pull-only — an `http`/`https` origin, so that a push to it cannot succeed —
   receives no branch creation in it, no commit in it, and no push to it: the
   agent does not attempt a push it knows cannot succeed. The handling is the
   agent's judgment — deliver the change from a repository it can push to
   (such as a fork or clone of that repository), or report to the developer
   that the change cannot be delivered from this workspace. Nothing here
   forbids delivering the change from a repository the agent can push to.
4. **Submodule deinit remediation.** False-modified submodule status (a
   phantom ` M <submodule>` in the parent) caused by divergent nested
   submodule state is remediated with, run from the parent repo root:

   ```
   git submodule foreach git submodule deinit --all --force
   ```

   The deinit mandate is a special carve-out whose purpose is removing
   unwanted recursive-checkout residue that causes agent-behavior issues and
   bitrot. Caveat: `--force` destroys uncommitted content in nested submodule
   worktrees — safe under the no-recursion rule (`ci-boundary`), because
   agents never legitimately hold uncommitted content in nested submodule
   worktrees. The card prescribes no restore path: restoring nested submodule
   worktrees is not an agent operation.
5. **Provenance.** Record branch, base tip, and the issue in the work record,
   alongside the verified tip the trunk-freshness step wrote there, so PR
   preparation can verify the chain later. **When the work has no issue,
   record branch and base tip only** — never create an issue, or initialize an
   issue store, to satisfy provenance; the record is input to PR prep, not a
   checklist that summons new machinery.
6. **Trunk protection.** The trunk commit/push check is enforced mechanically;
   treat any block as the hard boundary it is.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
