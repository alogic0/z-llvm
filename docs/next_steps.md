# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 4: `lower-expect` and branch-weight metadata preservation

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map `LowerExpectIntrinsic` upstream entry points.
- [x] Define the accepted local IR surface: direct `llvm.expect.i1` calls whose
      result feeds a same-block `br i1`.
- [x] Implement branch condition replacement with the expect operand.
- [x] Attach branch-weight metadata matching LLVM's default expected weights.
- [x] Remove supported `llvm.expect.i1` calls by replacing their uses with the
      first operand.
- [x] Preserve unsupported cases without marking the pass complete for those
      cases: `expect.with.probability`, switch/select/phi handling,
      non-constant expected values, non-i1 forms, existing profile merge
      policy, and debug salvage.
- [x] Add `opt-22` comparison fixtures for the positive branch case and an
      unsupported non-i1 preservation boundary.
- [x] Update pass docs, pipeline docs, inventory status, and the algorithm
      parity audit.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 4 complete in the roadmap.
