# Cycle 13: Path-Aware MemorySSA Foundation

## Goal

Replace the current conservative memory access-list checks with a path-aware
MemorySSA foundation only where source-backed fixtures justify the complexity.

## Source Anchors

- Current MemorySSA design docs
- Local code: `src/analysis/memory_ssa.zig`, EarlyCSE, GVN, DSE
- LLVM: `MemorySSA`, `MemorySSAUpdater`, `MemoryUse`, `MemoryDef`, `MemoryPhi`
- Source-backed memory precision blockers

## Plan

- [x] Add a reduced source-backed fixture where current conservative memory
      checks block a needed transform.
- [x] Model basic MemoryDef, MemoryUse, and MemoryPhi relationships across CFG
      edges.
- [x] Add a clobber walker that respects dominance and path reachability.
- [x] Keep updater support out of scope unless a mutating pass needs it.
- [x] Wire only one pass first, then expand after tests prove the API shape.
- [x] Document exact differences from LLVM MemorySSA.

## Exit Criteria

- [x] One source-backed memory precision blocker is solved by path-aware facts.
- [x] Existing conservative memory fixtures still pass.
- [x] MemorySSA limitations are documented beside tests.

## Completed Slice

- Added CFG reachability to the MemorySSA access-list clobber query so
  unrelated/unreachable blocks are not treated as intervening clobbers.
- Wired the first precision gain through EarlyCSE with a local-conservative
  fixture where a side-exit store no longer blocks load CSE on the path that
  bypasses it; `opt-22` preserves this shape, so broader load-placement parity
  remains future work.
- Kept MemorySSAUpdater, optimized defs, and full LLVM walker behavior out of
  scope and documented the remaining differences.
