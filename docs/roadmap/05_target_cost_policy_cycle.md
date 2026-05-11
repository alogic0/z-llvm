# Cycle 5: Target-Cost Policy For Vector And FP Transforms

## Goal

Define a policy for target-cost-sensitive transforms so vector and floating-point
support does not accidentally claim LLVM TargetTransformInfo behavior.

## Source Anchors

- LLVM: TargetTransformInfo and target feature strings
- Corpus rows: FP rows, future vector rows, AArch64 target-layout row
- Local docs: target DataLayout, AArch64 optimizer policy, unsupported IR
- Local passes: InstCombine, vector placeholders, loop/vector boundaries

## Plan

- [x] Inventory current places where LLVM would use target cost or target
      library information.
- [x] Add docs that classify transforms as target-independent,
      DataLayout-sensitive, or TTI-sensitive.
- [x] Reject or skip TTI-sensitive vector and FP transforms.
- [x] Add tests proving accepted target-independent transforms still run with
      target records present.
- [x] Update pipeline docs for ReleaseFast and ReleaseSmall target-cost gaps.
- [x] Keep CPU scheduling and vectorization profitability out of scope.

## Exit Criteria

- [x] Target-cost-sensitive transforms have explicit local status.
- [x] No vector or FP optimization depends on unmodeled target cost.
- [x] Docs distinguish DataLayout from TargetTransformInfo.

## Completed Slice

- Added `docs/target/transform_cost_policy.md` with target-independent,
      DataLayout-sensitive, and TTI/TLI-sensitive transform classes.
- Documented current FP, vector, AArch64, DataLayout, and target-feature
      boundaries.
- Updated accepted ReleaseFast and ReleaseSmall pipeline notes to make
      target-cost-sensitive transforms explicitly out of scope.
- Kept vectorizer profitability, CPU scheduling, and target library rewrites as
      placeholders until TTI/TLI equivalents exist.
