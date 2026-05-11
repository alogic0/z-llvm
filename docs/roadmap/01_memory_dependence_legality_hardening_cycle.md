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

- [x] Add direct clobber-helper unit tests for:
      load/load with no intervening clobber,
      load/store/load same pointer,
      load/store/load no-alias pointer,
      load/may-alias store/load,
      load/unknown call/load,
      load/readnone call/load,
      load/readonly call/load,
      volatile and atomic barriers.
- [x] Add `opt-22` fixtures for the same cases where LLVM behavior should
      match the local conservative model.
- [x] Route EarlyCSE load CSE through the shared clobber helper only.
- [x] Route GVN load availability through the same helper for every load
      replacement path.
- [x] Decide whether DSE should keep its single-block reverse scan or move to
      the helper; document the chosen boundary.
- [x] Expand `alias.modRef` only for proven accepted IR shapes; keep unknowns
      conservative.
- [x] Add fixture metadata that separates LLVM-equivalent cases from local-only
      conservative cases.
- [x] Document the exact gap from real LLVM MemorySSA: no MemoryPhi placement,
      no persisted def/use graph, no updater, no path-sensitive walker.

## Exit Criteria

- [x] Load CSE and load GVN share one tested clobber decision path.
- [x] Every memory transform has a rejected fixture for the nearest unsafe
      variant.
- [x] Volatile, atomic, unknown-call, and may-alias cases are protected by
      tests.
- [x] `zig build test` and `bash scripts/compare_opt.sh` pass.

## Completed Slice

Closed as a shared clobber-helper hardening slice:

- `src/analysis/memory_ssa.zig` now classifies readnone/readonly calls as
  non-clobbering and keeps unknown calls, same-pointer stores, may-alias stores,
  volatile accesses, and atomic accesses conservative.
- EarlyCSE and GVN load replacement paths use the same helper.
- DSE remains on its single-block reverse scan by design until the shared
  helper models overwrite direction and MemoryPhi-like joins.
