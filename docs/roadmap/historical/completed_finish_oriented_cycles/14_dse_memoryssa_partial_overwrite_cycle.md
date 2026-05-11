# Cycle 14: DSE With MemorySSA And Partial Overwrite Boundaries

## Goal

Improve Dead Store Elimination using MemorySSA-backed legality while explicitly
bounding partial-overwrite and intrinsic behavior.

## Source Anchors

- Local pass: `src/passes/dse.zig`
- LLVM: `DeadStoreElimination.cpp`, MemorySSA walker
- Memory fixtures: store overwrite, load barrier, volatile, atomic, partial
      ranges
- Source-backed pointer and aggregate rows

## Plan

- [x] Add source-backed or reduced fixtures for overwrite cases current DSE
      misses.
- [x] Use MemorySSA clobber facts to find safe same-location later stores across
      simple CFG shapes.
- [x] Add memory range checks for full overwrite vs partial overlap.
- [x] Preserve loads, volatile, atomic, calls, and unknown alias barriers.
- [x] Keep memset/memcpy and lifetime intrinsic DSE out of scope unless captured.
- [x] Compare accepted cases against `opt-22`.

## Exit Criteria

- [x] DSE removes at least one new source-backed safe dead store.
- [x] Partial overwrite and alias ambiguity are tested as rejected.
- [x] Docs explain remaining LLVM DSE gaps.

## Completed Slice

- Hardened the existing MemorySSA-owned same-block overwrite query so a later
  store must fully cover the earlier store range before DSE deletes it.
- Added an `opt-22` partial-overwrite rejection fixture for same-offset
  different-width stores.
- Kept cross-block DSE, memcpy/memset, lifetime intrinsics, and partial-overlap
  elimination out of scope.
