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

- [ ] Add scalar fold gaps from integer corpus to InstCombine docs.
- [ ] Expand known-bits or demanded-bits only for tested integer cases.
- [ ] Improve SCCP undef/poison-adjacent behavior where local IR can model it.
- [ ] Add BDCE-style bit-demanded cleanup as a separate conservative pass.
- [ ] Add CVP only after assumptions and branch facts are represented.
- [ ] Compare quality-sensitive fixtures with `opt-22`.

## Exit Criteria

- [ ] Scalar corpus output moves closer to LLVM without unsafe folds.
- [ ] Flag-sensitive arithmetic remains conservative.
- [ ] Quality improvements have direct fixtures.

