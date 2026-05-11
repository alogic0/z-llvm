# Cycle 16: LICM Memory-Hoisting Legality

## Goal

Start memory-aware LICM only after alias and MemorySSA facts prove that a load or
store motion is safe for a source-backed loop fixture.

## Source Anchors

- Local pass: `src/passes/licm.zig`
- LLVM: `LICM.cpp`, AliasAnalysis, MemorySSA, LoopSafetyInfo
- Source-backed loop/memory rows
- Existing LICM scalar fixtures

## Plan

- [x] Add a source-backed loop fixture with a candidate invariant memory access.
- [x] Implement safety checks for preheader, dominance, no clobber, and no
      trapping behavior where required.
- [x] Hoist only readonly nonvolatile loads with proven invariant address first.
- [x] Keep stores, sinking, promotion, atomics, calls, exceptions, and multi-exit
      memory motion out of scope.
- [x] Add rejected fixtures for unknown alias, variant address, no preheader, and
      side effects.
- [x] Compare accepted cases with `opt-22`.

## Exit Criteria

- [x] One memory LICM case is accepted and source-backed.
- [x] Unsafe memory motion remains rejected with fixtures.
- [x] LICM docs distinguish scalar LICM from memory LICM.

## Completed Slice

- Added the first memory LICM case: a nonvolatile invariant load in the loop
  header can move to an existing preheader when no loop instruction clobbers
  that access.
- Added a local-conservative rejection fixture where a may-alias store blocks
  the load hoist; `opt-22` may still perform other loop rewrites around that
  shape.
- Left stores, non-header loads, sinking, promotion, calls, atomics, exceptions,
  and MemorySSA updater behavior out of scope.
