# Cycle 1: Memory Dependence And Legality Hardening

## Goal

Make memory availability and clobber reasoning boringly correct before adding
more optimization power. EarlyCSE and GVN must not replace loads, calls, or
stores unless the shared legality layer proves the transformation safe for the
accepted IR surface.

## Source Anchors

- LLVM analyses: `MemorySSA`, `MemoryDependenceAnalysis`, `AliasAnalysis`,
  `ModRefInfo`, `MemoryLocation`
- LLVM users: `EarlyCSE`, `GVN`, `DSE`, `LICM`
- Local docs: `docs/analysis/memory_ssa.md`, `docs/analysis/alias.md`,
  `docs/analysis/memory_location.md`, `docs/analysis/memory_effect.md`
- Local code: `src/analysis/memory_ssa.zig`, `src/analysis/alias.zig`,
  `src/passes/early_cse.zig`, `src/passes/gvn.zig`, `src/passes/dse.zig`

## Plan

- [ ] Add direct clobber-helper unit tests for:
      load/load with no intervening clobber,
      load/store/load same pointer,
      load/store/load no-alias pointer,
      load/may-alias store/load,
      load/unknown call/load,
      load/readnone call/load,
      load/readonly call/load,
      volatile and atomic barriers.
- [ ] Add `opt-22` fixtures for the same cases where LLVM behavior should
      match the local conservative model.
- [ ] Route EarlyCSE load CSE through the shared clobber helper only.
- [ ] Route GVN load availability through the same helper for every load
      replacement path.
- [ ] Decide whether DSE should keep its single-block reverse scan or move to
      the helper; document the chosen boundary.
- [ ] Expand `alias.modRef` only for proven accepted IR shapes; keep unknowns
      conservative.
- [ ] Add fixture metadata that separates LLVM-equivalent cases from local-only
      conservative cases.
- [ ] Document the exact gap from real LLVM MemorySSA: no MemoryPhi placement,
      no persisted def/use graph, no updater, no path-sensitive walker.

## Exit Criteria

- [ ] Load CSE and load GVN share one tested clobber decision path.
- [ ] Every memory transform has a rejected fixture for the nearest unsafe
      variant.
- [ ] Volatile, atomic, unknown-call, and may-alias cases are protected by
      tests.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

