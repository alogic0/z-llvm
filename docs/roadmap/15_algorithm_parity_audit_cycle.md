# Cycle 15: Algorithm Parity Audit

## Goal

Turn the current pass-by-pass documentation into a source-backed parity audit:
for every LLVM optimization Zig invokes, state what local code implements,
which fixtures prove it, and which LLVM algorithm pieces remain missing.

## Source Anchors

- Local inventory: `docs/inventory/zig_llvm_pass_pipeline_inventory.md`
- Local roadmap: `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`
- Local rubric: `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`
- LLVM source tree: `../llvm-project` or the configured LLVM 22 source checkout

## Plan

- [ ] Build a pass-by-pass parity table from the current source and docs.
- [ ] For every non-placeholder pass, list LLVM source files and local files.
- [ ] Mark each pass as fixture-equivalent, LLVM-shaped subset, or
      algorithm-parity target.
- [ ] Add a missing-analysis column for DominatorTree, MemorySSA, TTI,
      AssumptionCache, LoopInfo, and DataLayout.
- [ ] Add a missing-IR-surface column for parser/verifier blockers.
- [ ] Create follow-up issues or roadmap links for every high-risk gap.
- [ ] Reconcile pass docs whose target status is stale.

## Exit Criteria

- [ ] The project has a single current parity table.
- [ ] Every implemented pass has source-backed LLVM mapping.
- [ ] Remaining gaps are linked to active or future cycles.

