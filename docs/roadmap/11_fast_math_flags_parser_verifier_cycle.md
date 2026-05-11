# Cycle 11: Fast-Math Flags Parser And Verifier

## Goal

Recognize LLVM fast-math flag syntax enough to preserve or reject it safely,
without applying fast-math transforms.

## Source Anchors

- Future Zig FP captures with fast-math-like attributes or flags
- LLVM IR: `fast`, `nnan`, `ninf`, `nsz`, `arcp`, `contract`, `afn`, `reassoc`
- Local FP parser/verifier
- Docs: FP semantics and unsupported IR

## Plan

- [x] Add source-backed or reduced fast-math flag fixtures.
- [x] Parse flag spelling into an explicit FP flag record where accepted.
- [x] Verify flags are attached only to supported FP operations.
- [x] Preserve flags through print and pass-through pipelines.
- [x] Disable all fast-math-dependent folds until a later comparison cycle.
- [x] Reject unsupported flag combinations or unsupported instructions.

## Exit Criteria

- [x] Fast-math syntax is not silently ignored.
- [x] Accepted flags are preserved but not optimized through.
- [x] Docs clearly separate flag parsing from fast-math optimization.

## Completed Slice

- Added an explicit `FastMathFlags` IR record for scalar FP binary ops and
  `fcmp`.
- Accepted `fast`, `nnan`, `ninf`, `nsz`, `arcp`, `contract`, `afn`, and
  `reassoc` syntax only on supported scalar FP operations.
- Added an `opt-22` comparison fixture proving flags round-trip through
  InstCombine and DCE without enabling FP folds.
