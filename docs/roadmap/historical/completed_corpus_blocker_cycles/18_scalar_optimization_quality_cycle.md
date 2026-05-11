# Cycle 18: Scalar Optimization Quality

## Goal

Improve optimization quality for scalar Zig IR after correctness foundations are
in place, focusing on profitable folds that are source-backed and easy to
validate against LLVM.

## Source Anchors

- LLVM: `InstCombine`, `InstructionSimplify`, `SCCP`, `BDCE`, `CorrelatedValuePropagation`
- Local code: `src/passes/instcombine.zig`, `src/passes/inst_simplify.zig`,
  `src/passes/sccp.zig`
- Corpus rows: `tiny_scalar`, `integers`

## Plan

- [x] Add scalar fold gaps from integer corpus to InstCombine docs.
- [x] Expand known-bits or demanded-bits only for tested integer cases.
- [x] Improve SCCP undef/poison-adjacent behavior where local IR can model it.
- [x] Add BDCE-style bit-demanded cleanup as a separate conservative pass.
- [x] Add CVP only after assumptions and branch facts are represented.
- [x] Compare quality-sensitive fixtures with `opt-22`.

## Exit Criteria

- [x] Scalar corpus output moves closer to LLVM without unsafe folds.
- [x] Flag-sensitive arithmetic remains conservative.
- [x] Quality improvements have direct fixtures.

## Completion Notes

- Added a real `bdce` pass for the narrow demanded-low-bits case reproduced
  from LLVM BDCE: a single-use wider integer `and` mask feeding a narrower
  integer `and` mask.
- Added `bdce_and_mask` as an `opt-22` equivalent fixture.
- Kept CVP as a placeholder because local assumptions and branch range facts
  are not represented beyond existing SCCP CFG facts.
- Kept flag-sensitive arithmetic conservative; the new BDCE rule rejects
  flagged binary operators and only handles integer `and` masks up to 64 bits.
