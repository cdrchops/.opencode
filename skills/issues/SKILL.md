---
name: issues
description: "Load when creating, reading, updating, commenting on, linking, or closing any issue — local .issues/ stores, GitHub, or GitBucket. Covers qualified issue names, platform routing via the authenticated CLIs, the local-issues tool, and the comment gate: a remote comment is posted only when the correspondence card's channel rule qualifies it as a stakeholder notice, and the gate is evaluated before the agent commits to posting."
license: MIT
provenance: AI-authored, .opencode#2490; tooling contract consolidated per .opencode#2543; .opencode#2382; recomposition protocol, .opencode#2661
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2490; .opencode#2543; .opencode#2561 verified-resolved closure; ticket-state hygiene, .opencode#2563; mirror-repair + pointer check, .opencode#2597; local/remote boundary + §7 routing correction, .opencode#2382; recomposition protocol, .opencode#2661 -->

# issues — issue operations

1. **Routing.** Local stores go through `.opencode/tools/local-issues` with
   qualified names (`repo#N`) on every command that takes a number — bare
   numbers are rejected; remote operations go through the platform CLI
   (`gh` / `gb`) — authenticated tools, never raw API scripts. The script's
   `--help` is the flag-level source of truth; the CLI mechanics are Read
   [the local-issues CLI reference](references/local-issues-cli.md), and the
   sync mechanics are Read
   [the local-issues sync and worktree mechanics](references/sync-mirroring.md). **Pull-only repositories
   (#2667):** a repository the tool classifies pull-only (its effective
   origin is `http`/`https`) holds no local issue store; the local store's
   operations never target it, and its issues are read and written through
   the platform CLI against its own tracker.
2. **Creation.** Remote first: when the store has a remote tracker, file the
   remote issue to reserve the number before any local folder setup — every
   issue type; the local `{N}/` mirror follows, its `github_url` field
   written locally via `update --github` (a local-store write — see §1's
   boundary; the remote body itself is edited through the platform CLI).
   Remoteless stores pick the next free number in that repo's own namespace.
   The local-artifacts pointer written into the remote body must resolve to
   the actual local folder at write time — an unresolvable pointer is a flow
   defect to fix in the same action, not a formatting choice.
   The remote body follows Read
   [the remote body format](../spec/references/remote-body-format.md)
   — sizing doctrine, required sections, and the closing blockquoted
   artifacts link, reconciled on every remote-body edit; the full
   spec and artifacts live locally and stay local-authoritative. Title states the work; labels describe
   pipeline state. Never derive the number by listing remote issues and never
   hand-create the `{N}/` folder — register it via
   `local-issues create --number repo#N`.
3. **Comment gate.** The gate defers to Read
   [the channel rule](../correspondence/SKILL.md):
   a remote comment is posted only when the channel rule qualifies the
   content as a stakeholder notice, and the gate is evaluated only by the
   agent, before the agent commits to posting — posting is not the default
   outcome. Spec and plan corrections always edit the artifact in place —
   never route to comments.
