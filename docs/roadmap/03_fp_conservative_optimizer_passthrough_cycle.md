# Cycle 3: FP Conservative Optimizer Pass-Through

## Goal

Make existing scalar optimizer passes safely preserve supported FP instructions,
then promote accepted FP corpus rows to optimizer input only where the release
pipeline is proven not to change FP behavior incorrectly.

## Source Anchors

- Corpus rows: `floats_math_release_fast`, `float_compare_release_fast`
- Passes: DCE, ADCE, GVN, EarlyCSE, SCCP, InstSimplify, InstCombine
- LLVM comparison: `opt-22` preserve-only fixtures
- Local code: `src/passes/`, `src/analysis/expression_key.zig`

## Plan

- [x] Add preserve-only opt fixtures for supported FP instructions through each
      relevant scalar pass.
- [x] Confirm DCE/ADCE remove only dead, side-effect-free FP instructions with
      no live uses.
- [x] Keep GVN and EarlyCSE from value-numbering FP until NaN, signed-zero, and
      fast-math semantics are explicitly modeled.
- [x] Keep SCCP, InstSimplify, and InstCombine conservative for FP constants
      unless compared with `opt-22`.
- [x] Run accepted FP corpus rows through the local release pipeline.
- [x] Document every deliberate local-conservative FP difference from LLVM.

## Exit Criteria

- [x] Supported FP corpus rows can be marked `optimizer-input` only when the
      local pipeline preserves them correctly.
- [x] Each participating pass has at least one named FP preserve or reject
      fixture.
- [x] No FP fold is implemented without an `opt-22` comparison fixture.
