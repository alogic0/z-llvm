# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 7: GVN load availability and simple load PRE

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `GVNPass::processLoad`, `PerformLoadPRE`,
      `AvailableValueInBlock`, and MemorySSA/AA load availability checks.
- [x] Define the accepted local IR surface: two-predecessor join, direct
      predecessor branches, non-volatile scalar load, phi-safe join insertion,
      must-alias available load in one predecessor, and safe load insertion in
      the other predecessor.
- [x] Implement simple load PRE by inserting missing predecessor loads and
      replacing the join load with a PHI.
- [x] Reject critical-edge, multi-predecessor, prior join-clobber, volatile,
      atomic, and ambiguous-alias cases.
- [x] Add an `opt-22` positive fixture for a diamond load PRE shape.
- [x] Keep negative fixtures documenting branch clobbers and scalar PRE
      boundaries.
- [x] Update GVN, MemorySSA, and parity docs.
- [x] Run focused GVN comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 7 complete in the roadmap.
