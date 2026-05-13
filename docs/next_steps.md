# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 18b: APFloat-backed strict `fadd`/`fmul` constants

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `InstructionSimplify.cpp` constant binary folding and
      `InstCombineAddSub.cpp`/`InstCombineMulDivRem.cpp` strict FP handling.
- [x] Define the accepted local IR surface: scalar `float`/`double` `fadd`
      and `fmul` with literal FP operands where the result can reuse an
      existing operand spelling.
- [x] Fold strict `fadd` with positive-zero literal plus finite non-negative
      literal to the non-zero operand.
- [x] Fold strict `fmul` with one literal `1.0` to the other literal, and
      positive-zero times finite non-negative literal to the zero operand.
- [x] Keep general APFloat result formatting, negative zero edge cases,
      infinities times zero, NaNs, rounding modes, exceptions, vectors, and
      fast-math-sensitive variable folds out of scope and documented.
- [x] Add `opt-22` comparison fixtures for selected strict `fadd`/`fmul`
      constant folds.
- [x] Update InstCombine docs and parity docs, then mark Slice 18 complete.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit this Slice 18 sub-slice.
