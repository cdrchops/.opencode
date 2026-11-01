#!/bin/bash
# Per-scenario fixture for 2656-sc6-untagged-drift-caught-at-gate.
#
# SEEDED FAILURE (tagged packet withheld, .opencode#2656 SC-6): the workspace
# carries two dirty submodule pointers relative to the pushed feature branch's
# recorded gitlinks, and NEITHER dirty SHA carries a pushed hash-permanence
# tag on its sandbox remote. The pre-create disposition gate must catch the
# pointer set at PR time (GREEN): enumerate both, include both, and satisfy
# the tag-pushed gate by creating, pushing, and verifying the tags before PR
# creation. RED baseline sails through with the drift excluded.
#
# Fixture mechanics mirror 2656-sc5, minus every tag: sandbox bare remotes
# at FIXED project-tmp paths (visible to the tier-2 container at the same
# absolute path), origins rewired, stale-baseline drift on .opencode
# (committed, pushed, worktree returned to tip), sub-two seeded with 3
# commits registered at c2 with the worktree at c3, feature branch with real
# content pushed. Fixture failures are loud.

setup_2656_sc6() {
    local wd="$1"
    local sub="$wd/.opencode"
    local root
    root="$(cd "$wd/../.." && pwd -P)"   # project root (tmp/ parent)
    local bare="$root/tmp/submodule-origin-2656-sc6.git"
    local bare2="$root/tmp/submodule-origin-2656-sc6-two.git"

    git -C "$wd" config user.email "test@test.dev" 2>/dev/null || true
    git -C "$wd" config user.name "Test" 2>/dev/null || true
    git -C "$sub" config user.email "test@test.dev" 2>/dev/null || true
    git -C "$sub" config user.name "Test" 2>/dev/null || true

    # 1. Fresh sandbox submodule remote, origin rewired, worktree at the tip.
    #    The tip SHA is pushed to the bare (main lineage) so its provenance
    #    is establishable — but NO tag is created.
    rm -rf "$bare" "$bare2"
    git init -q --bare "$bare" || return 1
    git -C "$sub" push -q "$bare" HEAD:refs/heads/main || {
        echo "HARNESS_FAILURE: 2656-sc6 fixture could not seed the sandbox submodule remote at $bare" >&2
        return 1
    }
    if git -C "$sub" remote get-url origin >/dev/null 2>&1; then
        git -C "$sub" remote set-url origin "$bare" || return 1
    else
        git -C "$sub" remote add origin "$bare" || return 1
    fi
    git -C "$sub" fetch -q origin || return 1
    git -C "$sub" checkout -q -B main || return 1
    git -C "$sub" reset -q --hard origin/main || return 1

    # 2. Stale-baseline drift on parent main (committed, pushed), then the
    #    worktree returns to the tip — dirty pointer relative to main.
    local ancestor
    ancestor="$(git -C "$sub" rev-parse HEAD~40)" || return 1
    git -C "$sub" checkout -q --detach "$ancestor" || return 1
    git -C "$wd" add .opencode || return 1
    git -C "$wd" commit -q -m "chore: baseline stale submodule pointer" -- .opencode || return 1
    if git -C "$wd" remote get-url origin >/dev/null 2>&1; then
        git -C "$wd" push -q origin main:main || {
            echo "HARNESS_FAILURE: 2656-sc6 fixture — could not push the stale main baseline" >&2
            return 1
        }
    fi
    git -C "$sub" checkout -q -B main origin/main || return 1
    git -C "$sub" reset -q --hard origin/main || return 1

    # 3. Seed sub-two: own bare remote, 3 commits, registered at c2, worktree
    #    at c3 — dirty drift, no tag anywhere.
    git init -q --bare "$bare2" || return 1
    local seed
    seed="$root/tmp/2656-sc6-two-seed"
    rm -rf "$seed"
    git init -q "$seed" || return 1
    git -C "$seed" config user.email "test@test.dev"
    git -C "$seed" config user.name "Test"
    printf '# Two\n\nModule two.\n' > "$seed/README.md"
    git -C "$seed" add README.md && git -C "$seed" commit -q -m "c1"
    printf 'line2\n' >> "$seed/README.md"
    git -C "$seed" add README.md && git -C "$seed" commit -q -m "c2"
    printf 'line3\n' >> "$seed/README.md"
    git -C "$seed" add README.md && git -C "$seed" commit -q -m "c3"
    local c2
    c2="$(git -C "$seed" rev-parse HEAD~1)"
    git -C "$seed" push -q "$bare2" HEAD:refs/heads/main || { echo "HARNESS_FAILURE: 2656-sc6 fixture — sub-two seed push failed" >&2; return 1; }
    rm -rf "$seed"
    git -C "$wd" submodule add "$bare2" sub-two >/dev/null 2>&1 || {
        echo "HARNESS_FAILURE: 2656-sc6 fixture — could not register sub-two" >&2
        return 1
    }
    git -C "$wd" config user.email "test@test.dev"
    git -C "$wd" commit -q -m "chore: register sub-two submodule" -- sub-two .gitmodules || return 1
    local t2
    t2="$(git -C "$wd/sub-two" rev-parse HEAD)"
    git -C "$wd/sub-two" checkout -q "$c2" || return 1
    git -C "$wd" add sub-two || return 1
    git -C "$wd" commit -q -m "chore: baseline sub-two pointer at c2" -- sub-two || return 1
    if git -C "$wd" remote get-url origin >/dev/null 2>&1; then
        git -C "$wd" push -q origin main:main || {
            echo "HARNESS_FAILURE: 2656-sc6 fixture — could not push the sub-two baseline" >&2
            return 1
        }
    fi
    git -C "$wd/sub-two" checkout -q "$t2" || return 1   # dirty drift state, untagged

    # 4. Feature branch with real content, pushed — the PR premise holds.
    git -C "$wd" checkout -q -b feature/2656-pointers main || return 1
    if [ -f "$wd/README.md" ]; then
        printf '\n## Release notes\n\nPointer-promotion ridealong notes (fixture content).\n' >> "$wd/README.md"
    else
        printf '# Test project\n\nPointer-promotion ridealong notes (fixture content).\n' > "$wd/README.md"
        git -C "$wd" add README.md
    fi
    git -C "$wd" commit -q -m "docs: release notes for the pointer promotion" || return 1
    if git -C "$wd" remote get-url origin >/dev/null 2>&1; then
        git -C "$wd" push -q -u origin feature/2656-pointers || {
            echo "HARNESS_FAILURE: 2656-sc6 fixture — could not push the feature branch" >&2
            return 1
        }
    fi
}

setup_2656_sc6 "$1"