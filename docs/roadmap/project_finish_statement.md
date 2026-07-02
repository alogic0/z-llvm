# Optimizer/IR-Layer Milestone Finish Statement

> **Superseded as a project-level statement (2026-07-02).** This document
> records the finish of an earlier, narrower milestone: the optimizer/IR
> layer with bounded x86_64 smoke evidence. It is kept as a historical
> record. Project-level scope, definition of done, and the active work
> queue are now defined by
> [`end_to_end_convergence_plan.md`](end_to_end_convergence_plan.md) and
> tracked in [`convergence_progress.md`](convergence_progress.md). The
> "Future Work Rule" below no longer governs worker cycles.

This repository reached the finish line defined by the earlier
Zig-aligned optimizer/IR-layer effort to replace the LLVM library dependency
used by Zig's distribution.

## Finished Scope

- The readiness gate passes for the selected corpus and validation matrix.
- The implemented scope is tied to LLVM behavior that Zig's distribution needs,
  not to a full LLVM clone.
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
zig build readiness
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

## Future Work Rule (superseded)

Historical rule for the optimizer/IR-layer milestone; superseded by the
convergence plan. Active worker goal selection is defined in
`docs/working-cycle.md` and `docs/roadmap/convergence_progress.md`.

Original text: Do not continue by default. Future work should start only from
`docs/roadmap/future_optimizer_backlog.md` or from a new measured
source-backed blocker. Any new cycle must name the LLVM upstream mapping,
fixture evidence, local conservative boundary, and readiness-gate impact before
it can be marked complete.
