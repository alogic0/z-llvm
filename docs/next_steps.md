# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 6: EarlyCSE load availability through MemorySSA

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `EarlyCSE`, `LoadValue`, `AvailableLoads`,
      `isSameMemGeneration`, and `MemorySSA::getWalker` entry points.
- [x] Define the accepted local IR surface: non-volatile, non-atomic scalar
      loads with must-alias pointers and MemorySSA-proven no clobber.
- [x] Rework EarlyCSE load equivalence to call the MemorySSA walker directly.
- [x] Preserve store-to-load forwarding as a separate local store availability
      path until LLVM's store generation model is reproduced.
- [x] Add an `opt-22` positive fixture for a readonly call that does not
      clobber repeated load availability.
- [x] Keep negative clobber fixtures for unknown calls, branch-local stores,
      volatile/atomic loads, and ambiguous aliases.
- [x] Update EarlyCSE, MemorySSA, and parity docs.
- [x] Run focused EarlyCSE comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 6 complete in the roadmap.
