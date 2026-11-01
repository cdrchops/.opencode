<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->

# [SPEC] Root-repo PRs include every dirty submodule pointer — pre-create disposition gate

## Problem

On 2026-10-22, in a parent repository PR, an agent staged only the two submodule
pointers its own work intended and left 19 other dirty submodule pointers
unstaged, narrating them as "pre-existing workspace residue, untouched". The
developer's correction:

> dirty pointers are NOT allowed when create a root repo PR, the pointers are
> always supposed to be included. This is a regression.

## The rule (as the deck now states it)

Before creating a parent-repo PR — a PR in a repository that consumes
registered submodules — the creating agent enumerates every dirty submodule
pointer using the parent's `git submodule status` listing (the `+` rows:
checked-out commit differs from the recorded gitlink) and accounts for each
with exactly one of two dispositions:

- **include (default):** stage the pointer and record it into the PR's
  per-issue commit content; the recorded pointer SHA carries its pushed
  hash-permanence tag (`<parent-repo>/<issue-number>-<submodule-dir>`)
  before PR creation.
- **halt for developer clarification:** when the pointer's lineage cannot be
  established from the session's record and the submodules' recorded state.

Zero unaccounted dirty pointers is the pass condition at PR creation. A dirty
pointer left out of a parent-repo PR is a regression regardless of which
session or sub-agent introduced it; "pre-existing residue" names no
disposition and no deck category. Drift is never resolved by checkout-away
cleanup.

## Scope

Deck changes to `skills/git-workflow-pr/SKILL.md` §2(d) only. No scripts.