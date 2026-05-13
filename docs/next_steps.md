# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 19: Fast-math CSE legality

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `Instruction::isIdenticalToWhenDefined`,
      EarlyCSE `SimpleValue` equality/`combineIRFlags`, and GVN value-table
      expression equality for FP operations.
- [x] Define the accepted local IR surface: scalar non-constrained FP
      `fadd`/`fsub`/`fmul`/`fdiv`/`frem` and `fcmp` with identical operands.
- [x] Remove the local `fast`-only CSE gate for that accepted surface.
- [x] Intersect retained leader fast-math flags when EarlyCSE/GVN replace a
      duplicate FP expression.
- [x] Keep constrained FP intrinsics, dynamic rounding, vectors, commuted FP
      equality, min/max select matching, and full poison/debug salvage out of
      scope and documented.
- [x] Add `opt-22` comparison fixtures for strict, partial-FMF, and mixed-FMF
      FP CSE.
- [x] Update EarlyCSE/GVN/fast-math docs and parity docs, then mark Slice 19
      complete.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 19.
