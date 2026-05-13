# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 17: InstCombine overflow-flag legality

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `InstructionSimplify` flagged binary folds,
      `InstCombineAddSub.cpp`, `InstCombineMulDivRem.cpp`, and
      `InstCombineShifts.cpp` flag handling.
- [x] Define the accepted local IR surface: scalar integer `mul`, `shl`,
      `lshr`, and `ashr` folds where the folded result is independent of the
      poison-generating flag.
- [x] Extend flagged multiply-by-zero folding for `nsw` and `nuw`.
- [x] Extend flagged zero-shift-source folding for `shl nsw/nuw`,
      `lshr exact`, and `ashr exact`.
- [x] Keep reassociation, flag propagation to newly created instructions,
      known-bits inference, non-zero shift amount reasoning, and vector flags
      out of scope and documented.
- [x] Add `opt-22` comparison fixtures for the accepted folds and rejected
      overflow-sensitive folds.
- [x] Update InstCombine docs and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 17 complete in the roadmap.
