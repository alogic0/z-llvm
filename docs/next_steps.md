# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 12: `loop-deletion` for provably side-effect-free finite loops

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `LoopDeletionPass::run`, `deleteDeadLoop`, `isLoopDead`, and
      ScalarEvolution-backed exit count checks.
- [x] Define the accepted local IR surface: single-latch counted loop with
      preheader, one dedicated exit, `mustprogress`, pure scalar loop body, and
      no outside uses of loop-defined values.
- [x] Replace the `loop-deletion` placeholder with a real loop pass for that
      surface.
- [x] Delete the accepted side-effect-free loop by retargeting the preheader to
      the exit and removing unreachable loop blocks.
- [x] Add an `opt-22` comparison fixture for the accepted finite loop.
- [x] Keep unknown trip counts, memory effects, calls, live loop outputs, multi-exit loops,
      non-dedicated exits, nested loops, and SCEV generality out of scope and
      documented.
- [x] Update loop deletion and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 12 complete in the roadmap.
