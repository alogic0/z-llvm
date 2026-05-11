# Cycle 2: Intrinsics And Call Semantics

## Goal

Model the Zig-emitted LLVM intrinsics and direct-call attributes that block
integer, pointer, and control-flow corpus rows, while keeping unknown calls and
unsupported intrinsics conservative.

## Source Anchors

- LLVM: `llvm/include/llvm/IR/Intrinsics.td`
- LLVM: `llvm/lib/Analysis/TargetLibraryInfo.cpp`
- Local code: `src/analysis/function_attrs.zig`,
  `src/analysis/target_library_info.zig`, `src/passes/instcombine.zig`,
  `src/passes/sccp.zig`
- Corpus rows: `integers_release_fast`, `control_flow_calls_release_fast`

## Plan

- [x] Inventory Zig-emitted `llvm.*` calls in captured corpus files.
- [x] Add direct parsing/classification for `llvm.smin.*` and neighboring
      integer min/max intrinsics needed by integer fixtures.
- [x] Add conservative parsing for `llvm.assume` as a side-effect boundary or
      documented no-op only where legal.
- [x] Classify readnone, readonly, argmemonly, nounwind, willreturn, and
      similar attrs through one call-effect API.
- [x] Add InstCombine/SCCP folds only for intrinsic cases with source-backed
      tests and `opt-22` comparisons.
- [x] Preserve unsupported intrinsics as calls when possible; reject only when
      syntax cannot be represented.
- [x] Promote the integer corpus row from unsupported to accepted when parser
      and intrinsic semantics are sufficient.

## Exit Criteria

- [x] Integer captured IR has an accepted reduced or raw corpus path.
- [x] Intrinsic side effects are documented and tested.
- [x] Unknown intrinsics remain conservative.
- [x] `zig build test`, `bash scripts/compare_opt.sh`, and
      `bash scripts/run_zig_corpus.sh` pass.

## Completed Slice 1: Integer Min/Max Intrinsics

- Preserved `tail call` for direct calls while keeping `musttail` and `notail`
  rejected.
- Resolved attribute group references for call memory-effect classification.
- Added conservative no-memory/read-only classification for `memory(none)`,
  `memory(read)`, `readnone`, and `readonly`.
- Added `llvm.smin.*`, `llvm.smax.*`, `llvm.umin.*`, and `llvm.umax.*`
  same-operand and constant folds through `inst_simplify`, shared by
  InstCombine and SCCP.
- Promoted `integers_release_fast` to `parse,verify,optimizer-input`.
- Documented the slice in
  `docs/semantics/intrinsics_and_call_semantics.md`.

## Completed Slice 2: Assume And Control-Flow Call Surface

- Parsed Zig-emitted `llvm.assume` as a conservative side-effecting void call.
- Preserved return attributes such as `range(i32 ...)` before function return
  types.
- Preserved `or disjoint` as a binary flag and kept flagged folds
  conservative.
- Accepted loop-branch metadata syntax as parser input while deferring metadata
  preservation to the loop metadata cycle.
- Derived implicit entry-block names from numeric LLVM parameter names so raw
  PHI incoming blocks such as `%1` verify.
- Promoted `control_flow_calls_release_fast` to
  `parse,verify,optimizer-input`.
