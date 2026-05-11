# Cycle 12: Sanitizer, Instrumentation, And Safety IR

## Goal

Classify and preserve Zig safety-mode and instrumentation-related IR so
ReleaseSafe, sanitizer, profiling, and coverage paths do not get mixed into
ordinary scalar optimization work.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig`
- LLVM passes: sanitizer instrumentation, profile instrumentation, coverage,
  stack protector, annotation/instrumentation metadata
- Local docs: `docs/passes/instrumentation_metadata.md`,
  `docs/passes/global_cleanup_placeholders.md`,
  `docs/debug/metadata_inventory.md`
- Corpus rows: `tiny_scalar_release_safe`,
  `atomics_inline_asm_debug_release_fast`

## Plan

- [x] Inventory sanitizer, profiling, coverage, and safety-check constructs in
      current Zig-emitted IR.
- [x] Separate safety IR parser blockers from debug-info and sanitizer blockers.
- [x] Parse and preserve harmless instrumentation metadata where possible.
- [x] Reject sanitizer intrinsics and instrumentation calls when semantics are
      not modeled.
- [x] Add ReleaseSafe reduced fixtures for safety checks that should survive
      local optimization.
- [x] Document which LLVM instrumentation passes remain optional tracks.
- [x] Keep sanitizer behavior out of core optimizer parity unless Zig's selected
      mode requires it.

## Exit Criteria

- [x] ReleaseSafe corpus blockers are classified separately from ReleaseFast.
- [x] Instrumentation metadata is either preserved or rejected with exact docs.
- [x] Sanitizer/instrumentation no-op placeholders are not used for correctness
      claims.

## Completion Notes

- Added `test/zig/expected/release_safe_safety.reduced.ll` as an accepted
  ReleaseSafe safety-control fixture with a dynamic trap branch and opaque
  branch-weight metadata.
- The parser now rejects sanitizer, TSan, UBSan, and trap instrumentation calls
  explicitly instead of treating them as ordinary direct calls.
- `docs/passes/instrumentation_metadata.md` documents the conservative boundary:
  metadata preservation is local-only, while sanitizer callback insertion and
  runtime ABI behavior remain optional-track placeholders.
