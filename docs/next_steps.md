# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 8: DSE overwrite lattice for partial stores

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `OverwriteResult`, `isOverwrite`, `isPartialOverwrite`, and
      `InstOverlapIntervalsTy` entry points.
- [x] Define the accepted local IR surface: same-block non-volatile integer
      stores with known byte offsets and fixed byte sizes.
- [x] Add a small byte-interval lattice for later partial stores that together
      fully cover an earlier store.
- [x] Preserve existing barriers: intervening loads, calls, volatile/atomic
      memory, unknown locations, may-alias accesses, and cross-block DSE.
- [x] Add an `opt-22` positive fixture where two later byte stores fully cover
      an earlier wider integer store.
- [x] Keep the existing partial-overwrite rejection fixture for incomplete
      coverage.
- [x] Update DSE, MemorySSA, and parity docs.
- [x] Run focused DSE comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 8 complete in the roadmap.