4. **Relationships.** Link sub-issues to parents; the hierarchy carries the
   authorization cascade and closure order.

   **Recomposition protocol** — when a validation loop's structural
   re-evaluation (the sibling loop rule `.opencode#2660` carries) resolves an
   artifact to recomposition, its **Recompose** outcome, the agent running
   that loop performs the split:

   - **Parts.** One issue per part artifact; each part is registered as a
     sub-issue of the recomposed issue via the `local-issues` tool's `link`
     command. Each part's spec reads standalone under the spec card's own
     discipline and records its side of the seams the umbrella names.
   - **Umbrella.** The recomposed issue's spec becomes the umbrella: it
     records the parts, the seams between them (the shared conventions,
     interfaces, and ordering constraints a part builds on), and the
     re-evaluation's grounds; the redistributed content is deleted from it
     in the same action that records the recomposition — no
     superseded-content pointers remain.
   - **Authorization void.** Implementation or PR authorization carried for
     the pre-split scope is void at recomposition and does not authorize the
     parts; work already delivered under a then-valid authorization stays
     delivered; the parts' further implementation and PR work proceeds only
     under the authorization the developer states after the notification. A
     recomposition reached during the spec phase — before any implementation
     or PR authorization exists — has nothing to void, and the notification
     still applies. The work card's authorization check carries the same
     void.
   - **Notification.** The developer is notified at split time by a
     stakeholder comment on the recomposed issue per §3's comment gate,
     carrying the recomposed issue's and each part's issue and artifacts
     URLs plus the authorization consequence; chat reporting accompanies
     the comment and does not replace it.
   - **Review shape.** The parts' review shape follows the PR contract —
     Read [the git-workflow-pr card](../git-workflow-pr/SKILL.md): issues the
     developer authorizes together share one branch and one PR carrying one
     squashed commit per part; a part never opens its own branch or PR
     outside the authorization scope that names it. This protocol states no
     second PR rule.
   - **Closure order.** Each part closes by its own delivered work or triage
     verdict (§5); the recomposed issue closes only after every part has
     closed, as a verdict-backed closure whose record states the
     redistribution — the pre-split scope was superseded by the parts. This
     is the closure order the hierarchy sentence above carries.
   - **No thresholds.** The protocol states no part count and no size
     threshold: which parts an over-fat artifact decomposes into, and when,
     is the loop rule's structural re-evaluation's judgment; this protocol
     governs the split's mechanics, recording, authorization, notification,
     review shape, and closure.
5. **Closure.** Issue closure follows delivered work (post-merge cleanup), an
   evidence-backed verified-resolved/moot triage verdict, or explicit
   developer instruction — never closure to tidy up. A verdict-backed closure
   reconciles the remote tracker to the same closed state in the same
   workflow; the local store is authoritative (#2561).
6. **Ticket-state hygiene.** A stale ticket state — the local store mirror's
   record diverging from the remote tracker's state — is corrected on
   discovery, reconciling both sides to the true state. The remote tracker
   anchors reality for changes made outside the local workflow (e.g. a
   remote-side closure the local mirror missed); the local-authoritative
   closure ruling (#2561) governs the closure workflow it drives. The two
   govern different moments and do not collide.
7. **Mirror-repair.** On discovery that a remote issue's local record is
   absent, or that the issue's local-artifacts pointer does not resolve to
   the local folder it names, repair instead of reporting: create the local
   record at the remote-assigned number via `local-issues create --number
   repo#N`, mirror the remote-tracked content into `{N}/`, and correct the
   remote body's pointer through the platform skill — Read
   [the gh-cli skill](../gh-cli/SKILL.md) or Read
   [the gb-cli skill](../gb-cli/SKILL.md) — per §1. Boundary: local-issues commands manage only the local
   issues-data store — they never contact or update any remote issues-system
   API on any platform; `update --github` writes the local store's
   `github_url` field only and is never the mechanism for a remote-body
   correction. The repair is fact work performed on discovery — never a
   blocker or fail reason by itself. This rule governs a record's absence;
   ticket-state hygiene (§6) governs state divergence for an existing record.
8. **Email actions.** Mid-flow email work — drafting, sending, or mailbox
   checks — dispatches to the `email-ops` subagent, which holds the gmail
   tool permissions; the flow itself never calls gmail tools directly.

## local-issues operating contract

- **Tool path:** `.opencode/tools/local-issues` — run it directly
  (`./.opencode/tools/local-issues <command> [flags]`). First mutation
  auto-initializes the `.issues/` orphan-branch worktree in a store-holding
  repository — every repository the tool classifies writable; a pull-only
  repository carries no store and never receives one (#2667).
- **Invocation:** every number argument uses the qualified `repo#N` form;
  bare numbers exit with the available-qualifier list.
- **Session start:** `init` (bootstrap worktrees + pull remote `issues-data`
  for all repos), then `sync` (commit + pull-rebase + push) for bidirectional
  currency.
- **Fail-fatal worktree:** if worktree establishment fails, the tool exits
  non-zero with a remediation command — never continue in plain-file mode.
- **Mutation commands** (`create`, `update`, `comment`, `close`, `delete`,
  `link`, `renumber`) auto-commit and auto-push to the `issues-data` branch.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
