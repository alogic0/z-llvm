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
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
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
