# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 27: PGO/profile metadata propagation for SimplifyCFG

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `SimplifyCFG.cpp` profile metadata update paths and
      `ProfDataUtils` branch-weight helpers.
- [x] Choose one accepted CFG rewrite: empty diamond `phi`/`ret` folding to
      `select`/`ret`.
- [x] Preserve `!prof` branch-weight metadata from the conditional branch on
      the new select, matching LLVM's profile propagation for this shape.
- [x] Add an `opt-22` equivalent fixture for the profile-preserving diamond
      select rewrite.
- [x] Update SimplifyCFG, PGO/size, parity, and roadmap docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 27.
