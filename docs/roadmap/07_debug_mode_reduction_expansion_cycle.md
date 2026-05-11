# Cycle 7: Debug-Mode Source-Backed Reduction Expansion

## Goal

Turn more broad Debug-mode Zig output into reduced source-backed fixtures that
exercise debug metadata without pulling in all std/debug support.

## Source Anchors

- Manifest rows: `tiny_scalar_debug`, `debug_metadata_reduced`,
      `debug_scope_branch_reduced`
- Zig emitter: `../ziglang/build/stage4/bin/zig`
- LLVM metadata: `DICompileUnit`, `DISubprogram`, `DILexicalBlock`,
      `DILocation`
- Local docs: debug metadata and unsupported IR docs

## Plan

- [x] Capture current Debug output for selected tiny source groups.
- [x] Reduce two new Debug shapes to manageable checked fixtures.
- [x] Preserve metadata attachments through parse, verify, print, and no-op
      pipelines.
- [x] Add fail-closed tests for unsupported debug intrinsics or metadata forms.
- [x] Keep variable location salvage and DWARF quality out of scope.
- [x] Update manifest rows with exact provenance and reduced-fixture notes.

## Exit Criteria

- [x] At least two new Debug reduced fixtures are tracked.
- [x] Accepted metadata survives the verifier-only Debug pipeline.
- [x] Broad raw Debug rows remain classified honestly as future where needed.

## Completed Slice

- Captured current Debug output for `control_flow_calls` and
      `pointers_memory` under `tmp/zig_ir/raw/` to confirm broad Debug output
      still pulls in large std/debug support.
- Added `debug_call_chain.reduced.ll` and `debug_loop_sum.reduced.ll` as
      manageable source-backed reductions from `control_flow_calls`.
- Added verifier-only opt fixtures and manifest rows for the two reduced Debug
      shapes.
- Kept debug value/declare intrinsics, variable-location salvage, and DWARF
      quality out of scope with fail-closed tests and docs.
