# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 24: TargetTransformInfo skeleton

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `TargetTransformInfo`, `getArithmeticInstrCost`,
      `getShuffleCost`, and scalarization-overhead query boundaries.
- [x] Add local target-cost query objects for generic, x86_64, and AArch64.
- [x] Model a first scalar/vector cost surface for integer/FP arithmetic and
      vector shuffle-like operations.
- [x] Keep the skeleton analysis-only; do not enable vectorizer-quality
      transforms from these costs yet.
- [x] Add focused unit coverage for x86_64, AArch64, and generic vector costs.
- [x] Update target-cost, vector, parity, and roadmap docs.
- [x] Run focused tests.
- [x] Run readiness checks.
- [x] Review and commit Slice 24.
