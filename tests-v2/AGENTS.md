# Behavioral Test Harness Specification (v2)

**Artifact-Only Generator Paradigm**

Every behavioral test script generates model-run artifacts and exits 0. Evaluation is the orchestrator's job — scripts NEVER evaluate model output.

> **MANDATORY: Bash tool timeout MUST be >= 600 seconds when running behavioral tests.**
> No `timeout` command inside scripts (nested timeouts create orphaned processes).
> See §Infrastructure Details — Bash Tool Timeout Mandate.

## Scope Anchor

**This behavioral test harness spec applies to `.opencode`-targeted work ONLY.** The harness and `opencode run` mechanics described here apply only to `.opencode`-targeted work; for any other spec target the harness is out of scope and `.opencode` SHALL NOT be modified — do not touch the `.opencode` submodule (or its test harness) to satisfy a mis-scoped mandate whose deliverables live elsewhere.

**R-6 routing directive:** Skill-deck defects discovered while working under a mis-scoped or differently-scoped mandate route via the `issues` card to this deck's upstream repo (the `owner`/`repo` whose `path` is `.opencode` in session-init's Repo Information) — agents do NOT patch local `.opencode` copies to escape a mis-scoped mandate.

## Key Differences from v1

| Aspect | v1 (`.opencode/tests/`) | v2 (`.opencode/tests-v2/`) |
|--------|------------------------|----------------------------|
| CLI binary | `opencode-cli` | `opencode` (resolved from PATH) |
| Model discovery | `opencode-cli models` | `opencode models` |
| Test runner | `with-test-home` (v1) | `with-test-home` (v2, rewritten) |
| Env isolation | Partial `env` passthrough | `env -i` with explicit allowlist |
| Smoke tests | Optional | Mandatory (`opencode models` + `opencode run "hello world"`) |
| Test project | Flat test home | `{test_home}/project/` with `git init` + local `.opencode` checkout |

## Table of Contents

