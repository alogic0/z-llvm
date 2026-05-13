# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 18a: APFloat-backed strict `fcmp` constants

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `InstructionSimplify.cpp` `SimplifyFCmpInst` and APFloat
      comparison behavior.
- [x] Define the accepted local IR surface: scalar `float`/`double` `fcmp`
      with literal FP operands, including finite numbers, zeros, infinities,
      and NaNs.
- [x] Evaluate ordered and unordered strict `fcmp` predicates from classified
      FP literals instead of preserving them.
- [x] Keep `fadd`/`fmul` result-producing folds, rounding modes, exceptions,
      vectors, x86_fp80/fp128, and fast-math-sensitive folds out of this
      sub-slice and documented as the next Slice 18 work.
- [x] Add `opt-22` comparison fixtures for strict finite and NaN comparisons.
- [x] Update InstCombine docs and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit this Slice 18 sub-slice.
