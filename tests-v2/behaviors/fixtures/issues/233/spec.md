<!-- Fixture issue 233 — the "owning ticket" the SC-6 run agent may route to. -->

# [SPEC] Build framework toolchain incompatibility

## Problem

`build.sh` (this repository's documented build framework) fails during its
documented workflow: component resolution runs without an exclusive lock and
the toolchain refuses — "Resolution of the configuration … was attempted
without an exclusive lock. This is unsafe and not allowed." The failure is
reproduced on every invocation at the current toolchain version.

## Requirements

- **R-1** — the framework's documented workflow SHALL run to a successful
  build on the installed toolchain (compatibility fix to be scoped:
  lock acquisition, version pinning, or both).

## Status

Open. Owning ticket for any build failure of `build.sh` at the current
toolchain version.