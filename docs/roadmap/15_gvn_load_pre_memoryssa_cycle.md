# Cycle 15: GVN Load And PRE Expansion With MemorySSA

## Goal

Expand GVN load availability and limited PRE only when MemorySSA and dominance
facts can prove correctness for source-backed rows.

## Source Anchors

- Local pass: `src/passes/gvn.zig`
- LLVM: `GVN.cpp`, MemoryDependence, MemorySSA
- Current fixtures: load/call clobber, branch clobber, scalar GVN
- Source-backed memory rows

## Plan

- [x] Add a source-backed load redundancy fixture that current GVN cannot handle.
- [x] Use MemorySSA clobber walks for load availability.
- [x] Add dominance and same-value checks for safe load replacement.
- [x] Add local-only conservative fixtures for PRE cases LLVM handles but local
      support still rejects.
- [x] Keep full PRE, value-table completeness, and complex memory dependence out
      of scope.
- [x] Compare accepted load cases with `opt-22`.

## Exit Criteria

- [x] One new GVN load optimization is source-backed and tested.
- [x] Unsafe clobber and path cases remain rejected.
- [x] GVN docs update fixture-equivalent vs local-conservative status.

## Completed Slice

- Added a path-aware GVN load fixture that reuses the MemorySSA access-list
  reachability proof from Cycle 13.
- Kept full PRE and LLVM load-placement parity out of scope; the new fixture is
  local-conservative because `opt-22` preserves the side-exit shape.
- Existing clobber rejection fixtures continue to cover unsafe branch and call
  cases.
