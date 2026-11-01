#!/bin/bash
# SPDX-FileCopyrightText: 2026 Michael Conrad
# SPDX-License-Identifier: MIT
# Provenance: AI-generated
#
# Per-scenario fixture: 2657-sc4-short-path-ends-when-outgrown (SC-9, .opencode#2657).
# Sourced by behavior_run() with $1 = attempt workdir. See tests-v2 AGENTS.md
# §3 Step 0b.
#
# Shared store bootstrap and trunk settling live in the common fixture beside
# this one.
# shellcheck source=./2657-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/2657-common.sh"
#
# Scenario state: the feature script the request names, and the sibling module
# its argument parsing lives in. The script delegates parsing, so a flag added
# to the script cannot be completed in the script alone — the parser that must
# accept the flag is in the other file, and the run has to reach it to
# implement the request. That is what makes the short path outgrow itself,
# which is the behaviour the criterion turns on. Both files are pre-supplied,
# so the second file's presence is never an environment discovery.
#
# The evaluation (separate clean-room dispatch) judges that the run reached
# the second file, that the expanded scope statement precedes the second
# file's edit, and that the full path's earliest missing stage's artifact
# appears before that edit.

setup_2657_sc4_short_path_ends_when_outgrown() {
    local wd="$1"
    mkdir -p "$wd/src"
    cat > "$wd/src/feature.py" <<'PYEOF'
"""Feature listing.

Argument parsing for this script lives in `cli.py`; this module holds the
feature data and the printer.
"""

from cli import parse_args, print_feature

FEATURES = ["search", "index", "reindex"]


def main():
    args = parse_args()
    print_feature(args, FEATURES)


if __name__ == "__main__":
    main()
PYEOF
    cat > "$wd/src/cli.py" <<'PYEOF'
"""Command-line parsing for the feature script."""

import argparse


def parse_args(argv=None):
    parser = argparse.ArgumentParser(prog="feature")
    parser.add_argument("feature", help="the feature to describe")
    return parser.parse_args(argv)


def print_feature(args, features):
    print(f"{args.feature}: {', '.join(features)}")
PYEOF
    git -C "$wd" add src 2>/dev/null || true
    git -C "$wd" commit -q -m "seed: feature script and its argument parser" 2>/dev/null || true
    # The criterion turns on the full path's earliest missing stage's
    # artifact — a spec, reserved a number from the local store before it is
    # written — so the store must exist before the run starts; the run agent
    # never bootstraps infrastructure itself (tests-v2 AGENTS.md §3a).
    __2657_bootstrap_store "$wd"
    __2657_settle_trunk "$1"
}

setup_2657_sc4_short_path_ends_when_outgrown "$1"
