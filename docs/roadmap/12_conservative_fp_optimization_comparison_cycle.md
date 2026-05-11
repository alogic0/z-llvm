# Cycle 12: Conservative FP Optimization Comparison

## Goal

Begin comparing strict and flagged FP behavior with `opt-22`, adding only
conservative transforms that are proven correct for source-backed fixtures.

## Source Anchors

- Accepted FP corpus rows
- LLVM passes: InstSimplify, InstCombine, SCCP, GVN, EarlyCSE, DCE, ADCE
- LLVM comparison: `opt-22`
- Docs: FP semantics and pass docs

## Plan

- [x] Build strict-FP opt fixture groups for preserve-only behavior.
- [x] Add dead FP instruction elimination comparisons for DCE and ADCE.
- [x] Add negative fixtures for NaN, signed zero, and fast-math-sensitive cases.
- [x] Consider only trivial folds proven identical to LLVM under the accepted
      semantics.
- [x] Keep reassociation, reciprocal transforms, and target-cost transforms out
      of scope.
- [x] Document every local-conservative difference.

## Exit Criteria

- [x] FP pass behavior has explicit `opt-22` comparison coverage.
- [x] Conservative FP transforms are implemented only where proven.
- [x] Remaining FP optimizer gaps are listed in the backlog.

## Completed Slice

- Added a strict FP preservation fixture for add-zero, which LLVM also preserves
  because signed-zero behavior blocks the ordinary scalar identity.
- Added a local-conservative fast-math-sensitive fixture documenting that LLVM
  can fold more for flagged and other FP-sensitive identities, while this
  project still preserves until FP legality is implemented.
- Recorded remaining FP optimizer parity work in the future optimizer backlog.
