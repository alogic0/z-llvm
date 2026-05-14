# Project Finish Statement

This repository has reached the finish line defined by the current
Zig-aligned LLVM replacement experiment.

## Finished Scope

- The readiness gate passes for the selected corpus and validation matrix.
- The Zig IR manifest has no unsupported rows in the finish corpus.
- Remaining future rows are explicit boundaries, not unowned blockers.
- Accepted rows document the local pipeline they exercise.
- Optimizer behavior is fixture-backed and does not claim full LLVM algorithm
  parity.
- Debug info, atomics, inline asm, vectors, EH, TLS, module flags, bitcode/LTO,
  and backend work have explicit conservative or out-of-scope boundaries.
- Native backend and AIR handoff evidence remains validation-only and bounded
  to the documented x86_64 smoke subset.

## Latest Finish Evidence

```text
bash scripts/run_readiness_checks.sh
ok manifest rows=40 optimizer_input=33
summary accepted=33 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```

Accepted optimizer discovery was also rerun across all Zig optimization modes
against the current `../ziglang` stage4 emitter and local ReleaseFast
`z_llvm` checker:

```text
tmp/zig_ir/optimizer_discovery_03_debug
  mode=Debug
  passes=zig-debug-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/optimizer_discovery_05_releasefast
  mode=ReleaseFast
  passes=zig-release-fast-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/optimizer_discovery_06_releasesafe
  mode=ReleaseSafe
  passes=zig-release-safe-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/optimizer_discovery_07_releasesmall
  mode=ReleaseSmall
  passes=zig-release-small-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
```

## Non-Goals

- Full LLVM clone.
- Full pass-for-pass optimizer parity.
- Full MC/Object replacement.
- Full ThinLTO or bitcode summary implementation.
- Full debug variable-location salvage.
- Target-complete vectorization and cost modeling.
- Broad backend parity across targets and ABIs.

## Future Work Rule

Do not continue by default. Future work should start only from
`docs/roadmap/future_optimizer_backlog.md` or from a new measured
source-backed blocker. Any new cycle must name the LLVM upstream mapping,
fixture evidence, local conservative boundary, and readiness-gate impact before
it can be marked complete.
