# Cycle 3: CFG Mutation, ADCE, And SimplifyCFG

## Goal

Strengthen CFG mutation so ADCE and SimplifyCFG can delete or rewrite more dead
control flow without corrupting PHIs, dominance, or postdominance facts.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/ADCE.cpp`
- LLVM: `llvm/lib/Transforms/Utils/SimplifyCFG.cpp`
- LLVM analyses: `PostDominatorTree`, `DominatorTree`, control dependence
- Local docs: `docs/passes/adce.md`, `docs/passes/simplifycfg.md`,
  `docs/analysis/cfg.md`, `docs/analysis/postdominator.md`
- Local code: `src/passes/adce.zig`, `src/passes/simplifycfg.zig`,
  `src/analysis/cfg.zig`, `src/analysis/postdominator.zig`

## Plan

- [x] Add a small CFG update helper for deleting edges, deleting blocks, and
      retargeting branches.
- [x] Centralize PHI incoming update/removal after edge deletion.
- [x] Add verifier checks that catch stale PHI incoming blocks after CFG edits.
- [x] Extend postdominator/control-dependence tests to diamonds, nested
      diamonds, loops, multiple exits, and unreachable blocks.
- [ ] Rework ADCE liveness toward an explicit block/instruction worklist for
      the supported CFG surface.
- [ ] Mark live branch terminators from control dependence where the local
      postdominator model proves it.
- [ ] Let ADCE delete more dead branch regions when PHI repair is locally safe.
- [ ] Extend SimplifyCFG empty-block threading and branch folding with the same
      CFG update helper.
- [ ] Keep EH, invoke, switch, indirectbr, musttail, and debug salvage deferred.
- [ ] Add accepted and rejected `opt-22` fixtures for every CFG rewrite shape.

## Exit Criteria

- [x] ADCE and SimplifyCFG use shared CFG/PHI mutation helpers.
- [ ] Rewritten CFGs pass verifier checks for PHIs, terminators, and block
      reachability.
- [ ] Unsupported CFG shapes are rejected or left unchanged with fixtures.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

## Completed Slice

- [x] Added `src/analysis/cfg_update.zig` for branch retargeting, PHI incoming
      block replacement, PHI pruning, and unreachable block deletion.
- [x] Routed SimplifyCFG empty-block threading, trivial branch-block merging,
      PHI pruning, and unreachable deletion through the shared helper.
- [x] Routed ADCE's supported branch rewrite through shared PHI pruning after
      edge deletion.
- [x] Documented the helper as a rebuild-and-repair subset of LLVM's CFG update
      utilities.
- [x] Verified with `zig build test` and `bash scripts/compare_opt.sh`.

## Completed Analysis Coverage Slice

- [x] Added nested-diamond postdominator and control-dependence coverage.
- [x] Added loop postdominator coverage for header/body/exit relationships.
- [x] Added multiple-exit coverage where no single immediate postdominator is
      available.
- [x] Added unreachable-block coverage to keep local postdominator behavior
      explicit for dead regions.
- [x] Verified with `zig build test`.
