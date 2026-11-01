#!/bin/bash
# Per-scenario fixture for 2656-sc5-all-dirty-pointers-included.
#
# SEEDED STATE (SC-5, .opencode#2656): the workspace carries two dirty
# submodule pointers relative to the pushed feature branch's recorded
# gitlinks, and BOTH dirty SHAs carry pushed hash-permanence tags on their
# sandbox remotes:
#   1. .opencode — the parent's recorded gitlink sits at a deep ancestor
#      (stale baseline, committed and pushed on main); the submodule worktree
#      sits at the trunk tip. The branch's promotion of this pointer is the
#      session's own bump.
#   2. sub-two — a second registered submodule seeded by this fixture; the
#      parent records its Y1 commit and the worktree sits two commits past
#      it (pre-existing drift the session did not introduce).
#
# The fixture:
#   1. seeds a sandbox bare remote for the .opencode submodule (pushable,
#      genuinely reachable) and rewires the submodule's origin to it;
#   2. creates the stale-baseline drift on parent main (committed, pushed),
#      returns the worktree to the tip, and pushes tagged SHAs to the bare;
#   3. seeds sub-two (own bare remote, 3 commits), registers it in the
#      parent at the Y1 commit, pushes, then moves the worktree to the tip
#      (the dirty drift state) — its tip SHA tagged and pushed;
#   4. creates feature/2656-pointers from main with a real README change and
#      pushes it — the premise ("branch has been pushed to origin") is true.
#
# BARE-REMOTE PLACEMENT: the bares live at FIXED project-tmp paths
# (tmp/submodule-origin-2656-sc5.git, tmp/submodule-origin-2656-sc5-two.git)
# so they survive staging moves and are visible to the tier-2 container at
# the same absolute path (only tmp/ is mounted). Fixture failures are loud.

setup_2656_sc5() {
    local wd="$1"
    local sub="$wd/.opencode"
    local root
    root="$(cd "$wd/../.." && pwd -P)"   # project root (tmp/ parent)
    local bare="$root/tmp/submodule-origin-2656-sc5.git"
    local bare2="$root/tmp/submodule-origin-2656-sc5-two.git"

    git -C "$wd" config user.email "test@test.dev" 2>/dev/null || true
    git -C "$wd" config user.name "Test" 2>/dev/null || true
    git -C "$sub" config user.email "test@test.dev" 2>/dev/null || true
    git -C "$sub" config user.name "Test" 2>/dev/null || true

    # Parent repo name (for hash-permanence tag naming).
    local prepo
    prepo="$(basename -s .git "$(git -C "$wd" remote get-url origin 2>/dev/null || echo 'https://gitbucket.invalid/testproj.git')")"

    # 1. Fresh sandbox submodule remote, origin rewired, worktree at the tip.
    rm -rf "$bare" "$bare2"
    git init -q --bare "$bare" || return 1
    git -C "$sub" push -q "$bare" HEAD:refs/heads/main || {
        echo "HARNESS_FAILURE: 2656-sc5 fixture could not seed the sandbox submodule remote at $bare" >&2
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
    local tip
    tip="$(git -C "$sub" rev-parse HEAD)"

    # 2. Hash-permanence tag on the tip, pushed to the sandbox remote.
    git -C "$sub" tag -a "$prepo/377-.opencode" -m "hash-permanence: sub-two pointer promotion (ticket 377)" "$tip" 2>/dev/null || true
    git -C "$sub" push -q origin "refs/tags/$prepo/377-.opencode" || {
        echo "HARNESS_FAILURE: 2656-sc5 fixture — could not push the .opencode discipline tag" >&2
        return 1
    }

    # 3. Stale-baseline drift on parent main (committed, pushed), then the
    #    worktree returns to the tip — dirty pointer relative to main.
    local ancestor
    ancestor="$(git -C "$sub" rev-parse HEAD~40)" || return 1
    git -C "$sub" checkout -q --detach "$ancestor" || return 1
    git -C "$wd" add .opencode || return 1
    git -C "$wd" commit -q -m "chore: baseline stale submodule pointer" -- .opencode || return 1
    if git -C "$wd" remote get-url origin >/dev/null 2>&1; then
        git -C "$wd" push -q origin main:main || {
            echo "HARNESS_FAILURE: 2656-sc5 fixture — could not push the stale main baseline" >&2
            return 1
        }
    fi
    git -C "$sub" checkout -q -B main origin/main || return 1
    git -C "$sub" reset -q --hard origin/main || return 1

    # 4. Seed sub-two: 3 commits in a scratch repo, pushed to its own bare;
    #    registered in the parent at the Y1 commit; worktree moved to the tip.
    git init -q --bare "$bare2" || return 1
    local seed
    seed="$root/tmp/2656-sc5-two-seed"
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
    git -C "$seed" push -q "$bare2" HEAD:refs/heads/main || { echo "HARNESS_FAILURE: 2656-sc5 fixture — sub-two seed push failed" >&2; return 1; }
    rm -rf "$seed"
    # Register the submodule (recorded at main tip, c3) then move the record
    # back to c2 so the workspace drift (worktree at tip vs recorded c2)
    # exists relative to what the parent records.
    git -C "$wd" submodule add "$bare2" sub-two >/dev/null 2>&1 || {
        echo "HARNESS_FAILURE: 2656-sc5 fixture — could not register sub-two" >&2
        return 1
    }
    local t2
    t2="$(git -C "$wd/sub-two" rev-parse HEAD)"
    git -C "$wd" config user.email "test@test.dev"
    git -C "$wd" commit -q -m "chore: register sub-two submodule" -- sub-two .gitmodules || return 1
    git -C "$wd/sub-two" checkout -q "$c2" || return 1
    git -C "$wd" add sub-two || return 1
    git -C "$wd" commit -q -m "chore: baseline sub-two pointer at c2" -- sub-two || return 1
    if git -C "$wd" remote get-url origin >/dev/null 2>&1; then
        git -C "$wd" push -q origin main:main || {
            echo "HARNESS_FAILURE: 2656-sc5 fixture — could not push the sub-two baseline" >&2
            return 1
        }
    fi
    # Tag the drift SHA (c3) — pre-covered lineage — and push the tag.
    git -C "$wd/sub-two" tag -a "$prepo/377-sub-two" -m "hash-permanence: sub-two pointer promotion (ticket 377)" "$t2" || return 1
    git -C "$wd/sub-two" push -q origin "refs/tags/$prepo/377-sub-two" || {
        echo "HARNESS_FAILURE: 2656-sc5 fixture — could not push the sub-two discipline tag" >&2
        return 1
    }
    git -C "$wd/sub-two" checkout -q "$t2" || return 1   # dirty drift state

    # 5. Feature branch with real content, pushed — the PR premise holds.
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
            echo "HARNESS_FAILURE: 2656-sc5 fixture — could not push the feature branch" >&2
            return 1
        }
    fi
}

setup_2656_sc5 "$1"