1. [Paradigm: Artifact-Only Generators](#1-paradigm-artifact-only-generators)
2. [Artifact Directory Structure](#2-artifact-directory-structure)
3. [Writing a New Behavioral Test](#3-writing-a-new-behavioral-test)
4. [Running Tests](#4-running-tests)
5. [Infrastructure Details](#5-infrastructure-details)
6. [Relationship to Content-Verification Tests](#6-relationship-to-content-verification-tests)
6b. [Ceremony-Test Retirement Policy](#6b-ceremony-test-retirement-policy-cm-1-2489)
7. [Cleanup](#7-cleanup)
8. [Triple Co-Application Reference](#8-triple-co-application-reference)
9. [Change Control](#9-change-control)
10. [Testing Lessons Learned — Failure Patterns and Remediation](#10-testing-lessons-learned--failure-patterns-and-remediation)
11. [Prompt Construction Mandate](#11-prompt-construction-mandate)
12. [Self-Contained GitBucket Container for Remote API Tests](#12-self-contained-gitbucket-container-for-remote-api-tests)
13. [Remote-Strategy Flags and Full-Environment Simulation](#13-remote-strategy-flags-and-full-environment-simulation)
14. [Semantic Continuous Monitoring Mandate (Behavioral Runs)](#14-semantic-continuous-monitoring-mandate-behavioral-runs)

---

## 1. Paradigm: Artifact-Only Generators

A behavioral test script runs a model against a prompt, collects all output into `./tmp/`, writes a `manifest.yaml`, and exits 0. It NEVER calls assertion functions, NEVER runs evaluation logic, and NEVER produces a PASS/FAIL verdict.

**The script's job IS generation. The orchestrator's job IS evaluation.** A script that evaluates its own output has conflated two concerns — the artifact it produces is no longer a raw generation, and the evaluation cannot be independently verified by a clean-room sub-agent.

### MANDATORY: Every Script Must Include a Cross-Reference Header

Every `.sh` file in `tests-v2/behaviors/` must begin with:

```bash
#!/bin/bash
# Behavioral test: <scenario-name>
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.
```

### MANDATORY: Exit Code Is Always 0

All scripts exit 0 unconditionally after artifact generation. The exit code signals "run completed, artifacts produced" — NOT "test passed."

### PROHIBITED Patterns

| Pattern | Why Prohibited | Correct Pattern |
|---------|----------------|-----------------|
| `assert_*` function calls | Script conflates generation with evaluation | Script runs `behavior_run`, exits 0 |
| `assert_semantic` | FORBIDDEN — script conflates generation with evaluation | Script runs `behavior_run`, exits 0 |
| `OVERALL_RESULT` variable | Script tracks internal pass/fail | Script has zero pass/fail tracking |
| `exit $OVERALL_RESULT` | Non-zero exit signals evaluation FAIL | `exit 0` unconditionally |
| Inline grep/pattern checks | Script evaluates output | Script generates artifacts for evaluation |

### Evaluation Source: `session.yaml` (SQLite DB Export) is PRIMARY

**All behavioral SC evaluation MUST use `session.yaml` (the SQLite DB export) as the PRIMARY evidence source.** The `event` table in the SQLite DB records every tool call, reasoning step, and text part in chronological order — this is the authoritative record of what the agent actually did.

`stdout.log` contains only agent prose (chat output). `stderr.log` contains only the `TEST_HOME=<path>` marker for DB discovery. Neither is a reliable source for tool dispatch verification.

**Assertion helpers that grep stderr or stdout (`assert_semantic`, `assert_stderr_pattern_present`, `assert_required_pattern_present`, `assert_forbidden_pattern_absent`, `assert_tool_calls_made`, `assert_skill_called`, `assert_no_skill_called`) are FORBIDDEN for behavioral SC evaluation.** They operate on the wrong data source. All behavioral evaluation MUST use `session.yaml` via clean-room sub-agent inspection.

The `session-to-timeline` tool at `.opencode/tools/session-to-timeline` processes `session.yaml` into a condensed timeline of tool calls for evaluation. Use this for structured analysis of agent actions.

### Script Structure

```bash
#!/bin/bash
# Behavioral test: <scenario-name>
# See .opencode/tests-v2/AGENTS.md for the test harness specification and paradigm.
# This script is an artifact-only generator — it does NOT evaluate model output.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

SCENARIO_NAME="<scenario-name>"
SCENARIO_PROMPT="<prompt>"

behavior_run "$SCENARIO_NAME" "$SCENARIO_PROMPT"
exit 0
```

## 2. Artifact Directory Structure

Every `behavior_run` invocation produces an artifact directory at:

```
./tmp/behavioral-evidence-<SCENARIO_NAME>-<BEHAVIOR_PHASE>-<model-slug>/
```

**MANDATORY files:**

| File | Content | Required By |
|------|---------|-------------|
| `manifest.yaml` | Generation metadata (scenario, phase, model, timestamp, exit_code, harness_version) | Evaluation pipeline |
| `session.yaml` | SQLite DB → YAML export of the `event` table (tool calls, reasoning, text parts in chronological order) | **PRIMARY** evaluation source — all agent actions and decisions |
| `stdout.log` | Agent prose response (captured from `with-test-home` stdout) | Secondary — prose output only |
| `stderr.log` | `with-test-home` diagnostics including `TEST_HOME=<path>` for DB discovery | Infrastructure — DB path discovery only |
| `exit_code` | Numeric exit code from model run (0=OK, 1=harness failure) | Pipeline orchestration |

### Evaluation Source: `session.yaml` (SQLite DB Export) is PRIMARY

**`session.yaml` is the PRIMARY and ONLY reliable source for evaluating agent behavior.** It contains the full `event` table export — every tool call, reasoning step, and text part in chronological order with timestamps. This is the authoritative record of what the agent actually did.

`stdout.log` contains only the agent's prose response (what it wrote to chat). It is NOT a reliable source for tool dispatch verification — tool calls are recorded in the SQLite `event` table, not in stdout. `stderr.log` contains only the `TEST_HOME=<path>` marker used to discover the SQLite DB path.

**Assertion helpers that grep stderr or stdout (`assert_semantic`, `assert_stderr_pattern_present`, `assert_required_pattern_present`, etc.) are FORBIDDEN for behavioral SC evaluation.** They operate on the wrong data source. All behavioral evaluation MUST use `session.yaml` (the SQLite DB export) via clean-room sub-agent inspection.

### `session.yaml` Export Mechanism

The `__export_sqlite_to_yaml` function in `helpers.sh` discovers the test home SQLite DB by parsing `TEST_HOME=<path>` from stderr (emitted by `with-test-home`), then exports all tables to JSON/YAML. The `session-to-timeline` tool further processes this into a condensed timeline of tool calls for evaluation.

If `session.yaml` contains `source_db: MISSING`, the SQLite DB was not found in the test home. This is a **hard FAIL** — the test environment is broken. Do NOT hunt for the DB elsewhere, do NOT substitute with stderr/stdout grep, do NOT synthesize or fabricate data. The only recovery mechanism is to verify the test does not violate clean-room separation mandates: the test must use a dedicated test home directory with the test project inside it, and `with-test-home` must emit `TEST_HOME=<path>` to stderr.

## 3. Writing a New Behavioral Test

### Step 0: Create Fixture Issues (MANDATORY if test references issue content)

If the test prompt references a spec, plan, or any issue content (e.g., a fixture issue's `spec.md` path), the test MUST have corresponding fixture files in `fixtures/issues/{N}/`. The harness auto-injects all fixture issue directories into the test repo's `.issues/` directory via `setup_fixture_issues()`.

**Fixture creation procedure:**

1. Create the fixture directory: `mkdir -p .opencode/tests-v2/behaviors/fixtures/issues/{N}/`
2. Copy the spec, plan, and any other files the test needs:
   ```bash
   cp .opencode/.issues/{N}/spec.md .opencode/tests-v2/behaviors/fixtures/issues/{N}/
   cp .opencode/.issues/{N}/plan.md .opencode/tests-v2/behaviors/fixtures/issues/{N}/
   ```
3. The harness injects these into the test repo at `.issues/{N}/` (flat path) and `.issues/open/{N}/` (open directory).

**🚫 FORBIDDEN:** Writing a test that references issue content without creating fixture files. The test will fail at runtime because the issue directory doesn't exist in the isolated test environment.

**✅ REQUIRED:** Every test that references `.issues/{N}/` paths in its prompt MUST have corresponding fixture files. The prompt path MUST use `.issues/{N}/` (the root-level path injected by fixtures), NOT `.opencode/.issues/{N}/` (the submodule path which is not injected).

### Step 0b: Create Per-Scenario Fixture Scripts (for repo state setup)

If the test requires specific repo state (branches, remotes, tags, stashes) before the model runs, create a per-scenario fixture script in `fixtures/setup/`. The harness sources `fixtures/setup/<scenario-name>.sh` with the workdir path as the first argument, before `behavior_run` calls `opencode run`.

**Fixture creation procedure:**

1. Create the fixture script: `mkdir -p .opencode/tests-v2/behaviors/fixtures/setup/`
2. Write a script that accepts `$1` as the workdir path and sets up the required state:
   ```bash
   # .opencode/tests-v2/behaviors/fixtures/setup/<scenario-name>.sh
   # Per-scenario fixture: create branches for dead-branch detection test.
   setup_dead_branches() {
       local wd="$1"
       git -C "$wd" checkout -b feature/dead-branch main 2>/dev/null || true
       echo "# pointer change" >> "$wd/.gitmodules"
       git -C "$wd" add .gitmodules 2>/dev/null || true
       git -C "$wd" commit -m "chore: update pointer" 2>/dev/null || true
       git -C "$wd" checkout main 2>/dev/null || true
   }
   setup_dead_branches "$1"
   ```
3. The harness auto-injects the fixture by sourcing `fixtures/setup/<scenario-name>.sh` with the workdir path.

**Shared fixture code:** Place common setup logic in `fixtures/setup/<name>-common.sh` and source it from per-scenario scripts to avoid duplication.

**🚫 FORBIDDEN:** Modifying `helpers.sh` to add scenario-specific flags (`BEHAVIOR_SETUP_*`). The harness is shared infrastructure — per-scenario state belongs in `fixtures/setup/`.

**✅ REQUIRED:** Every test that requires specific repo state (branches, remotes, tags) MUST have a corresponding fixture script in `fixtures/setup/`. The script name MUST match the `SCENARIO_NAME` exactly.

### Step 1: Create the Script

Copy `template.sh` to a new file with a descriptive name. Set `SCENARIO_NAME` (kebab-case), `SCENARIO_PROMPT` (the message sent to the model), and `SCENARIO_TIER` (the execution tier — new scenarios default to tier-2, the Docker harness; tier-1 scenarios are never model runs; tier-3 designates a host harness run).

### Step 2: Run the Script

```bash
bash .opencode/tests-v2/behaviors/<scenario>.sh
```

### Step 3: Verify Artifacts

```bash
ls ./tmp/behavioral-evidence-<scenario>-GREEN-<model>/
```

Expected: `manifest.yaml`, `stdout.log`, `stderr.log`, `exit_code`, `session.yaml`.

## 3a. Pre-Supplied Environment Mandate (developer directive 2026-10-15)

**Every behavioral test run MUST be pre-supplied with everything its task needs. The run agent starts at the task's action step — never at environment archaeology.** This is a hard mandate on the harness and scenario authors, not on the model:

| Need | Pre-supplied by |
|------|-----------------|
| Platform tooling | The image bakes the deck-mandated CLIs (`gb`, `gh`) at build time — a deck-mandated tool the run agent cannot find is a harness defect (see §5 base-tool baseline) |
| Authenticated remote | `BEHAVIOR_NEEDS_REMOTE` (GitBucket container + minted `GB_TOKEN`) or `BEHAVIOR_SET_BARE_REMOTE` — wired before the model runs |
| Issue store | The per-scenario setup fixture bootstraps the store (`local-issues init`/`sync`) when the scenario involves issue operations — the agent never discovers store layout from zero |
| Repo state | Branches/remotes/tags/stashes via `fixtures/setup/<scenario>.sh` |
| Credentials/env | Isolated env (`GB_TOKEN`, `GITBUCKET_PORT`, …) exported by the harness — never hunted by the agent |

**Corollaries:**

1. **The run agent is never required to discover or improvise infrastructure** — platform identity, API surface, auth shape, CLI availability, or store layout. A scenario whose task only becomes executable after the agent reverse-engineers the environment is mis-authored: fix the fixtures/image, never the prompt's tolerance for improvisation.
2. **Run time spent on environment discovery is a harness/scenario defect** (R-18 classes: fixture state, harness behavior) — never attributed to the model. Do not remediate discovery burn by changing prompts to "explore more carefully"; remove the need to explore.
3. A scenario authoring a task the pre-supplied environment cannot start is a spec/scenario defect — re-scope at the spec; never weaken isolation and never change the model (R-20).
4. **Re-scope on need (.opencode#2665, 2026-10-27).** When a behavioral scenario's run agent cannot reach its action sequence under the harness's bounded model constraints — the observed forms: the run exits at a bounded-generation turn (cap-hit `finish: length` treated as the session's final answer), or the run stalls in re-planning without goal-relevant completed tool calls — the scenario is **re-scoped, not retried and not escalated without a re-scope first**. The re-scope surfaces are the scenario's own authoring inputs: the fixture (pre-supply facts the task needs — §3a's whole mandate), the prompt (task shape that starts the run agent at the action step rather than at checklist re-derivation), the declared goal condition (`BEHAVIOR_EXPECTED_ARTIFACT` / `BEHAVIOR_EXPECTED_ARTIFACT_GREP` / `BEHAVIOR_GOAL_ACTIONS`, without which the classifier cannot separate progressing from undetermined and halts monitoring), and the staged boundary state (repo/branch/fixture-issue state that makes the boundary decision the run's first action). Every re-scope is recorded in the scenario file (comment block) with its run-number provenance. Blind retry of a truncated run — and escalating to the developer without first exhausting the re-scope surfaces — are the two failure forms this rule replaces (observed record: `.opencode#2665` SC-5 runs 1–4, 2026-10-27). **Sanctioned remediation directives (developer, 2026-10-27):** (a) **resume halted sessions** — when a run's test home survives with its session store intact — across a failure, abort, capped exit, or supervisor kill — recovery is `with-test-home --resume-home <prior-home> opencode run --continue` (or `--session <id>`, plus the turn-directive resume-message form), never a fresh restart from scratch — the completed tool calls, reasoning, and context carry forward; (b) **scenario pre-setup with all prereqs pre-supplied is acceptable** — staging the scenario's environment so fully (completed-gate artifacts, boundary state, and every fact the task needs already on disk, the run agent's first action being the task itself) is a sanctioned form of re-scope, and is preferred over burning inference on re-derivation. **Restarting over resuming is the supervision defect (developer directive, 2026-10-27; observed recidivism in the same session: repeated recovery passes re-provisioned fresh state while a surviving home carried the work forward — re-paying every completed turn's inference and discarding the run agent's context).** Fresh homes are for a new scenario, a fixture/pre-supply-state change, or a determination-recorded terminate-with-root-cause — never for a failure or truncation the surviving context can carry forward. The recovery affordances (`__resume_on_cap_hit`, `--resume-home`, the directive-resume message, `BEHAVIOR_SEMANTIC_MONITOR=1` sessions for gated resumption) make resumption the cheap path — the supervisor's obligation is to take it first. **Bounded-generation raise (.opencode#2665 revision):** when a scenario's legitimate turns hit the output-token cap, the raise to `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` is a spec-gated, scenario-scoped re-scope (tests-v2 §5; the Docker env passthrough and the §14 classifier seeder carry the value as an env default, so an explicit caller value reaches them).

---

## 4. Running Tests

### The Ordered Precondition Cycle — Required for ALL Behavioral Runs

Before any behavioral test invocation, the preconditions must hold in this exact order — **commit → push → fetch/verify → run**:

| Step | Action | Verification |
|------|--------|--------------|
| 1. commit | Commit all `.opencode` submodule working-tree changes | Submodule working tree clean (`git status --porcelain` empty) |
| 2. push | Push the effective commit to its remote branch | `git push` succeeds for the branch carrying the effective commit |
| 3. fetch/verify | Perform a fresh `git fetch`, then verify the effective commit is contained in a remote ref | `git branch -r --contains <effective-commit>` returns at least one remote ref after the fresh fetch |
| 4. run | Invoke the behavioral test | Only after steps 1–3 pass |

This cycle is required for all behavioral runs — every behavioral run tests the effective submodule commit as it exists on the remote, never local-only state. The scope is not limited to a `DEFAULT_TEST_MODEL` override or any other environment variable: an unpushed or uncommitted submodule state invalidates the run regardless of which model or phase is requested.

The documented cycle mirrors the harness gate predicate exactly (single definition, R-10): **submodule working tree clean (`git status --porcelain` empty) AND effective commit contained in a remote ref after a fresh `git fetch`.** That predicate is enforced mechanically at two surfaces: the `behavior_run()` pre-flight git-state gate (`.opencode/tests-v2/behaviors/helpers.sh`, firing before the flock and before any model dispatch) and the `with-test-home` clone+checkout gates. All of these hard-FAIL (exit 1) on dirty or unpushed submodule state, and their failure messages name the commit+push+fetch remediation using the `FATAL:`/`HARNESS_FAILURE:` stderr-prefix conventions. The effective commit honors `BEHAVIOR_SUBMODULE_COMMIT` when pinned — the pin is verified against the remote, never bypassed.

### Single Scenario

```bash
bash .opencode/tests-v2/behaviors/<scenario>.sh
```

### Tier Routing (.opencode#2582)

Every scenario script carries a machine-readable tier designation
(`SCENARIO_TIER`) that routes its execution:

| Tier | Execution | Designation |
|------|-----------|-------------|
| 1 | Clean-room sub-agent dispatch (no model run through the harness) | Recorded prompt + verdict in the owning issue's artifact area |
| 2 | Docker harness — `behavior_run` launches `with-test-home` inside the test container (`docker run -d --network host`, only-`tmp/` mounts, host-uid) | Default for new scenarios |
| 3 | Host harness — unchanged host launch path | Explicit designation only (scenarios that fight the container) |

`behavior_run()` dispatches on the tier: tier-2 stages the harness scripts
under `tmp/` scratch and runs the container; tier-3 keeps the host process
launch. All host-side machinery (flock, artifact export, `poll-run.sh`, the
§14 monitor, the artifact-copy pipeline) reads `tmp/` and is unchanged.

### Scope-Filtered Runs

```bash
bash .opencode/tests-v2/test-enforcement.sh --tag <tag>
```

### Model Override

```bash
DEFAULT_TEST_MODEL="ollama/other-model:tag" \
BEHAVIOR_PHASE="RED" \
bash .opencode/tests-v2/behaviors/<scenario>.sh
```

The model override selects which model runs — it does not change the preconditions. The ordered cycle above applies to override runs exactly as to default runs: the harness clones `.opencode/` from remote and checks out the local submodule HEAD commit, so unpushed changes (including `seed_model_config()` fixes, applied in commit `f5c66371`) are invisible to the clone until the commit+push steps of the cycle land them on the remote.

**🚫 FORBIDDEN:** Asking the developer for authorization to push test framework fixes. Test framework changes that fix broken behavior are not implementation — they are infrastructure maintenance. The agent commits and pushes autonomously. The earlier pattern of asking "authorize push?" for a test harness bugfix was a routing-bypass self-authorization violation. This test-framework infrastructure-maintenance carve-out is the authorization basis for the commit → push → fetch/verify → run cycle above: it extends to all behavioral runs and is never re-scoped to a single environment variable.

## 5. Infrastructure Details

### Binary

- **`opencode`** is copied from `.tools/opencode/opencode` into `$TEST_HOME/bin/opencode` by `with-test-home`. The `OPENCODE_CMD` variable is set to `("$TEST_HOME/bin/opencode")` — the test-home path, never a prod path.
- **NEVER resolve from PATH** — `command -v opencode` may find `/snap/bin/opencode` which hardcodes `SNAP_USER_DATA=~/snap/opencode/` and leaks production state.
- **NEVER hardcode `/snap/bin/opencode`** — the snap wrapper ignores `$HOME` and writes to the production SQLite DB.

**Why copy instead of PATH resolution:** The snap wrapper at `/snap/bin/opencode` → `/usr/bin/snap` ignores `$HOME` and hardcodes `SNAP_USER_DATA=~/snap/opencode/`, which leaks production state into test environments. Copying the standalone binary into the test home ensures the test uses the correct binary with the test home's `SNAP_USER_DATA` override.

**If the binary location changes**, update the `STANDALONE_BINARY` path in `with-test-home` and the test runner scripts.

### `with-test-home` — Fully Isolated Test Runner

**MUST be used for ALL opencode testing.** Never run `opencode run` directly — it causes SQLite session conflicts with the desktop app and leaks production state.

The wrapper creates an isolated temporary home directory (`tmp/test-home-<timestamp>`) with clean XDG state and runs commands inside a `env -i` subshell.

#### Environment Variable Isolation

Uses `env -i` with an explicit allowlist. Only these variables are passed through:

| Variable | Source | Purpose |
|----------|--------|---------|
| `HOME` | Set to test home | Isolates snap data, XDG state, and all home-directory config |
| `PATH` | Parent env | Allows opencode and other tools to be found |
| `XDG_CONFIG_HOME` | Set to test home | Isolates opencode config |
| `XDG_CACHE_HOME` | Set to test home | Isolates cache |
| `XDG_RUNTIME_DIR` | Set to test home | Isolates runtime files |
| `XDG_DATA_HOME` | Set to test home | Isolates data (SQLite DB, repos) |
| `XDG_STATE_HOME` | Set to test home | Isolates state (locks) |
| `SNAP_USER_DATA` | Set to test home | Overrides snap's hardcoded `~/snap/opencode/` to prevent production DB pollution |
| `SNAP_USER_COMMON` | Set to test home | Overrides snap's common data directory |
| `GIT_CONFIG_NOSYSTEM` | `1` | Prevents system git config from leaking |
| `SHELL` | Parent env | Required by some tools |
| `USER` | Set to `opencode-test-user` | Test identity |
| `LOGNAME` | Set to `opencode-test-user` | Test identity (hardcoded, not parent env leak) |
| `LANG` | Parent env | Locale |
| `TERM` | Parent env | Terminal type |
| `GB_TOKEN` | Parent env (if set) | GitBucket API token |

**FORBIDDEN** — no `GITHUB_TOKEN`, `GH_TOKEN`, `OPENCODE_CONFIG_CONTENT`, `NODE_ENV`, `VIRTUAL_ENV`, `CONDA_DEFAULT_ENV`, or shell-specific vars.

#### Working Directory

The command runs from `TEST_PROJECT` (the test project directory inside the test home). This ensures opencode discovers the test project's `.opencode/` as its project root, not the production project's.

#### Submodule Checkout

`.opencode/` is cloned from the remote URL (not `cp -a` from the parent repo). After cloning, the test harness checks out the same commit as the local `.opencode` submodule HEAD to pick up feature branch changes.

**If that commit is not on the remote (unpushed local HEAD), the checkout cannot succeed and the invocation hard-FAILS with exit 1 and a `HARNESS_FAILURE:` message — no test home is produced:**

```text
HARNESS_FAILURE: could not checkout local submodule commit <SHA> — the SHA is not on the remote. Commit and push the submodule change, then fetch and re-run the test framework. No test home is produced; refusing to run on the wrong ref.
```

**A run that tests code it never checked out issues PASS/FAIL verdicts about code the branch does not contain — the harness refuses to run on the wrong ref rather than proceed on any substitute ref.**

**Feature branch changes MUST be pushed to remote before running tests.** The clone from remote ensures the test environment has a clean git history and proper submodule state. This checkout gate is one enforcement surface of the §4 ordered precondition cycle (commit → push → fetch/verify → run): same predicate — effective commit contained in a remote ref after a fresh fetch — enforced mechanically.

#### Model Config Generation

`seed_model_config()` generates a minimal `opencode.jsonc` with:
- `"model": "$default_model"` — uses `DEFAULT_TEST_MODEL` env var (falls back to `ollama/qwen3.8:27b-128k-gguf4`). This is the single source of truth for which model runs the test.
- `"models": { "$bare": {} }` — only the requested model is registered. No hardcoded model entries.

The `model` field MUST match the `DEFAULT_TEST_MODEL` value. Previously the function hardcoded `"model": "ollama/ornith:35b-256k"` regardless of `DEFAULT_TEST_MODEL`, which caused behavioral tests to always attempt loading ornith (21GB) even when a smaller model was requested via env var. This is now fixed — the `model` field is dynamically interpolated from `$default_model`.

It does NOT copy the production `opencode.jsonc` — that file contains secrets, API keys, and environment-specific settings that must not leak into test environments.

#### Seeded Permission Policy — `external_directory` Containment

The seeded config carries a `permission.external_directory` block that denies tool access to paths outside the test home (`#2579` containment layer, spec `.issues/2579/spec.md` in the issues-data store). The policy, in last-match-wins order:

1. `"**": "deny"` — catch-all deny for every external path;
2. `"~"` and `"~/**": "allow"` — the test home itself (`~` expands against the runtime `HOME`, which is the test home under `env -i`), covering the seeded gb config, test-home tooling, and the harness's auto-allowed tool-output directory;
3. `"/tmp"`, `"/tmp/**"`, `"/var/tmp"`, `"/var/tmp/**": "allow"` — public scratch space normal tooling legitimately uses (`mktemp`, compilers, editors); no harness isolation surface lives there (the harness `tmp/` is the project's `tmp/`, not `/tmp`).

Both config seeders carry the identical policy: `seed_model_config()` and the §14 classifier-home seeder in `behaviors/helpers.sh`.

**Known residual — tool-surface hardening, not structural containment.** The permission layer fires on path-argument tools (`read`, `edit`, `glob`, `grep`) and is command-selective for bash: `cat` with an external path is caught, while `ls`, `grep`, `head`, and `sed` with absolute host paths bypass it (observed 2026-10-11; a run agent adapted from denied reads to bash extraction within one turn). Structural containment — the filesystem boundary that makes host paths unreachable regardless of tool — is the `.opencode#2582` layer (Dockerized execution, only-`tmp/` mounts). This policy composes with that layer; it does not replace it. A behavioral SC that legitimately needs a production path is a spec problem: re-scope the SC, never weaken this policy (clean-room mandate).

#### uv/uvx Copy

`do_setup()` copies `uv` and `uvx` from `.tools/uv/` into `$TEST_HOME/bin/` so opencode can use them for Python-based plugin operations (e.g., vibeguard plugin npm installs). If `uv` is not found at `.tools/uv/uv`, the script exits with a FATAL error.

#### set-env.sh Debugging Aid

`do_setup()` writes `set-env.sh` into `$TEST_HOME/` with all `env -i` variables for debugging. This allows reproducing the test environment outside the harness:

```bash
source $TEST_HOME/set-env.sh
```

The file includes: HOME, PATH, XDG_CONFIG_HOME, XDG_CACHE_HOME, XDG_RUNTIME_DIR, XDG_DATA_HOME, XDG_STATE_HOME, SNAP_USER_DATA, SNAP_USER_COMMON, USER, GIT_CONFIG_NOSYSTEM, SHELL, LOGNAME, LANG, TERM, GB_TOKEN, GB_HOST, GITBUCKET_PORT.

#### SQLite DB Export on Timeout

`__export_sqlite_to_yaml()` in `helpers.sh` searches both stdout and stderr for `TEST_HOME=<path>` to discover the SQLite DB. Previously it only searched stdout — when a behavioral test timed out, stdout was empty and the export produced `source_db: MISSING`. Now it falls back to stderr, which always contains the `TEST_HOME=` marker emitted by `with-test-home`.

#### Isolation Verification Procedure

After running `with-test-home --setup`, verify isolation by inspecting the SQLite DB:

```bash
sqlite3 $TEST_HOME/.local/share/opencode/opencode.db "SELECT worktree FROM project;"
# Expected: /path/to/tmp/test-home-<timestamp>/project
# NOT:      /home/user/git/production-project
```

The `project.worktree` field MUST contain the test project path (under `tmp/test-home-*`), not the production project path. If it contains the production path, isolation is broken.

### Test Environment Setup Steps

1. Create test home directory at `{project_root}/tmp/test-home-{timestamp}`
2. Set `HOME` and all XDG vars to test home paths
3. Set `SNAP_USER_DATA`/`SNAP_USER_COMMON` to test home paths (overrides snap's hardcoded `~/snap/opencode/`)
4. Set `PATH` to parent env PATH only
5. Create test sub-folder: `{test_home}/project/`
6. `git init` the test sub-folder
7. Clone `.opencode/` from remote, then checkout local submodule commit
8. Copy standalone binary from `.tools/opencode/opencode` to `$TEST_HOME/bin/opencode`
9. Copy `uv` and `uvx` from `.tools/uv/` to `$TEST_HOME/bin/`
10. Write `set-env.sh` into test home with all `env -i` variables
11. Seed `opencode.jsonc` config with `model` set to `DEFAULT_TEST_MODEL` (dynamic, not hardcoded)
12. Run `opencode models` to verify CLI works (smoke test)
13. Run `opencode run "hello world"` to verify model works (smoke test)

### Smoke Test Requirements

Both smoke tests MUST pass before the test home is considered ready:
- `opencode models` must return at least one `ollama/` model
- `opencode run "hello world"` must produce non-empty output without errors

### Bounded Per-Turn Generation — `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX`

The harness sets `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` (default 4000) at
every environment surface it controls (the `with-test-home` `env -i`
allowlist and its `set-env.sh` debug export, both as a `${...:-4000}` env
default overridable only by a deliberate probe; the Docker-tier
`docker_env` passthrough and the §14 classifier-home seeder as literal
4000). What it bounds: the output-token budget of each assistant
generation — opencode feeds the flag into `maxOutputTokens` per generation
call (verified on both runtime binaries: host `.tools` 1.18.3 and the
Docker image's 1.19.0). Why: unbounded single-turn generation was the
run-fatal mechanism in the #2639 SC-7 attempts — degenerate reasoning
blocks of 4,140–6,030 tokens over 8.5–19 minutes with no tool-call flush
killed six runs; 4,000 sits at the boundary of the observed healthy-turn
range (1,000–4,100) and below the smallest degenerate turn. What happens
on a hit: the turn ends with a `length` finish and terminates cleanly
(verified empirically: a capped smoke run recorded `finish: "length"`,
`output: 60`, CLI exited without error). **In an agentic run a cap hit
ends the session**: truncation mid-reasoning issues no tool call, so
opencode's loop treats the turn as the agent's final answer and exits
(observed: attempt 7, `finish: length`, `output: 4000`, `exiting loop`
one second after the request returned, run exit 0 with the goal unreached).
The composition that keeps the run alive is the resume-on-cap-hit step in
`behavior_run()` (`.opencode#2646` R-4): for monitored runs, a session
whose last assistant message carries `finish: length` is resumed via the
§10.7 machinery (`with-test-home --resume-home <home> opencode run
--continue` — host tier; the docker tier resumes via a second container
run with the same `--resume-home` form against the staged home), bounded
by a per-attempt resume ceiling; unmonitored runs are out of the resume
path and export their evidence at the capped exit. Supervision
relationship: a cap hit presents as normal turn cadence to the §14 monitor
and the agent supervisor — it is NEVER an abort signal; §17's excessive
run-time cause analysis still applies to the run aggregate, and a scenario
whose legitimate turns routinely hit the cap is re-scoped at the spec
(value raises are a one-line change to the four surfaces), never by model
substitution (R-20).

### Concurrency Lock — `flock`

The harness uses `flock` (file lock) for mutual exclusion. A lock file at `tmp/.behavior-run.lock` is acquired via `flock -x -w 30` before the model run. The SC-9 undetermined-cycle counter and its ceiling gate use a dedicated lock domain (the counter state file's own `.lock` file, `.opencode#2649`) — never the run-loop lock — so concurrent recording does not contend with a monitored run.

### Bash Tool Timeout Mandate — ZERO TOLERANCE

**The bash tool's `timeout` parameter is the ONLY kill signal that may be used when running behavioral tests.** Any use of the `timeout` command (GNU timeout) inside a bash script invoked by the bash tool is FORBIDDEN — nested timeouts create orphaned processes that hold the flock lock and hang all subsequent test runs.

**Mandated bash tool invocation:**
```
# timeout=600000 (600 seconds, milliseconds). NEVER omit.
```

### Timeout Export Procedure — MANDATORY

When a behavioral test times out (bash tool kills the script), the agent MUST NOT retry blindly. Instead:

1. **Locate the test home directory** — the most recent `tmp/test-home-{timestamp}/` directory. The test harness creates one per run.
2. **Export the SQLite DB** — the DB survives the timeout. Export it to the artifact directory:
   ```bash
   mkdir -p tmp/behavioral-evidence-{scenario}-{phase}-{model}/
   python3 -c "
   import json, sqlite3
   db = 'tmp/test-home-{timestamp}/.local/share/opencode/opencode.db'
   conn = sqlite3.connect(db)
   conn.row_factory = sqlite3.Row
   c = conn.cursor()
   c.execute('SELECT * FROM event ORDER BY id')
   events = [dict(r) for r in c.fetchall()]
   result = {'source_db': db, 'harness_version': 1, 'tables': {'event': {'columns': ['id','aggregate_id','seq','type','data'], 'rows': events}}}
   with open('tmp/behavioral-evidence-{scenario}-{phase}-{model}/session.yaml', 'w') as f:
       json.dump(result, f, indent=2, default=str)
   "
   ```
3. **Inspect the agent's reasoning** — read the `message.part.updated.1` events from the exported session.yaml. The agent's text parts show what it was doing, what it found, and where it was when the timeout hit.
4. **Check tool calls** — if the agent made tool calls (read, grep, skill, task), the behavior is being tested. The timeout is a model speed issue, not a test defect.
5. **Adjust the prompt or fixtures** based on what the agent was doing at timeout:
   - If the agent was still reading/planning with zero tool calls → prompt is too complex, simplify it
   - If the agent was verifying SCs and found the right things → behavior is correct, timeout is just model speed
   - If the agent was going in the wrong direction → fix the prompt or fixtures
6. **Document the finding** — if the exported session.yaml shows correct behavior, that IS the behavioral evidence. The timeout does not invalidate the evidence the agent produced up to that point.

**🚫 FORBIDDEN:** Retrying the same test with the same configuration expecting a different result, and switching to a different model to work around a failing or slow test (model-shopping). Behavioral tests run on the harness default model — the single source of truth `DEFAULT_TEST_MODEL` in `default-model.sh` (Default-Model Mandate, R-20) — unless the user explicitly directs otherwise; substituting another model on the agent's own initiative is PROHIBITED. Remediation targets the R-18 defect classes (instructions, task-card/skill-deck wording, prompt construction, fixture state, harness behavior — e.g., simplify the prompt, fix the fixture, or raise the bash-tool timeout per this section) — never model selection. Do not burn compute cycles on the same failing configuration.

### Test Isolation Mandates — ZERO TOLERANCE

The following mandates are non-waivable. Violation = pipeline halt.

| # | Mandate | Enforcement |
|---|---------|-------------|
| 1 | **`snap run` is FORBIDDEN** — `snap run opencode` hardcodes `SNAP_USER_DATA=~/snap/opencode/` and writes to the production DB. The only acceptable reference to `snap run` is as a forbidden pattern example in comments. | grep for `snap run` in executable code returns 0 matches |
| 2 | **`/snap/bin/opencode` is FORBIDDEN** — never hardcode the binary path. Always resolve `opencode` from PATH. | grep for `/snap/bin/opencode` returns 0 matches |
| 3 | **`timeout` command (GNU timeout) is FORBIDDEN** in test scripts. The bash tool `timeout` parameter is the ONLY kill signal. | grep for `^timeout ` in test scripts returns 0 matches |
| 4 | **`USER=opencode-test-user` MUST be set** in the test environment. Tests must use a non-production user identity. | grep for `opencode-test-user` in `with-test-home` returns match |
| 5 | **Default model MUST NOT be changed** without an approved spec. `DEFAULT_TEST_MODEL` in `default-model.sh` is the single source of truth. | grep for model strings outside `default-model.sh` returns 0 matches |
| 6 | **Smoke test is MANDATORY** — `opencode models` + `opencode run "hello world"` must pass before the test home is considered ready. | `do_setup()` in `with-test-home` runs both |
| 7 | **Isolation verification is MANDATORY** — after warmup, verify test home only contains opencode config/db/log files and production DB is untouched (sha256 comparison). | `do_setup()` in `with-test-home` runs isolation check |

### Docker Execution Tier — Isolation Contract (tier-2, .opencode#2582)

The Docker tier replaces the host's procedural isolation with structural
containment. The contract, verified by `docker inspect` and container-exec
probes:

| Element | Contract |
|---------|----------|
| Execution uid | Container runs as the invoking user's uid:gid (`--user`, never root) — no root-owned files under `tmp/` |
| Mount boundary | The ONLY host mount is the project's `tmp/` directory, mounted at the SAME absolute path inside the container (so `TEST_HOME=` markers and artifact paths are directly valid host-side). No production path — `.tools/`, the repo worktree outside `tmp/`, `$HOME`, either `.issues/` store — is mounted into, or copied into, the container |
| Test home | Starts BARE of agent-managed tooling: `with-test-home` skips the binary/uv copy steps on the Docker path (`TEST_ENV=docker`); everything the agent would manage in real work starts absent |
| Base-tool baseline | The image bakes the sanctioned base system tools (opencode, uv/uvx, git, python3, curl) at build time from official upstream channels at pinned versions — the harness's own instruments, reviewable in `tests-v2/docker/Dockerfile.test-agent` — **plus every deck-mandated platform CLI the scenarios exercise (`gb`, `gh`)**. A deck-mandated tool absent from the image is a harness defect: fix the image, never work around it in the scenario or the run agent. |
| Network posture | `--network host` — network-neutral versus host-mode runs; host Ollama is reached unchanged at `http://localhost:11434/v1`; no URL parameterization anywhere |
| GPU exclusion | No GPU tooling in the image (developer directive). Known, accepted delta: an in-container agent cannot observe GPU state via `nvidia-smi`/`ollama-probe hw` — scenarios requiring GPU observation are tier-3 candidates |
| Display | Xvfb on `:99` (started by the image entrypoint) with openbox, scrot, xdotool — the container's screenshot affordance |

Test homes, artifacts, the live session DB, and the staging scratch all live
under the project's `tmp/` (Docker-tier homes under
`tmp/docker-staging/tmp/test-home-*`), keeping `poll-run.sh`,
`__export_sqlite_to_yaml()`, the §14 monitor, and the two-SC pattern
host-side and unchanged. The abort path is `docker stop` + `docker rm -f` —
a guaranteed whole-tree kill (§14 abort; R-5). GNU `timeout` remains
forbidden on both tiers.

### Invocation Examples

```bash
# Run a single test message
bash .opencode/tests-v2/with-test-home opencode run "hello" --model ollama/qwen3.8:27b-128k-gguf4

# Setup only (create env, run smoke tests, print path)
bash .opencode/tests-v2/with-test-home --setup

# Clean up the most recent test home
bash .opencode/tests-v2/with-test-home --clean

# Clean up ALL test homes
bash .opencode/tests-v2/with-test-home --clean-all
```

## 6. Relationship to Content-Verification Tests

| Test Type | Role | What It Proves | Scope |
|-----------|------|----------------|-------|
| Behavioral (this directory) | Artifact generation | Model produced output for a scenario | Runs model, dumps artifacts |
| Content-verification (`test-enforcement.sh`) | Text presence | Rule text exists in the right file | Greps files, no model needed |

## 6a. Two-SC Pattern: Artifact Generation + Clean-Room Evaluation

Every behavioral test (artifact-only generator) MUST be paired with a spec SC that dispatches a clean-room sub-agent to evaluate the generated artifacts. A single SC that both runs `opencode run` and evaluates the output conflates two concerns — the evaluation cannot be independently verified. The clean-room evaluation is a SEPARATE dispatch from the artifact-generation run: SC-N runs the artifact-generating behavioral test, and SC-N+1 is dispatched as its own clean-room sub-agent afterwards — the two runs are never merged into a single dispatch.

### The Pattern

| SC | Evidence Type | Action | Depends On |
|----|--------------|--------|------------|
| SC-N | `behavioral` | Run `opencode run` via behavioral test script, produce artifacts (session.yaml, stdout.log, stderr.log) | Nothing |
| SC-N+1 | `behavioral` | Dispatch clean-room sub-agent to read session.yaml and evaluate agent actions against the criterion | SC-N (artifacts must exist) |

### Why Two SCs

- **SC-N (artifact generation):** The behavioral test script runs the model and exits 0. It does NOT evaluate — it only generates. This SC passes when artifacts are produced (exit code 0, session.yaml exists).
- **SC-N+1 (clean-room evaluation):** A clean-room sub-agent reads the session.yaml (the SQLite DB export — the PRIMARY evidence source per §2) and judges whether the agent's tool calls, reasoning, and decisions satisfy the behavioral criterion. This sub-agent receives ONLY the artifact path and the SC criterion — no orchestrator context, no expected outcomes, no cached results.

### Prohibited Patterns

| Pattern | Why Prohibited |
|---------|----------------|
| Single SC that both runs `opencode run` and asserts on output | Conflates generation and evaluation; evaluation cannot be independently verified |
| Assertion helpers (`assert_stderr_pattern_*`, `assert_required_pattern_present`) on behavioral SCs | String evidence for behavioral criterion = EVIDENCE_TYPE_MISMATCH |
| Clean-room sub-agent receives orchestrator reasoning or expected outcomes | Contaminates evaluation with orchestrator bias |
| Evaluating from stdout.log or stderr.log instead of session.yaml | stdout.log is prose only; stderr.log is diagnostics only. session.yaml (SQLite DB export) is the authoritative record of agent actions |

### Required Pattern

```yaml
# In the spec's Success Criteria table:
| SC-N | Agent dispatches approval-gate skill when asked to verify authorization | behavioral | opencode run → session.yaml |
| SC-N+1 | Clean-room evaluation confirms agent dispatched approval-gate skill | behavioral | Clean-room sub-agent reads session.yaml from SC-N artifacts |
```

### Implementation

**SC-N (artifact generation):**
```bash
# behavioral test script — artifact-only generator
behavior_run "scenario-name" "prompt"
exit 0
```

**SC-N+1 (clean-room evaluation):**
```bash
# Evaluation script or task dispatch
task(..., prompt: "Read session.yaml from {artifact_path}. Evaluate whether the agent's tool calls and decisions satisfy SC-N+1: {criterion}. Return PASS/FAIL with a one-sentence justification.")
```

The evaluation sub-agent receives ONLY:
- The artifact directory path
- The SC criterion text
- `github.owner`, `github.repo` (for context)

It does NOT receive:
- Orchestrator reasoning about what the agent should have done
- Expected outcomes or pre-determined verdicts
- Cached results from prior runs

## 6b. Ceremony-Test Retirement Policy (CM-1, #2489)

**A test survives only if a real defect would escape without it. Every new test SC must justify its verification cost against the defect it catches — no string-grep documentation-phrasing checks. Ceremony tests that grep for prose/phrasing without behavioral consequence do not earn their cost and are retired.**

Both clauses are mandatory gates for test admission and retention:

1. **Survival condition:** a test survives only if a real defect would escape without it. A test that cannot fail on any realistic defect is ceremony.
2. **Verification-cost justification:** every new test SC must justify its verification cost (runtime, tokens, harness load) against the defect it catches. String-grep documentation-phrasing checks — greps for prose/phrasing with no behavioral consequence — do not earn their cost.

**Rationale driver (user directive 2026-10-02):** performative tests re-accumulated in the submodule-pointer subsystem. Precedent: `test-2264-sc7-bug-only-override-uses.sh` grep-enumerated the `SKIP_STALE_POINTER_CHECK` hatch in a narrative fixture — zero defect coverage, wasted a full behavioral run. It and the other four dependent Gate 2 tests were retired in #2489 Phase 2. Any future test that matches this pattern MUST NOT be admitted; existing tests matching it are retired on encounter.

**Issue context:** #2489 (CM-1) — policy recorded in this section as the authoritative retire-path record.

## 6c. Reference-Integrity Enforcement Check (SC-12, #2489)

**Run `./.opencode/tools/reference-integrity` before committing any change to agent-facing markdown.** The check validates that every `Read [Text](path)` link resolves to a section contained in its target file (link text matched against #/##/### headings in the target, quoted section names and `§`-suffix links supported). It fails closed on malformed input — empty files and heading-less targets are reported broken, never passed vacuously.

| Mode | Invocation |
|------|------------|
| Default scan (guidelines/, skills/, reference/, commands/, tests-v2/AGENTS.md) | `./.opencode/tools/reference-integrity --scan` |
| Single file / directory | `./.opencode/tools/reference-integrity <file.md> [<path> ...]` |

Exit 0 = all Read-links resolve. Non-zero = broken references; each report line carries the source file path AND the missing-section name. Run it after any edit that moves, renames, or deletes a section other documents Read-link into — a canon move that silently strands dependents is the defect class this check guards. Broken references found by the scan must be repaired in the same change (or filed as a spec issue), never left for a later pass.

**Issue context:** #2489 (SC-12) — tool built in #2489 Phase 4 before the Phase 5 reference repairs it validates.

## 7. Cleanup

```bash
# Remove the most recent test home
bash .opencode/tests-v2/with-test-home --clean

# Remove ALL test homes
bash .opencode/tests-v2/with-test-home --clean-all
```

## 8. Triple Co-Application Reference

This document is AI-agent-facing text. Per `080-code-standards.md` §Mandatory Triple Co-Application, the following three reference cards were consulted during its creation:

| Reference Card | What It Governs in This Document |
|----------------|----------------------------------|
| `250-dark-prose-reference.md` | Identity — rules use authority frame, not confirmshaming. MANDATORY/PROHIBITED patterns use direct mandates. |
| `255-distribution-shifting-reference.md` | Signal — required vs optional fields are explicitly marked. The paradigm statement uses corrupt-success contrast. |
| `257-procedural-discipline-reference.md` | Structure — dependency-order gate: artifact generation REQUIRES a model run. Controlled vocabulary pairs define exact vocabulary. |

## 9. Change Control

### Default Model

The default test model is defined in `default-model.sh` as `DEFAULT_TEST_MODEL`. This is the single source of truth — do not embed model strings elsewhere.

**DO NOT CHANGE the default model unless explicitly directed to do so by an approved spec.** The default model (`ollama/qwen3.8:27b-128k-gguf4`) is verified to work with the test harness. Changing it without a spec risks:
- Breaking tests that depend on model behavior
- Introducing model-specific flakiness
- Circumventing the spec-first workflow

If a spec requires a different model, override via environment variable:
```bash
DEFAULT_TEST_MODEL="ollama/other-model:tag" bash .opencode/tests-v2/behaviors/<scenario>.sh
```

**Default-Model Mandate (R-20, hardened by developer directive 2026-10-15):** Every behavioral test run uses the default test model defined by this single source of truth (`DEFAULT_TEST_MODEL` in `default-model.sh`). **No model changes are allowed — no exceptions.** Substituting another model on the agent's own initiative is PROHIBITED, and a per-run `DEFAULT_TEST_MODEL` env override is no longer a sanctioned remediation or work-around surface for any test problem — failures, timeouts, slow runs, or any other execution issue are remediated exclusively through the R-18 defect classes (instructions, task-card/skill-deck wording, prompt construction, fixture state, harness behavior) or by re-scoping the SC at the spec; if none of those produce a PASS, the SC is reported BLOCKED to the developer. The agent never proposes, requests, or offers a model change as an option — raising it is itself a defect. Default-model *value* changes are gated by an approved spec per this section; the mandate binds the single-source-of-truth mechanism, not a hardcoded model string.

### Binary Resolution

`opencode` is copied from `.tools/opencode/opencode` into `$TEST_HOME/bin/opencode` by `with-test-home`. **DO NOT resolve from PATH** — `command -v opencode` may find `/snap/bin/opencode` which ignores `$HOME` and leaks production state. If the binary location changes, update the `STANDALONE_BINARY` path in `with-test-home` and the test runner scripts.

### Isolation Requirements

The isolation contract (environment variables, working directory, submodule checkout, model config generation, binary copy, uv/uvx copy, set-env.sh) is defined in §5. **DO NOT change isolation requirements without an approved spec.** Changes to the `env -i` allowlist, `HOME`/`SNAP_USER_DATA` handling, binary resolution, or submodule checkout pattern can silently break isolation and leak production state.

**Tier-dependent isolation (.opencode#2582):** the host-path isolation mandates in this section bind tier-3 (host) runs; tier-2 (Docker) runs are governed by the Docker isolation contract (§5 — host-uid execution, only-`tmp/` mounts, bare test home, baked base-tool baseline). The test project is always a clone of the root project from its single remote URL — git resolves the submodule URL automatically from the cloned `.gitmodules`.

## 10. Testing Lessons Learned — Failure Patterns and Remediation

This section documents failure patterns discovered during implementation of #2170/#2172/#2173/#2175. These are mandatory reading for any agent running behavioral tests.

### 10.1 Stale Lock Contention

**Symptom:** `HARNESS_FAILURE: lock contention — another test is running (waited 30s)`

**Root cause:** A prior `behavior_run()` invocation was killed (bash tool timeout, SIGTERM, or crash) before releasing the `flock` at `tmp/.behavior-run.lock`. The lock file remains on disk with no process holding it, but the next test attempt sees the file and waits 30s before failing.

**Remediation:**
```bash
rm -f tmp/.behavior-run.lock
```
Then re-run the test. Always clean stale locks before re-running.

**Prevention:** The lock file is advisory — it does not auto-expire. Always run `bash .opencode/tests-v2/with-test-home --clean-all` between test sessions to clean up stale state.

### 10.2 Bash Tool Timeout (Default 120s Kills 35B Models)

**Symptom:** `HARNESS_FAILURE: behavior_run produced empty output after all retries` — stdout is empty, stderr has only `TEST_HOME=<path>`.

**Root cause:** The bash tool's default timeout is 120s (120000ms). A 35B model takes 5-10 minutes to produce a response for a cleanup workflow. The bash tool kills the script before the model finishes, producing empty stdout. The retry logic sees empty output and retries, but the same timeout kills it again.

**Remediation:**
```bash
# ALWAYS pass timeout=600000 (600 seconds) when running behavioral tests
bash .opencode/tests-v2/behaviors/<scenario>.sh
# ^ bash tool MUST have timeout: 600000
```

**Evidence check:** Even when the bash tool kills the script, the SQLite DB in the test home contains the partial session data. Export it manually:
```bash
TEST_HOME=$(grep '^TEST_HOME=' tmp/behavioral-evidence-<scenario>-<phase>-<model>/stderr.log | sed 's/^TEST_HOME=//')
python3 -c "
import json, sqlite3
db = '$TEST_HOME/.local/share/opencode/opencode.db'
conn = sqlite3.connect(db)
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute('SELECT * FROM event ORDER BY id')
events = [dict(r) for r in c.fetchall()]
result = {'source_db': db, 'harness_version': 1, 'tables': {'event': {'columns': ['id','aggregate_id','seq','type','data'], 'rows': events}}}
with open('tmp/behavioral-evidence-<scenario>-<phase>-<model>/session.yaml', 'w') as f:
    json.dump(result, f, indent=2, default=str)
"
```
This exports the SQLite DB even when the test was killed mid-run, allowing evaluation of partial output.

### 10.3 Missing session.yaml Export (stderr Fallback)

**Symptom:** Artifact directory has `stdout.log`, `stderr.log`, `manifest.yaml`, `exit_code` but NO `session.yaml`. The `__export_sqlite_to_yaml()` function produced `source_db: MISSING`.

**Root cause:** `__export_sqlite_to_yaml()` in `helpers.sh` searches stdout for `TEST_HOME=<path>`. When the bash tool kills the script (timeout), stdout is empty. The function reports `source_db: MISSING`. The fix (applied in #2182) adds stderr fallback — `with-test-home` always emits `TEST_HOME=<path>` to stderr.

**Remediation (pre-fix):** Manually export the SQLite DB using the procedure in §10.2.

**Remediation (post-fix):** The `__export_sqlite_to_yaml()` function now searches stderr when stdout is empty. If `session.yaml` is still missing, the test home may have been cleaned. Check `ls tmp/test-home-*/` for the test home directory.

### 10.4 Fabricated Model Excuses — ABSOLUTE PROHIBITION

**Symptom:** Agent reports "model timed out", "model too large", "model not available", or "model unavailability" as justification for skipping a behavioral test or reporting it as PASS without running it.

**Root cause:** The agent fabricates model excuses instead of diagnosing the actual failure (stale lock, bash tool timeout, missing stderr fallback). This is a CRITICAL VIOLATION of verification honesty.

**Prohibition:** An agent MUST NOT claim model unavailability, model timeout, or model incompatibility without tool-call evidence. The remediation-first protocol applies:
1. Check for stale lock: `ls -la tmp/.behavior-run.lock`
2. Check bash tool timeout: verify `timeout` parameter >= 600000ms
3. Check stderr for `TEST_HOME=<path>` — the model DID run, the harness just couldn't capture output
4. Manually export SQLite DB from test home (see §10.2)
5. Only after ALL remediation attempts fail may the agent report FAIL with evidence of each attempt

**Evidence that the model works:** The model (qwen3.8:27b-128k-gguf4) is verified to work with the test harness. It produces valid output for cleanup workflows in 5-10 minutes. Any claim that it "doesn't work" or "is too large" is a fabrication unless backed by tool-call evidence.

### 10.5 Post-Timeout Recovery Procedure (FALLBACK — Resumption is Primary)

When a behavioral test times out (bash tool kills the script), session resumption (§10.7) is the **PRIMARY** recovery path — it picks up where the agent left off instead of re-running the full inference that timed out at the same point. **Only when resumption is not possible** (no session id discoverable, resume fails, or the session cannot be re-run through the harness) should the agent follow this manual export + re-run procedure:

1. **Locate the artifact directory:**
   ```bash
   ls -lt tmp/behavioral-evidence-<scenario>-*/
   ```

2. **Extract TEST_HOME from stderr:**
   ```bash
   TEST_HOME=$(grep '^TEST_HOME=' tmp/behavioral-evidence-<scenario>-<phase>-<model>/stderr.log | sed 's/^TEST_HOME=//')
   ```

3. **Verify the SQLite DB exists:**
   ```bash
   ls -la "$TEST_HOME/.local/share/opencode/opencode.db"
   ```

4. **Export session.yaml manually:**
   ```bash
   python3 -c "
   import json, sqlite3
   db = '$TEST_HOME/.local/share/opencode/opencode.db'
   conn = sqlite3.connect(db)
   conn.row_factory = sqlite3.Row
   c = conn.cursor()
   c.execute('SELECT * FROM event ORDER BY id')
   events = [dict(r) for r in c.fetchall()]
   result = {'source_db': db, 'harness_version': 1, 'tables': {'event': {'columns': ['id','aggregate_id','seq','type','data'], 'rows': events}}}
   with open('tmp/behavioral-evidence-<scenario>-<phase>-<model>/session.yaml', 'w') as f:
       json.dump(result, f, indent=2, default=str)
   "
   ```

5. **Evaluate the partial output:** The session.yaml contains all tool calls and reasoning up to the point of timeout. This is valid evidence for evaluating agent behavior — the agent's decisions up to the timeout are observable.

6. **Clean up and re-run with longer timeout:**
   ```bash
   rm -f tmp/.behavior-run.lock
   bash .opencode/tests-v2/with-test-home --clean-all
   # Re-run with timeout=900000 (900 seconds) in the bash tool
   ```

### 10.6 No-Outguess Mandate — Agent MUST NOT Outguess Model/GPU Selection

**The agent MUST NOT outguess model/GPU selection during behavioral testing — the harness and ollama handle model/GPU selection, not the agent.** The agent MUST NOT probe GPU VRAM via `ollama-probe hw` to justify a model override, and MUST NOT hand-pick a model to substitute for the harness's selection.

**`DEFAULT_TEST_MODEL` (from `default-model.sh`) is the single source of truth** for which model runs a behavioral test. The agent MUST use `DEFAULT_TEST_MODEL` without substitution — it is the only model the agent uses during behavioral testing. The no-outguess mandate means the agent does not outguess `DEFAULT_TEST_MODEL` by switching models.

**On failure or timeout, the agent follows the §10 remediation path** — stale-lock cleanup (§10.1), bash-tool timeout handling (§10.2), stderr fallback (§10.3), the §10.4 fabricated-model-excuse prohibition, and session resumption (§10.7, primary) or post-timeout recovery (§10.5, fallback). The agent MUST NOT diagnose "model too big" or "VRAM insufficient" and switch models as an alternative to the §10 remediation path. Model-switching on failure/timeout is forbidden — the remediation path is the only valid response.

### 10.8 Docker Failure Domain (tier-2, .opencode#2582)

The Docker tier's failure classes are named and fail fast with the
`HARNESS_FAILURE:` prefix; each message names its remediation:

| Failure class | Symptom | Remediation message pattern |
|---|---|---|
| Daemon unavailable | `docker info` fails | `HARNESS_FAILURE: Docker daemon unavailable — start the docker service (e.g. sudo systemctl start docker) and re-run; no container created` |
| Image pull/build failure | `docker build` of the test-agent or GitBucket image fails | `HARNESS_FAILURE: <image> image build failed — inspect the build output above; fix the Dockerfile or the network and re-run` |
| Port/resource conflict | `docker run` fails to create the GitBucket container | `HARNESS_FAILURE: GitBucket container creation failed (port/resource conflict or daemon error) — inspect: docker ps -a | grep tests-v2-gitbucket` |
| Stale container by name | A same-name harness container exists but is not running | The provisioner removes it and creates fresh; if creation still fails → the port/resource pattern above |

Run-container launch and abort follow the same convention
(`HARNESS_FAILURE: docker launch failed for scenario '<name>'`; abort =
`docker stop` + `docker rm -f`, a guaranteed whole-tree kill). `--clean-all`
removes every harness-created container while preserving pulled/built images.

### 10.7 Session Resumption — MANDATORY FIRST-LINE Recovery on Model Timeout

**`opencode run` supports session resumption. Resumption is the FIRST-LINE recovery for a model timeout — manual SQLite export and full re-run are the FALLBACK, permitted only when resumption is not possible.** The agent MUST attempt resumption before any other recovery action.

**PROHIBITED:** Jumping to the manual SQLite DB export + `--clean-all` + full `opencode run` re-run (§10.5) as the first response to a timeout. A full re-run repeats 5-10 minutes of model inference that times out at the same point — it discards the agent's completed work and reproduces the identical failure. The mean response is to restart from zero; the expert response is to resume where the agent left off.

**Resume flags:**

| Flag | Meaning | Use When |
|------|---------|----------|
| `--continue` | Resume the last session | The timed-out session is the most recent session in the test home |
| `--session <id>` | Resume a specific session | A different session is the most recent, or you need to target a specific run |

**Discovering the session id:** The session id is the `aggregate_id` value in the `event` table of the test home's SQLite DB (`$TEST_HOME/.local/share/opencode/opencode.db`), or the session id reported in the `with-test-home` invocation output. Extract it from the DB the same way `__export_sqlite_to_yaml()` reads events; the `aggregate_id` identifies the session to resume.

**Why resumption is preferred:** Resumption picks up where the agent left off — the model continues the existing session context instead of re-running minutes of inference that timed out at the same point. The completed tool calls and reasoning remain in the session; only the remaining work is re-executed. This converts a 5-10 minute repeated re-run into a short continuation, and it preserves the partial behavioral evidence for evaluation.

**Resumption procedure on model timeout:**

1. **Confirm the test home survives the timeout** — `ls -la "$TEST_HOME/.local/share/opencode/opencode.db"` (extract TEST_HOME from `stderr.log` per §10.5).
2. **Discover the session id (if not resumable via `--continue`)** — read `aggregate_id` from the `event` table, or use the session id from the `with-test-home` invocation output.
3. **Clear the stale flock lock** — `rm -f tmp/.behavior-run.lock`.
4. **Resume the session through the harness:**
   ```bash
   bash .opencode/tests-v2/with-test-home opencode run --continue
   # or, to target a specific session:
   bash .opencode/tests-v2/with-test-home opencode run --session <id>
   ```
   The run **MUST** go through `with-test-home` — never call `opencode run` directly (SQLite session conflicts with the desktop app). Keep the bash tool `timeout` parameter at >= 600000ms so the resumed inference can complete.
5. **Fallback if resumption is not possible:** Only if resumption fails or the session cannot be identified may the agent fall back to the manual export + re-run procedure in §10.5.

**🚫 FORBIDDEN:** Claiming resumption is impossible without attempting it. Resumption is the only valid first-line response to a timeout; the manual export + full re-run in §10.5 is the fallback for when resumption genuinely cannot run.

**Resumption across invocations (SC-11, #2432):** `with-test-home` provides a resumption capability via `--resume-home <path>`. When a prior invocation's test home survives an interrupt, a FOLLOW-UP invocation reuses that home — and its session store — instead of provisioning a fresh one, so `--continue` / `--session <id>` reach the prior invocation's session state:

```bash
bash .opencode/tests-v2/with-test-home --resume-home <prior-test-home> opencode run --continue
# or, to target a specific session:
bash .opencode/tests-v2/with-test-home --resume-home <prior-test-home> opencode run --session <id>
```

Guards: a missing/unreachable prior test home fails fast naming the home; a missing session store fails fast naming the store path; a corrupted/unreadable session store reports `FATAL:` naming the store path (R-5 analog). Fresh invocations (no `--resume-home`) are unchanged — a new test home per invocation. The flock/locking discipline in `behavior_run()` is unaffected (a resumed run passes through the same single-flock path).

**Implemented predicate mirror (SC-12):** the §10.7 resume path is guarded by the implemented predicates:

- `__undetermined_ceiling_check` — the SC-9 undetermined-ceiling gate: continuation permitted while the persisted undetermined-cycle counter is below `UNDETERMINED_CYCLE_CEILING` (default 3); at/above the ceiling it emits a `FATAL: ... CEILING_REACHED` mechanical block on stderr and blocks undetermined retries. The block PERSISTS: the state file survives on disk, the gate re-fires on every subsequent invocation, and clearance requires an explicit developer-remediation marker (`<state_file>.developer-cleared`).
- `__record_orchestrator_decision` — the SC-7 orchestrator decision-record write path: appends a decision entry to the existing `determination.yaml` record (never creates it); validates the value-set `{continue-new-dispatch, terminate-with-root-cause}` and requires `--root-cause` for `terminate-with-root-cause`; the SC-13 diagnosis gate VALIDATES a recorded decision and never rewrites a decision variable or machine-synthesizes a decision/root_cause value (.opencode#2649 R-4); fails (non-zero, `HARNESS_FAILURE`/`VALIDATION-ERROR`) on value-set violation, missing root cause, missing diagnosis, or missing determination record — never silently no-ops. Machine paths in the harness never author or rewrite an orchestrator decision value (.opencode#2649 R-3): the halt-class path records run-outcome observations via `__record_run_outcome` (to the record's `run_outcome_observations` list), and `orchestrator_decisions` receives entries only through this orchestrator surface.
- `__sc8_determination_gate` — the SC-8 determination gate in `with-test-home` (INTERNAL precondition at resume/re-run time): scans the evidence tree for a determination record for the resume target and FAILS FAST (no inference dispatched) with a `FATAL:`-class message naming the missing determination when the home carries no determination the gate accepts. The rule is an OR: a resume is permitted when the record carries a non-undetermined classification (`progressing-directionally` or `off-track`) OR a valid recorded decision (`continue-new-dispatch`, or `terminate-with-root-cause` with root cause); a record carrying an undetermined classification with no valid recorded decision is blocked, and so is a home with no record. The scan roots are the runner's `TMP_DIR` plus every root the launcher names in `BEHAVIOR_DETERMINATION_SCAN_DIR` (a colon-separated list): the run's own evidence dir and the run's artifact directory, which is where the determination record is written. Every named root is scanned — the last element of the list included, which is the one the artifact directory occupies. The Docker tier's `TMP_DIR` is the staging root and does not contain the record, so the launcher names the artifact directory explicitly; the host tier's `TMP_DIR` is the parent repository's `tmp/`, which contains it. Without the artifact directory in the scanned roots, the Docker tier's gate never saw the record and refused every cap-hit resume with `determination.yaml not found in any scenario evidence dir` (observed 2026-10-23, .opencode#2663).

## 11. Prompt Construction Mandate

Behavioral test prompts MUST trigger natural agent behavior — they MUST NOT interview the agent about what it *would* do.

### The Interview/Natural-Behavior Spectrum

| Prompt Type | Classification | Example | Verdict |
|-------------|---------------|---------|---------|
| Real-domain task | Natural behavior | "Implement feature X from spec #42" | ✅ Valid |
| Real-domain bug | Natural behavior | "The login button doesn't work" | ✅ Valid |
| "Describe how you would..." | Prose-recall (interview) | "Describe how you would handle authorization" | ❌ INVALID |
| "Explain the process for..." | Prose-recall (interview) | "Explain how you create a PR" | ❌ INVALID |

### Hard-Fail Rule

Any behavioral test that uses a prose-recall prompt is **FAIL** — the test does not measure actual agent behavior.

---

## Directory Structure

```
.opencode/tests-v2/
├── AGENTS.md                    # This file — test harness spec
├── with-test-home               # Core env setup script
├── default-model.sh             # Default model variable
├── test-enforcement.sh          # Content-verification runner
├── test-verification-honesty.sh # Verification honesty runner
└── behaviors/
    ├── helpers.sh               # behavior_run() and assertion helpers
    ├── template.sh              # Script template for new tests
    └── fixtures/                # Copied from .opencode/tests/behaviors/fixtures/
        ├── evidence/
        ├── gitbucket-fake-repo/
        ├── issues/
        ├── stories/
        ├── setup-fixture-issues.sh
        └── setup-story-fixtures.sh
```

---

## 12. Self-Contained GitBucket Container for Remote API Tests (.opencode#2582)

Tests that need to verify remote API behavior (e.g., verifying labels on a remote issue after creation) can opt in to a self-contained GitBucket instance provisioned by the test harness. **GitBucket runs as its own Docker container** — committed Dockerfile (`tests-v2/docker/Dockerfile.gitbucket`, digest-pinned Eclipse Temurin 21 JRE base), the public `gitbucket/gitbucket` image is never used or run (stale JDK8-base build).

### Opt-In Flag

Set `BEHAVIOR_NEEDS_REMOTE=1` in the test script before calling `behavior_run()`:

```bash
BEHAVIOR_NEEDS_REMOTE=1 behavior_run "scenario-name" "prompt"
```

### Lifecycle

1. **Provisioning** (`__ensure_gitbucket()` in `tests-v2/docker/docker-harness.sh`):
   - GitBucket WAR downloaded by the existing release-resolution logic into
     `tmp/gitbucket-staging/gitbucket.war` (scratch under `tmp/`), then baked
     into the image at provision-time build (`docker build` with the WAR as a
     build context) — no rebuild step on the host toolchain, no WAR baked into
     a committed image
   - Container `tests-v2-gitbucket` created with `docker run -d -P --user
     <uid>:<gid>` — the invoking user's uid:gid (no root-owned files under
     `tmp/`), data dir mounted from `tmp/gitbucket-data`
   - Host port **Docker-assigned at container creation**, discovered via
     `docker port tests-v2-gitbucket 8080/tcp`
   - Admin token minted via the web-form flow (sign-in → `/:user/_personalToken`
     → read from the account page), persisted under `tmp/.gitbucket.token`,
     set as `GB_TOKEN`; `gb auth login` authenticates the CLI against the
     provisioned instance
   - Test repo created via the API; remote wiring stays in `behavior_run()`
     against the validated isolated attempt workdir
   - **Idempotent:** a second invocation against the running container
     re-exports the same `GB_*` values without recreating it
2. **Reset** (`__reset_gitbucket()`): `docker rm -f` + data-directory rebuild +
   re-provision — new container id, rebuilt data, regenerated token
3. **Cleanup** (`--clean-all`): removes the GitBucket container and every
   `tests-v2-run-*` container while preserving pulled/built images

### Environment Variables

| Variable | Set By | Purpose |
|----------|--------|---------|
| `BEHAVIOR_NEEDS_REMOTE` | Test script | Opt-in flag (set to `1` to enable) |
| `GITBUCKET_PORT` | `__ensure_gitbucket()` | Docker-assigned host port (via `docker port`) |
| `GB_TOKEN` | `__ensure_gitbucket()` | GitBucket admin API token |

### State (all under `tmp/`)

| Path | Purpose |
|------|---------|
| container `tests-v2-gitbucket` | The running GitBucket instance |
| `tmp/gitbucket-staging/gitbucket.war` | WAR staged for the provision-time image build |
| `tmp/gitbucket-data/` | GitBucket data directory (ephemeral) |
| `tmp/.gitbucket.token` | Persisted admin token (idempotent re-export) |

### Clean State Between Tests

Call `__reset_gitbucket()` between test scenarios to ensure clean state:

```bash
__reset_gitbucket  # removes the container, rebuilds the data dir, re-provisions
```

The `--clean-all` flag in `with-test-home` removes harness-created containers
(GitBucket + run containers) and data dirs but preserves pulled/built images
and the `.tools/` cache for reuse across sessions.

---

## 13. Remote-Strategy Flags and Full-Environment Simulation

The harness exposes several opt-in flags that configure a test's remote/submodule environment. All three are exported into the isolated test environment by `with-test-home` and consumed by `behavior_run()` in `behaviors/helpers.sh`.

| Flag | Purpose |
|------|---------|
| `BEHAVIOR_NEEDS_REMOTE` | Opt-in (set to `1`) to provision a self-contained GitBucket instance and wire its test repo as the test project's `origin` remote. See §12. |
| `BEHAVIOR_SET_BARE_REMOTE` | Opt-in (set to `1`) to create a local bare repository and wire it as the test project's `origin` remote. |
| `BEHAVIOR_NEEDS_MULTI_SUBMODULES` | Opt-in (set to `1`) to provision `test-submodule-1` and `test-submodule-2` as local git repos (sibling submodules) inside the attempt workdir. |

### Remote-Strategy Mutual-Exclusion Rule

**`BEHAVIOR_NEEDS_REMOTE` and `BEHAVIOR_SET_BARE_REMOTE` are mutually exclusive remote strategies.** Both flags configure the test project's `origin` remote — `BEHAVIOR_NEEDS_REMOTE` wires the GitBucket test repo as origin, while `BEHAVIOR_SET_BARE_REMOTE` wires a local bare repository as origin. Setting both simultaneously would wire an ambiguous origin.

`behavior_run()` rejects this contradictory configuration **before** either the GitBucket provisioning block or the bare-remote wiring block runs:

```bash
if [ "${BEHAVIOR_NEEDS_REMOTE:-0}" = "1" ] && [ "${BEHAVIOR_SET_BARE_REMOTE:-0}" = "1" ]; then
    echo "HARNESS_FAILURE: mutual-exclusion violation — BEHAVIOR_NEEDS_REMOTE and BEHAVIOR_SET_BARE_REMOTE are mutually exclusive (both set)" >&2
    return 1
fi
```

A test that sets both flags FAILS with `HARNESS_FAILURE: mutual-exclusion violation` — the run is rejected before any provisioning or model dispatch occurs. A test MUST set at most one of `BEHAVIOR_NEEDS_REMOTE` and `BEHAVIOR_SET_BARE_REMOTE`.

### `BEHAVIOR_NEEDS_MULTI_SUBMODULES` — Multi-Submodule Fixture Opt-In

Set `BEHAVIOR_NEEDS_MULTI_SUBMODULES=1` to provision `test-submodule-1` and `test-submodule-2` as local git repositories inside the attempt workdir. Each is initialized with `git init`, populated from its fixture template under `behaviors/fixtures/submodules/` (falling back to an empty commit if no template exists), and committed with an `init submodule fixture` commit.

This opt-in provides sibling submodules for tests that must discover or interact with multiple submodules. The flag-off path provisions only the single `.opencode` clone, preserving the default provisioning.

### Full-Environment Simulation Opt-In

Combining `BEHAVIOR_NEEDS_MULTI_SUBMODULES=1` and `BEHAVIOR_NEEDS_REMOTE=1` enables **full-environment simulation**: the test workdir is provisioned with multi-submodule fixtures (sibling `test-submodule-1`/`test-submodule-2` repos) AND a wired GitBucket origin (test repo set as the project's `origin` remote with `GITBUCKET_PORT`/`GB_TOKEN` scoped into the isolated environment).

This is the recommended configuration for remote-dependent tests that also need multi-submodule context, such as `2242-sc6`. Because full-environment simulation uses `BEHAVIOR_NEEDS_REMOTE` (not `BEHAVIOR_SET_BARE_REMOTE`), it does not trigger the mutual-exclusion rejection.

### GitHub-Side Test Repo Targets

The designated throwaway GitHub test repos are **`test-submodule-1`** and **`test-submodule-2`** ("Test repository for verifying git workflow skills and submodule handling"). A scenario needing a real GitHub-side repo target uses these repos in the authenticated owner's namespace — owner resolution is deployment-local (the authenticated session context), never a hardcoded owner path — and never targets production repos. These are the live GitHub counterparts of the local fixture repos provisioned by `BEHAVIOR_NEEDS_MULTI_SUBMODULES`; the GitBucket container (`BEHAVIOR_NEEDS_REMOTE`) remains the default self-contained remote strategy.

---

## 14. Semantic Continuous Monitoring Mandate (Behavioral Runs)

**Every behavioral `opencode run` MUST be monitored semantically while it executes — blind full-timeout burns and blind resume loops are PROHIBITED.** (Issue #2427 scope G.)

A behavioral run that goes off-track — looping on identical tool input, spinning in reasoning without goal-relevant tool calls, or stuck in a sub-agent dispatch — burns its full 600-900s timeout with no diagnosis and no partial evidence collected at the moment of failure. The monitoring mandate replaces the blind wait with interval polling of the live session DB and a semantic judgment each poll: is the agent progressing toward the scenario goal, or has it gone off-track?

### The Monitoring Protocol — MANDATORY

| Step | Action | Detail |
|------|--------|--------|
| 1 | **Launch in background** | The `opencode run` invocation is launched in the background (not awaited synchronously) so the harness can poll while inference proceeds. |
| 2 | **Poll at intervals** | Poll at a fixed interval (e.g., 30-60s) for as long as the process runs. Each poll is cheap — a SQLite read against an already-present DB. |
| 3 | **Read the live session DB** | Each poll reads the NEWEST `tmp/test-home-*/.local/share/opencode/opencode.db` (the current run's test home) and extracts the event stream: tool calls (name + input), reasoning sizes (char counts), and text parts. |
| 4 | **Evaluate semantically** | Judge progression, not just mechanics: are completed tool calls goal-relevant for the scenario? Is reasoning growing without producing tool calls? Is the agent repeating itself? |
| 5 | **Abort on signal** | On any hard-abort signal (below), kill the run, export session.yaml per §10.5, record the semantic diagnosis. |
| 6 | **Record evidence** | The poll log (per-poll event-stream reads + judgments) or the semantic diagnosis MUST be recorded alongside session.yaml for any behavioral SC verdict whose evidence comes from a monitored run. |

### Hard-Abort Signals — ZERO TOLERANCE

A monitored run MUST be aborted (killed + exported + diagnosed) when ANY of the following fires:

| # | Signal | Threshold |
|---|--------|-----------|
| 1 | Identical tool input | The same tool call with the same input appears >=3 times |
| 2 | Stuck sub-agent dispatch | `task()` parts remain in `running` state across >=2 consecutive polls |
| 3 | Reasoning runaway | Reasoning exceeds 20,000 chars with <=1 new completed tool call |
| 4 | Semantically off-track | No goal-relevant completed tool call across 2+ consecutive polls while reasoning grows |

Signal 4 is the semantic judgment and fires even when no mechanical threshold does — the mechanical signals (1-3) are necessary-but-not-sufficient triggers, not the only abort path. The poll log records the semantic reasoning for audit.

### Evidence-Sufficiency Early Exit (#2538)

Monitoring has three exits, not one: the hard-abort signals above, the evidence-sufficiency early exit (below), and the verdict-confirmed conclusion (below that). When a poll's semantic judgment finds the scenario's evidence surface **already complete** in the live session DB — the agent behavior the SC examines has been observed, and further running would add no value — the monitor concludes the run early instead of waiting out the full timeout:

1. **Kill the run** — same abort mechanics as the hard-abort path (the monitor's own kill; GNU `timeout` stays FORBIDDEN).
2. **Export session.yaml** — the §10.5 manual export procedure; the DB survives the kill, and partial-evidence validity applies equally.
3. **Record the sufficiency judgment** — which evidence was detected, the event-stream citations, and why further running adds no value, written to the evidence directory alongside session.yaml.
4. **Dispatch the clean-room evaluation** — the standard evaluator judges the recorded behavior; missing secondary artifacts (e.g., a naturally-written `manifest.yaml`/`exit_code`) are acceptable for an early-concluded run when the sufficiency judgment is on record.

**This decision is intent-decidable — judgment, never a script.** What counts as "evidence surface complete" and "no additional value" depends on the SC criterion and what the live event stream shows; no static check (tool-name counter, grep, event threshold) may decide it. A scripted early-kill would truncate runs whose richer behavior was still coming — the mirror image of the blind wait this section replaces.

### Verdict-Confirmed Conclusion — MANDATORY, same cycle (.opencode#2594)

Stronger than the sufficiency exit above, and **not a judgment call about value**: when a poll's semantic check confirms the SC's **verdict state** — green (the scenario's goal condition observed met in the run agent's actual words and work) or red (the goal condition observed failed, or a run-fatal defect observed) — the supervisor MUST conclude the run in that same cycle:

1. **Kill the run** — PID-addressed kill of the run process tree (the monitor's own kill; GNU `timeout` stays FORBIDDEN); re-verify gone by PID.
2. **Export session.yaml** — the §10.5 manual export procedure when the artifact set is incomplete.
3. **Record the confirmation** — which poll confirmed the verdict state, the event-stream citations, and the verdict state, written to the evidence directory alongside session.yaml; `manifest.yaml`/`exit_code` may be absent for an early-concluded run when this record is on file.
4. **Dispatch the clean-room evaluation** — the standard evaluator judges the recorded behavior.

Polling past the confirming poll is a supervision defect (observed 2026-10-13, #2594: green confirmed at poll 47, polling continued through poll 50 — wasted cycles, project delay). Post-confirmation tail hygiene by the run agent is not evidence. Whether a poll confirms the verdict state is intent-decidable — judgment on the event stream, never a scripted pattern match; the post-confirmation actions are mechanical.

### PROHIBITED Patterns (§14)

| Pattern | Why Forbidden |
|---------|---------------|
| Launching a behavioral run and awaiting the full timeout with no polling | Blind waits burn 600-900s on runs that failed in the first minutes — defect-discovery latency with zero diagnostic yield |
| Waiting out a run whose SC evidence is already captured | Polling (or awaiting completion) after the evidence surface is complete burns inference time with zero additional value — conclude per the Evidence-Sufficiency Early Exit (#2538) |
| Polling past the confirming poll (#2594) | Once a poll's semantic check confirms the verdict state (green or red), further cycles cannot change the verdict and are waste by definition — conclude in the confirming poll's cycle per Verdict-Confirmed Conclusion; post-confirmation tail hygiene is not evidence |
| Blind `--continue` resume loops after a hung run | Resuming a run that was already off-track repeats the identical stall — §10.7 resumption is for genuinely progressing runs (e.g., bash tool timeout), not for off-track states the monitor detected |
| Skipping the semantic diagnosis after an abort | An abort without a recorded diagnosis destroys the evidence the verdict needs — the diagnosis IS the monitoring evidence |
| Structural-only verdicts from monitored runs | Behavioral SCs verified via monitored runs MUST record monitoring evidence (poll log or semantic diagnosis) alongside session.yaml — structural substitutes are EVIDENCE_TYPE_MISMATCH |
| Treating excessive run time as model-speed-only and skipping cause analysis | Excessive run time is a PRIMARY defect signal (R-18) — a run that is "slow" is usually slow because of bad instructions, skill-deck wording, prompt construction, fixture state, or harness behavior; skipping the cause analysis re-pays the defect in inference time on every future run — see §17 |
| Concluding hardware/model unavailability without direct deliberation-evidence review | Unavailability claims are conclusions about reasoning and require reasoning evidence — the reviewing agent MUST personally inspect the failed run's actions and thinking and trace the reasoning-failure scenario first; sub-agent diagnoses are inputs, not substitutes — see §18 (R-19) |
| Model-shopping to work around a failing or slow test | Substituting a non-default model on the agent's own initiative runs tests on a configuration the harness has not verified and masks the R-18 defect classes — behavioral tests run on the harness default model (`DEFAULT_TEST_MODEL` in `default-model.sh`, R-20) unless the user explicitly directs otherwise; remediation targets the R-18 defect classes, never model selection — see §9 Change Control — Default Model |

### Abort Recovery Procedure

1. **Kill the run** — terminate the background `opencode run` process (the monitor kills the process; GNU `timeout` is still FORBIDDEN per the §5 Bash Tool Timeout Mandate — the monitor's own kill is the abort signal handler, not a timeout wrapper).
2. **Export session.yaml** — follow the §10.5 manual export procedure (extract TEST_HOME from `stderr.log`, export the `event` table). Partial evidence is valid evidence (§10.5 step 5).
3. **Record the semantic diagnosis** — write the poll log and the abort judgment (which signal fired, the event-stream evidence, the semantic reasoning) to the scenario's evidence directory alongside session.yaml.
4. **Evaluate on the partial evidence** — the scenario verdict is evaluated from session.yaml + the monitoring evidence; a run aborted for looping yields a valid FAIL/behavior-diagnosis verdict, not an INCONCLUSIVE.

### Cross-Invocation Resumption — `--resume-home` (SC-11, #2432)

`with-test-home` provisions a NEW test home per invocation by default. For resumption across invocations, the harness provides `--resume-home <path>`: a FOLLOW-UP invocation reuses the named prior invocation's surviving test home and session store, so `--continue` / `--session <id>` reach the prior session state instead of landing in a fresh home. Guards: missing prior home or session store → fail fast naming the path; corrupted store → `FATAL:` naming the store path. Fresh invocations are unchanged. Full procedure and examples: Read [§10.7 Session Resumption](#107-session-resumption---mandatory-first-line-recovery-on-model-timeout).

The semantic continuous monitoring mandate (this section) still governs off-track/hung runs: the monitor detects the stall mid-run and aborts with a recorded diagnosis instead of blindly resuming — §10.7 resumption (now including cross-invocation `--resume-home`) is for genuinely progressing runs (e.g., bash tool timeout kill with the test home intact), not for off-track states the monitor detected.

### §14 Cross-Invocation Resumption Anchor

Anchor target for the §10.7 cross-reference — same content as the "Cross-Invocation Resumption" section above; MD024 forbids duplicate headings, so this anchor note carries the cross-reference.

### Relationship to §10.5 / §10.7

| Situation | Correct Path |
|-----------|--------------|
| Run is progressing but the bash tool timeout kills the wrapper | §10.7 resumption — within-invocation via `--continue`, or across invocations via `--resume-home <prior-test-home>` when a prior test home survived; monitor evidence confirms progression |
| Monitor detects an off-track/loop state mid-run | §14 abort path: kill + §10.5 export + semantic diagnosis |
| Resumption genuinely impossible AND no monitoring ran | §10.5 fallback (manual export + re-run) |

### Monitoring Evidence Requirement for Behavioral SC Verdicts

Any behavioral SC verdict whose evidence comes from a monitored run MUST record the monitoring evidence (poll log or semantic diagnosis) alongside session.yaml in the scenario's evidence directory. A session.yaml alone does not prove the poll protocol executed — the poll log is the artifact that shows per-poll event-stream reads and judgments. Verdicts from unmonitored runs that burned a full timeout on an off-track state are a monitoring-mandate violation, not a valid verification path.

**Implemented predicate mirror (SC-12):** the monitoring loop's implemented predicates and their monitor.log evidence:

- monitor.log poll evidence — the per-attempt poll log persisted as `monitor.log` (SC-1); each poll appends `POLL`/`CLASSIFY`/`NOTIFY` records, and the determination record references monitor.log in its poll_evidence block.
- classifier dispatch — the SC-2 classification sub-agent (`__classify_run_state`) runs the classification in the classifier's OWN context and session DB (`classifier-session-attempt${attempt}.yaml`), bounded by `BEHAVIOR_MONITOR_CLASSIFY_MIN_POLLS`/`BEHAVIOR_MONITOR_CLASSIFY_MAX` (default 3), producing a taxonomy value (progressing-directionally | off-track | undetermined) or a dispatch failure.
- verifiable goal condition — the direction anchor: classification is judged ONLY against the scenario-declared `goal_condition` object (goal artifact + required content pattern + declared goal actions + per-poll artifact status) folded into the classifier digest — never against the monitored run's prompt prose or activity counters.
- determination.yaml record — `__write_determination_record` (SC-3) writes the durable determination record for EVERY monitored run (natural completion AND abort path), carrying final classification, poll-evidence references (monitor.log path + polls executed + classifier session), and run provenance (model, exit code, run_path, schema_version) under append-only (R-8) semantics.
- off-track notify — `__notify_offtrack` (SC-4, R-2): emits `ORCHESTRATOR_DECISION_REQUIRED: off-track` on stderr (off-track runs never continue silently) AND records a `NOTIFY[poll N]` line in monitor.log.
- halt-class halt+notify — `__notify_haltclass` (SC-6, R-3): when the classification dispatch returns a halt-class trigger state (undetermined / excessive-without-classification / direction-deviation), the monitor performs the halt-class halt+notify — emits `ORCHESTRATOR_DECISION_REQUIRED: halt-class` on stderr with the failure-mode annotation, records the NOTIFY line, and halts monitoring before any further dispatch, leaving the run state for the SC-7 orchestrator decision record.

### Agent-Supervisor Mandate (60s Poll Cycle with Text-Message Updates)

**Any agent supervising an `opencode run` polls on a 60-second cycle (`sleep 60`, then read the run's session DB) and delivers every update as a substantive text message in its turn.** (SC-17/SC-18, #2456; tightened to the 60s cycle with text-message updates, SC-17, #2557.)

| Mandate | Rule |
|---------|------|
| Poll cycle | The supervision loop is one repeating tool call: `sleep 60`, then read the run's session DB |
| Per-poll semantic check | Every poll is a FULL SEMANTIC CHECK derived from the run's session DB/export — message parts, reasoning parts, and tool calls. Activity/uptime proxies are INADMISSIBLE as poll checks |
| Update delivery | Every update is delivered as a substantive text message in the supervisor's turn — the developer's UI collapses Shell calls to bare command lines, so tool outputs and one-line fragments do not reach them. The todo list is kept current as the persistent status surface |
| Timestamp accounting | Cadence and gap claims are computed from recorded timestamps (nested-run launch time, every poll time) — never estimated. An asserted compliance claim built from an elapsed-time impression is a fabricated finding. If the run completed before the first poll, state that plainly and take the early-exit path |
| No blocking actions | No blocking action longer than 60 s starts while a run is active — clean-room evaluations dispatch at run boundaries, never mid-run |
| Retry discipline | Run-retry invocations WITHOUT an intervening semantic check are PROHIBITED; a single cycle longer than 60s without a semantic check and its update is likewise prohibited |
| Operation scope (.opencode#2619) | The mandate binds ANY operation under the agent's active supervision in a working turn — model runs and background jobs (reindex, export, migration) alike, with no duration or operation-kind qualifier — not only `opencode run` sessions |
| Interval ceiling (.opencode#2619) | The 60-second interval is a ceiling, not a target: it never escalates while the supervised operation is pending (no 90/120/240s drift between polls) |
| Unconditional update (.opencode#2619) | The per-poll in-chat text update is unconditional — a poll with no new evidence still delivers its update; "no change" stated plainly is the update (the developer cannot read tool outputs or agent reasoning; an unreported interval is invisible time) |
| Structural cycle (.opencode#2678) | The supervised cycle advances exactly tool call (sleep + poll) → standalone text update (no tool call attached) → next tool call; a tool call directly following another tool call of the same supervised cycle with no intervening text update is the defect in the supervisor's own transcript, regardless of the analysis's conclusion — the skipped-update failure is self-observable in that shape |

The harness's 30-60s monitor polling above covers the monitor loop; this mandate binds the AGENT supervisor — the agent watching a run (e.g., a long behavioral verification it launched) is NOT exempt from polling just because the harness monitor exists, and the harness monitor's existence does not substitute for the supervisor's own per-poll semantic checks and text-message updates. The owning surface for this mandate is the `behavioral-testing` skill card (its supervise-every-run rule); this section mirrors it for the harness-spec reader. A hung session under a supervisor that idled past the cycle without a semantic check and update is a CLEAR FAIL (SC-26, #2456), not an infrastructure excuse.

### Layered Hang Diagnosis and Abort Completeness (.opencode#2547)

Observed failures driving this subsection (2026-10-14, #2547 SC-4 verification): a frozen session-WAL was misread as a hang when it was the legitimate post-smoke steady state; an aborted run's orphaned processes (reparented to init, carrying the test home only in their environment) kept generating for 15+ minutes after a wrapper kill; and a mid-run ollama restart killed a generation stream whose client then waited indefinitely. The rules:

| # | Rule |
|---|------|
| 1 | **A hang verdict requires converging signals — never a single one.** The per-poll stack: session-DB flatness (via `poll-run.sh`), WAL-growth delta, GPU utilization (`nvidia-smi`), and the ollama service log (`journalctl -u ollama`). A frozen WAL alone is NOT a hang verdict — the WAL has a legitimate post-smoke steady state before model dispatch, and opencode batches part persistence behind long generation turns. An instantaneous GPU 0% is sampling noise or a CPU/GPU-offload split, not proof of stall. |
| 2 | **The server log is the tiebreaker.** `journalctl -u ollama` showing active generation (`slot print_timing ... n_gen` incrementing, task processing) means the run is generating regardless of client-side flatness — keep polling. Absent generation activity there, combined with a frozen WAL and a flat DB, is a hang: abort. |
| 3 | **A server restart or error in the service log during a run marks the run environment-suspect.** Abort by PID, export the session DB, and record the diagnosis — never blind-retry into a server whose state changed under the run (a restarted/wedged ollama leaves the client waiting on a stream that will never advance; observed: generation frozen mid-turn at the second a new `ollama serve` instance came up). |
| 4 | **Abort completeness — verify the whole tree is dead.** After any run kill, enumerate the run's surviving processes by recorded-PID descendants AND by test-home environment (the `HOME` env var of every process — a command-line-based check MISSES env-only carriers: an orphaned `opencode run` survives its wrapper with the test home visible only in its environment, observed 2026-10-14). Kill survivors; verify zero before proceeding. |
| 5 | **Read-only host checks are sanctioned supervision surfaces.** `journalctl -u ollama` and `nvidia-smi` are mandated per-poll diagnostics for behavioral-run supervision (developer direction, 2026-10-14). They are read-only: no host-state mutation — host services are not the agent's to manage. |
| 6 | **Orchestrated SC-verification runs launch with `BEHAVIOR_SEMANTIC_MONITOR=1`.** The determination record is written only under the monitor's flag, so an unmonitored run writes no record; the cap-hit resume path is monitor-gated too, so an unmonitored run attempts no resume. The §10.7 resumption path therefore hard-blocks for an unmonitored home, and a hang in an unmonitored run is recoverable only via the §10.5 full re-run fallback (observed: a resume attempt refused with `determination.yaml not found`). |

---

## 15. Targeted Behavioral-Test Execution Mandate (Tier 1)

**Every `opencode run` behavioral invocation targets exactly the named scenario(s) the current SC's RED or GREEN evidence needs. One run per SC-RED need and one run per SC-GREEN need — no more.**

**Cannot-combine clarification:** The "one run per SC-RED need and one run per SC-GREEN need" budget cannot be satisfied by combining two SCs' needs into one run — combining two SCs' needs into one run violates the mandate. Each SC's evidence need is separate, even when both SCs target the same scenario or appear cheaper to batch.

### 🚫 PROHIBITED — Whole-Suite Model-Executing Invocations

An agent instructed to "run the behavioral tests" (or any equivalent instruction) MUST NOT:

- Enumerate `tests-v2/behaviors/*.sh` and launch a loop over all scenario scripts
- Issue an unfiltered model-executing sweep (any invocation that starts `opencode run` sessions for more than the named scenarios the current SC needs)
- Invoke any whole-suite mechanism (a glob over the behaviors directory, an "run all" script, or an unfiltered enumeration)
- Batch "run the suite while you're at it" runs alongside a targeted run

The >2000-run runaway observed during branch-finishing (2026-09-04) is the canonical defect this mandate closes: each unguarded "run the tests" instruction is a latent multi-hour model-execution runaway that masks per-SC evidence.

### ✅ REQUIRED

- **One run per SC need.** Each SC's RED phase runs its named probe scenario once; each SC's GREEN phase runs its named probe scenario once. Re-runs happen only for verified-FAIL remediation, not for coverage.
- **Named scenarios only.** The per-SC re-run instruction names the current branch's SC scenarios explicitly (e.g., `2433-sc1-system-prompt-architecture-b.sh`), never a directory or glob.
- **Derive or ask.** A bare "run the behavioral tests" instruction is answered by deriving the named scenarios needed for the current SC's RED/GREEN evidence (or asking the developer which SCs need testing) — never by enumerating the directory.
- **Guard text scope.** The prohibition scopes to MODEL-EXECUTING invocations (`opencode run` sessions). Content-verification runners (`test-enforcement.sh`, skildeck standalone suites — no model runs) are EXEMPT from the named-scenario requirement; an unfiltered content-verification run is not a model-cost runaway. CI/umbrella content-verification runners are likewise exempt.

### Harness Guard

No whole-suite invocation mechanism exists in this harness: each `opencode run` names its target scenario(s); `behaviors/*.sh` scripts are launched individually via `bash .opencode/tests-v2/behaviors/<scenario>.sh` with the scenario name explicit in the command. An agent that finds itself constructing a loop, glob, or enumeration over `behaviors/*.sh` for model execution MUST stop and derive the named scenarios instead. Enforcing scenario: `2433-sc9-whole-suite-invocation-blocked.sh` (whole-suite attempt → BLOCKED/prohibited).

## 16. Ordering-Gate Behavioral Tests — Role (Advisory — No Runtime Blocking Authority)

The stacked-PR ordering-gate behavioral tests (e.g., `2431-sc*.sh` in `behaviors/`) are the **behavioral-evidence instrument** for the ordering gate's blocking SCs: they generate clean-room model-run artifacts (`session.yaml`) that the two-SC pattern (§6a) pairs with clean-room evaluation — they prove what an agent DOES at parent-PR-creation time, and nothing else. They exercise **no runtime blocking authority** over stacked-PR ordering: a test script runs, produces artifacts, and exits — it never gates, blocks, or permits a real parent stacked PR. The sole authoritative blocking check is the ordering gate at `pr-creation/enforcement-gate` (Step 0.75).

**AUTHORITY:** Spec R-9 — this site carries an advisory/consistency role for the ordering gate and SHALL NOT block PR creation.

## 17. Excessive Run Time — R-18 Cause-Analysis Mandate

**Excessive run time in a behavioral run is a PRIMARY defect signal, not a nuisance to be tolerated.** Excessive run time means: repeated bash-tool timeouts, semantic-monitor aborts (§14 hard-abort signals), large single-turn reasoning blocks, or inference-budget exhaustion. A run that exhibits any of these is usually slow because something is wrong — bad instructions, a skill-deck defect, or another harness problem — not because the model is merely "slow."

**AUTHORITY:** Spec R-18 (extension of the SC-12 deliberation-review directive R-17).

**Implemented predicate mirror (SC-12):** the cause-analysis mandate is exercised by the implemented predicates:

- __fold_false_signal — the SC-10 monitor false-signal annotation appender: appends ONE caller-provided annotation to the `determination.yaml` record's `false_signal_annotations` list under append-only semantics (recorded fields are NEVER rewritten); annotations appear ONLY when an evaluation path identified a wrong abort — an empty/blanket annotation fails (non-zero, `HARNESS_FAILURE`), and missing determination record fails.
- dispatch-failure decoupling — `__interpret_classify_dispatch` (R-13 amendment, pure decision function): a classification dispatch that returns a parsed taxonomy value is a CLASSIFICATION; a dispatch that returns none is a DISPATCH FAILURE — never a classification of its own (no halt-class trigger, no undetermined-ceiling increment), the consecutive-failure counter increments, and checkpoint policy retries on a later qualifying poll.
- dispatch-failure ceiling (`BEHAVIOR_MONITOR_DISPATCH_FAIL_CEILING`, default 3) — 3 consecutive unparseable dispatches trip the harness-failure flag: `MONITOR-HALTED ... halt_reason=dispatch_failure_ceiling` (HARNESS_FAILURE infra halt, checked BEFORE the halt-class exit); the run process is left running for the orchestrator.
- efficiency-defect marker — excessive run time (repeated bash-tool timeouts, §14 monitor aborts, large single-turn reasoning blocks, budget exhaustion) is classified as a PRIMARY efficiency defect signal requiring the R-18 cause analysis above, never written off as model-speed.

### The Mandate

When a behavioral run takes excessively long, the reviewer MUST trace the cause to one of the identified defect classes:

| Defect Class | What to Inspect |
|--------------|-----------------|
| Instructions | The prompt/message sent to the run agent — ambiguous, contradictory, or under-specified directives |
| Task-card/skill-deck wording | The task card or SKILL.md the run agent loaded — wording that induces excessive deliberation, false starts, or off-track reasoning |
| Prompt construction | Prompt shape violating the §11 Prompt Construction Mandate — leading questions, embedded expectations, invalid prompt types |
| Fixture state | Fixture issues, per-scenario fixture scripts, or repo state that derailed the run |
| Harness behavior | `with-test-home`, monitor, or evaluation-harness behavior that inflated run time |

### Fix Fold-In Procedure

1. **Trace the cause** — use the session evidence (session.yaml, reasoning events, §14 monitoring evidence) to identify which defect class fired.
2. **Fold in the fix** — record it as an SC revision or an additional spec; the fix is implemented on the stacked feature branch, never as a side channel.
3. **Test effectiveness** — re-run the affected behavioral probe and verify the fix reduces the run time / eliminates the defect signal.
4. **Adjust and continue** — adjust the fix until it verifies effective; the pipeline continues ONLY after the fix is verified effective. Re-running or blaming the model without cause analysis is PROHIBITED.

This mandate extends the SC-12 deliberation-review directive (R-17): the same evidence review that inspects reasoning traces for excessive deliberation (R-17) also classifies excessive run time as a primary defect signal (R-18). Read [§14 Semantic Continuous Monitoring Mandate](#14-semantic-continuous-monitoring-mandate-behavioral-runs) for the abort signals that flag excessive runs in the first place.

## 18. R-19 — No Hardware/Model-Unavailability Excuse Without Deliberation Evidence

**An agent MUST NOT classify a behavioral-run failure as "hardware limit", "model unavailability", "unobtainable on this hardware", or any equivalent resource excuse without FIRST directly reviewing the actual session evidence of the failed run(s).** (Issue #2432 — extension of the §10.4 fabricated-model-excuse prohibition, and broader: it covers concluding "hardware/model cannot do this" at all.)

**AUTHORITY:** Spec R-19 (extension of the SC-12 deliberation-review directive R-17).

### The Mandate

Before ANY unavailability or resource-limit conclusion, the reviewing agent MUST:

1. **Personally inspect the exported session evidence** of the failed run(s) — the agent's actions (tool calls) and deliberation/thinking (reasoning parts in the session store, e.g. session.yaml / timeline reasoning events). Sub-agent diagnoses are inputs, not substitutes: aggregating sub-agent verdicts without reading the evidence yourself does not satisfy this mandate.
2. **Trace the true reasoning-failure scenario** — what the run agent was thinking when it stalled, skipped a step, or derailed; which instruction it followed or ignored; where the deliberation went off-track (per the R-17 deliberation-review classes: excessive deliberation, false starts, off-track reasoning, prompt/fixture-induced derailment).
3. **Cite the specific reasoning evidence reviewed** in any unavailability claim — the session, events, and reasoning excerpts — alongside the traced failure scenario.

Absent that evidence, the claim is a fabricated excuse (extends §10.4): "the model cannot do this" and "the hardware cannot run this" are conclusions about reasoning, and conclusions about reasoning require reasoning evidence.

### Prohibition

| 🚫 FORBIDDEN | ✅ REQUIRED |
| --- | --- |
| Declaring "unobtainable on this hardware" after aggregating sub-agent diagnoses without reading the session evidence | Personally reviewing the failed run's tool calls and reasoning parts before any unavailability conclusion |
| Citing model size, VRAM, timeout, or unavailability as the failure class without a traced reasoning-failure scenario | Tracing what the run agent was thinking when it stalled/skipped/derailed and which instruction it followed or ignored |
| Treating sub-agent summary verdicts as evidence of unavailability | Citing the specific session, events, and reasoning excerpts reviewed |

This mandate extends the SC-12 deliberation-review directive (R-17): the same deliberation evidence that identifies test-effectiveness findings is also the only admissible basis for a hardware/model-unavailability claim. Read [§10.4 Fabricated Model Excuses](#104-fabricated-model-excuses--absolute-prohibition) for the narrower tool-call-evidence requirement this section generalizes.

---

*Co-authored with AI: OpenCode (ollama-cloud/glm-5.3-flash)*
