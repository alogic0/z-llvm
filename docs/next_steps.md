# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 26: SLP vectorizer recognition-only pass

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `SLPVectorizerPass::run`, `collectSeedInstructions`,
      `tryToVectorizeList`, and BoUpSLP tree/profitability boundaries.
- [x] Define the accepted local recognition surface: same-block, straight-line,
      same-op scalar binary instructions with matching flags and type.
- [x] Replace the executable placeholder with a real recognition-only pass.
- [x] Emit an explicit unsupported diagnostic through pass context when a
      bundle is recognized but BoUpSLP rewriting is unavailable.
- [x] Add fixture coverage proving the pass preserves IR while recognizing the
      unsupported transformation boundary.
- [x] Update vector, target-cost, parity, inventory, and roadmap docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 26.
