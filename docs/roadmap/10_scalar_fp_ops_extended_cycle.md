# Cycle 10: Extended Scalar FP Operations

## Goal

Add scalar `fsub`, `fdiv`, and `frem` only when source-backed fixtures require
them, preserving strict semantics and keeping optimization conservative.

## Source Anchors

- Future FP Zig source groups
- LLVM IR: `fsub`, `fdiv`, `frem`
- Existing FP parser/verifier and pass-through fixtures
- LLVM comparison: preserve-only `opt-22` fixtures

## Plan

- [x] Add source-backed fixtures that emit each operation before implementation.
- [x] Extend binary-op parsing, printing, verification, and tests for observed
      operations.
- [x] Keep fast-math flags and FP exception behavior unsupported.
- [x] Add pass-through fixtures for DCE, ADCE, GVN, EarlyCSE, SCCP, and
      InstCombine.
- [x] Reject vector variants until vector FP semantics are separately modeled.
- [x] Update manifest classification after accepted rows pass local pipelines.

## Exit Criteria

- [x] Required extended scalar FP operations are accepted and preserved.
- [x] Unsupported FP operations still fail closed.
- [x] No FP arithmetic optimization is introduced without comparison fixtures.

## Completed Slice

- Added `fp_extended_ops` as a source-backed Zig corpus group covering scalar
  `fsub`, `fdiv`, and `frem`.
- Extended scalar FP binary parsing, printing, verification, and unit coverage
  while keeping vector FP binary ops, fast-math flags, constrained FP, and FP
  exception semantics fail-closed.
- Added preserve/no-CSE fixtures for InstCombine, DCE, ADCE, GVN, EarlyCSE, and
  SCCP; the local passes still do not fold or value-number FP arithmetic.
