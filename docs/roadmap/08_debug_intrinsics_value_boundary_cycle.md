# Cycle 8: Debug Intrinsics And Debug-Value Boundary

## Goal

Define and implement the first safe boundary for LLVM debug intrinsics such as
debug value declarations, without implementing full debug value salvage.

## Source Anchors

- Future reduced Debug captures
- LLVM IR: `llvm.dbg.declare`, `llvm.dbg.value`, `DIExpression`
- Local docs: debug metadata, unsupported IR, pass docs
- Local passes: DCE, ADCE, InstCombine, SimplifyCFG

## Plan

- [x] Add reduced fixtures containing debug intrinsics from Zig Debug output.
- [x] Decide whether each intrinsic is represented, preserved opaquely, or
      rejected.
- [x] Ensure optimizers do not treat debug intrinsics as semantic program
      effects.
- [x] Preserve metadata references when instructions are not transformed.
- [x] Document missing salvage behavior after instruction deletion or rewriting.
- [x] Compare preservation-only behavior with LLVM where practical.

## Exit Criteria

- [x] Debug intrinsic policy is implemented and tested.
- [x] Unsupported debug value forms fail closed or are dropped only by explicit
      documented policy.
- [x] No pass claims debug quality parity.

## Completed Slice

- Added explicit `UnsupportedDebugIntrinsic` rejection for `llvm.dbg.*`
      declarations and calls.
- Added unsupported reduced fixtures for `llvm.dbg.value` and
      `llvm.dbg.declare` with `DILocalVariable` and `DIExpression` references.
- Kept accepted Debug rows preservation-only: opaque `!dbg` metadata survives
      verifier-only pipelines, but debug-value salvage is not represented.
- Compared preservation-only Debug metadata fixtures with `opt-22` through the
      existing parse-preserve fixture path.
