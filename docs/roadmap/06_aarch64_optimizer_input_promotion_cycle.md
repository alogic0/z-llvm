# Cycle 6: AArch64 Optimizer-Input Promotion

## Goal

Promote selected AArch64 source-backed rows to optimizer input only for
target-independent or proven DataLayout-aware passes.

## Source Anchors

- Manifest row: `integers_release_fast_aarch64`
- Docs: `docs/target/aarch64_optimizer_policy.md`
- Local passes: verifier, InstSimplify, InstCombine, DCE, SimplifyCFG
- LLVM comparison: target-independent `opt-22` fixtures

## Plan

- [x] Split AArch64 pipeline checks into target-independent and
      DataLayout-sensitive gates.
- [x] Add manifest metadata for the exact accepted AArch64 local pipeline.
- [x] Add opt fixtures for scalar integer transforms with AArch64 target records.
- [x] Reject or defer transforms that depend on ABI, cost model, or non-host
      codegen.
- [x] Run accepted AArch64 rows through the local corpus runner.
- [x] Document remaining AArch64 promotion blockers.

## Exit Criteria

- [x] At least one AArch64 row is honestly classified beyond parse/verify if
      gates prove it safe.
- [x] Target-sensitive transforms remain blocked.
- [x] Readiness checks cover the promoted AArch64 path.

## Completed Slice

- Added `aarch64-target-independent` as the accepted non-host AArch64 corpus
      alias.
- Promoted `integers_release_fast_aarch64` to optimizer input only for
      verifier, integer InstCombine, and DCE.
- Kept ABI, codegen, TTI/TLI, vector, and DataLayout-sensitive memory
      transforms blocked until separate source-backed gates exist.
