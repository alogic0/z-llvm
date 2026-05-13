# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 14: LICM memory promotion

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `collectPromotionCandidates`, `isOnlyMemoryAccess`,
      `promoteLoopAccessesToScalars`, and `LoopPromoter`.
- [x] Define the accepted local IR surface: one invariant stack pointer, one
      preheader store, loop loads/stores only to that pointer, one dedicated
      exit, no aliasing writes, and scalar integer values only.
- [x] Promote the accepted loop memory location to a scalar loop-carried PHI.
- [x] Rewrite loop loads to the current scalar value and loop stores to update
      the scalar value.
- [x] Store the final promoted scalar value to the pointer on the dedicated
      exit edge.
- [x] Add an `opt-22` comparison fixture for the accepted promotion shape.
- [x] Keep multiple exits, aliasing memory, calls, volatile/atomic accesses,
      non-stack pointers, MemorySSA updater precision, debug salvage, and
      general SSAUpdater behavior out of scope and documented.
- [x] Update LICM, MemorySSA/ScalarEvolution boundaries if needed, inventory,
      parity, and loop pipeline docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 14 complete in the roadmap.
