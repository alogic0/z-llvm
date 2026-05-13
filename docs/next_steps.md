# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 2: `jump-threading` for constant predecessor conditions

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map `JumpThreadingPass` upstream entry points.
- [x] Define the accepted local IR surface: conditional branch on an in-block
      `i1` PHI whose predecessor incoming values are integer constants.
- [x] Implement predecessor-specific successor selection using the PHI incoming
      value, matching LLVM's `processThreadableEdges` decision shape.
- [x] Retarget unconditional predecessor edges and repair PHI incoming entries
      in old and new successors.
- [x] Preserve unsupported cases without marking the pass complete for those
      cases: non-PHI conditions, non-constant incoming values, switch,
      indirectbr, loop-header threading, block duplication, and metadata
      profile updates.
- [x] Add `opt-22` comparison fixtures for the positive branch-on-PHI case and
      a non-PHI condition rejection boundary.
- [x] Update pass docs and the algorithm parity audit.
- [x] Run focused comparison and readiness checks.
- [x] Review, commit, and mark Slice 2 complete in the roadmap.
