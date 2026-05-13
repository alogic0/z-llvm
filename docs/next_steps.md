# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 16: SROA rewrite for debug-free aggregate allocas

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `SROA::splitAlloca`, `presplitLoadsAndStores`,
      `SROA::rewritePartition`, and `AllocaSliceRewriter`.
- [x] Define the accepted local IR surface: entry-block aggregate allocas,
      whole-aggregate nonvolatile loads/stores, named aggregate store values,
      scalar integer or DataLayout-backed pointer fields, and no debug declare.
- [x] Build synthetic scalar field partitions for whole-aggregate load/store
      users when no field GEP partitions exist.
- [x] Rewrite aggregate stores into per-field `extractvalue` plus scalar stores.
- [x] Rewrite aggregate loads into scalar loads plus `insertvalue`
      reconstruction and replace uses of the old aggregate load.
- [x] Keep PHI/select speculation, debug salvage, integer widening, vector
      promotion, partial overlap splitting, volatile/atomic accesses, and
      memcpy/memmove out of scope and documented.
- [x] Add an `opt-22` comparison fixture for the aggregate load/store rewrite.
- [x] Update SROA and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 16 complete in the roadmap.
