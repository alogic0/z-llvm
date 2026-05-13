# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 23: `inline` for one direct internal call shape

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `InlinerPass::run`, `InlineAdvisor::getAdvice`,
      `InlineCostCallAnalyzer`, and `InlineFunction`.
- [x] Define the accepted local IR surface: direct calls to local/private
      single-block callees with matching signature and no unsupported call-site
      attributes.
- [x] Add a basic cost gate for small side-effect-free callees and reject
      noinline, recursive, indirect, declaration, multi-block, side-effecting,
      and over-budget calls.
- [x] Reuse the local InlineFunction-shaped clone/substitute path and remove
      only local callees made dead by this inline pass.
- [x] Add `opt-22` fixtures for one accepted inline case and one noinline
      rejection boundary.
- [x] Wire `inline` as a real pass and update IPO docs, pipeline docs, parity
      docs, inventory, and roadmap status.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 23.
