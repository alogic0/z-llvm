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

- [ ] Inventory sanitizer, profiling, coverage, and safety-check constructs in
      current Zig-emitted IR.
- [ ] Separate safety IR parser blockers from debug-info and sanitizer blockers.
- [ ] Parse and preserve harmless instrumentation metadata where possible.
- [ ] Reject sanitizer intrinsics and instrumentation calls when semantics are
      not modeled.
- [ ] Add ReleaseSafe reduced fixtures for safety checks that should survive
      local optimization.
- [ ] Document which LLVM instrumentation passes remain optional tracks.
- [ ] Keep sanitizer behavior out of core optimizer parity unless Zig's selected
      mode requires it.

## Exit Criteria

- [ ] ReleaseSafe corpus blockers are classified separately from ReleaseFast.
- [ ] Instrumentation metadata is either preserved or rejected with exact docs.
- [ ] Sanitizer/instrumentation no-op placeholders are not used for correctness
      claims.

