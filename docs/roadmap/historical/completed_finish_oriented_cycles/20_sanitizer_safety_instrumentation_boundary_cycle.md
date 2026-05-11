# Cycle 20: Sanitizer, Safety, And Instrumentation Boundary

## Goal

Classify sanitizer, coverage, and Zig safety instrumentation IR so the local
optimizer preserves correctness without implementing full sanitizer pipelines.

## Source Anchors

- ReleaseSafe and Debug captures
- LLVM IR: sanitizer calls, coverage guards, trap paths, profiling metadata
- Local passes: SimplifyCFG, ADCE, DCE, SCCP
- Docs: safety IR, unsupported IR, pass pipeline inventory

## Plan

- [x] Inventory instrumentation constructs present in current Zig captures.
- [x] Add reduced fixtures for sanitizer/coverage-like calls if present.
- [x] Treat instrumentation calls as side-effecting unless attributes prove
      otherwise.
- [x] Preserve profile and branch-weight metadata where accepted.
- [x] Keep sanitizer insertion/removal passes out of scope.
- [x] Compare preservation behavior with LLVM where equivalent.

## Exit Criteria

- [x] Instrumentation rows are classified honestly.
- [x] Safety and sanitizer calls are not optimized away unsafely.
- [x] Docs distinguish preserving instrumentation from generating it.

## Completed Slice

- Added a DCE fixture showing accepted ReleaseSafe-style opaque runtime calls
  stay live while unrelated scalar work is removed.
- Extended rejection coverage for sanitizer coverage, TSan, UBSan, and trap
  instrumentation calls.
- Documented the current boundary: preserve accepted safety IR and profile
  metadata, but do not generate, remove, or lower sanitizer/instrumentation
  callbacks.
