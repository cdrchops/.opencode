# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Shared setup for the .opencode#2657 scenarios.
# Sourced by the per-scenario fixture scripts in this directory.
#
# See .opencode/tests-v2/AGENTS.md §3 Step 0b (per-scenario fixtures) and
# §3a (pre-supplied environment).

# Bootstrap a local issue store in the test workdir.
#
# The deck's spec stage reserves an issue number from the store before it
# writes a spec, so a scenario whose task reaches that stage needs the store
# to exist already — the run agent never bootstraps infrastructure itself.
# The store is a linked worktree of the reserved orphan branch `issues-data`,
# matching the deck's own store layout.
__2657_bootstrap_store() {
    local wd="$1"
    local branch
    branch=$(git -C "$wd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)

    # The store is a linked worktree of the orphan `issues-data` branch, and
    # the local-issues tool recognises it only by that shape: `.issues/.git`
    # is a FILE, not a directory. The harness's fixture-issue injection has
    # already created `.issues/` as a staged plain directory, and a linked
    # worktree cannot take over a path the index still tracks — so the
    # injected content is copied aside and untracked first, the branch and the
    # worktree are created with the same plumbing the tool uses, and the
    # content is copied back into the worktree. Hand-rolling this wrong fails
    # silently: `git worktree add` refuses a non-empty target, the error is
    # swallowed, and `.issues/` stays a plain directory the tool does not
    # recognise as a store (observed 2026-10-24, .opencode#2657).
    local stash_dir
    stash_dir="$(mktemp -d)"
    if [ -d "$wd/.issues" ]; then
        cp -r "$wd/.issues/." "$stash_dir/" 2>/dev/null || true
        rm -rf "$wd/.issues"
        git -C "$wd" rm -rq --cached .issues 2>/dev/null || true
    fi
    # The legacy open/ and closed/ directories are dropped: their presence
    # makes the tool warn about a legacy layout, and the warning sends the run
    # agent back into store archaeology instead of doing the task.
    rm -rf "$stash_dir/open" "$stash_dir/closed" 2>/dev/null || true

    # The orphan branch: an empty tree committed onto a new ref, so no
    # porcelain commit runs and no hook can fire.
    local tree commit
    tree=$(git -C "$wd" hash-object -t tree /dev/null 2>/dev/null || true)
    if [ -n "$tree" ]; then
        commit=$(git -C "$wd" commit-tree "$tree" -m "Init issues branch" 2>/dev/null || true)
        if [ -n "$commit" ]; then
            git -C "$wd" update-ref refs/heads/issues-data "$commit" 2>/dev/null || true
        fi
    fi

    git -C "$wd" worktree add -q "$wd/.issues" issues-data 2>/dev/null || true
    if [ -d "$wd/.issues" ]; then
        cp -r "$stash_dir/." "$wd/.issues/" 2>/dev/null || true
    fi
    rm -rf "$stash_dir" 2>/dev/null || true

    printf '.issues/\n' >> "$wd/.gitignore" 2>/dev/null || true
    git -C "$wd" add .gitignore 2>/dev/null || true
    git -C "$wd" commit -q -m "chore: ignore the local issue store" 2>/dev/null || true
    git -C "$wd" checkout -q -f "$branch" 2>/dev/null || true
}

# Settle the test project's trunk against its remote tip.
#
# The harness commits `init` onto the test project's `main` and the story
# fixtures land on top of it, so `main` sits several commits ahead of
# `origin/main` before any per-scenario fixture runs. The branch card's rule 2
# says to "sync and rebase if the trunk moved", and a rebase onto the remote
# tip would discard the seed content the scenario needs — the run agent then
# spends its run reasoning about the conflict instead of doing the task
# (observed: seven consecutive polls on `git merge-base main origin/main`).
# Moving `main` back to the remote tip and leaving the seed content staged
# keeps the content and removes the divergence, so the branch card's rebase
# path never fires (tests-v2 AGENTS.md §3a — pre-supplied environment; and
# §17 R-18's "fixture state" cause class).
__2657_settle_trunk() {
    local wd="$1"
    local remote_tip
    remote_tip=$(git -C "$wd" rev-parse --verify origin/main 2>/dev/null || true)
    if [ -n "$remote_tip" ]; then
        git -C "$wd" reset --soft "$remote_tip" 2>/dev/null || true
    fi
}
