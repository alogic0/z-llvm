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

- [ ] Inventory Zig-emitted `llvm.*` calls in captured corpus files.
- [ ] Add direct parsing/classification for `llvm.smin.*` and neighboring
      integer min/max intrinsics needed by integer fixtures.
- [ ] Add conservative parsing for `llvm.assume` as a side-effect boundary or
      documented no-op only where legal.
- [ ] Classify readnone, readonly, argmemonly, nounwind, willreturn, and
      similar attrs through one call-effect API.
- [ ] Add InstCombine/SCCP folds only for intrinsic cases with source-backed
      tests and `opt-22` comparisons.
- [ ] Preserve unsupported intrinsics as calls when possible; reject only when
      syntax cannot be represented.
- [ ] Promote the integer corpus row from unsupported to accepted when parser
      and intrinsic semantics are sufficient.

## Exit Criteria

- [ ] Integer captured IR has an accepted reduced or raw corpus path.
- [ ] Intrinsic side effects are documented and tested.
- [ ] Unknown intrinsics remain conservative.
- [ ] `zig build test`, `bash scripts/compare_opt.sh`, and
      `bash scripts/run_zig_corpus.sh` pass.

