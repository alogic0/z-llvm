# Cycle 13: Bitcode, LTO, And ThinLTO Boundary

## Goal

Define and implement the minimum local boundary for LLVM bitcode and LTO-related
behavior that Zig still relies on, without blocking the core native-backend
optimizer path on optional output formats.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig`
- LLVM: bitcode writer/reader, `PassBuilder` LTO pipelines, ThinLTO summaries
- Local docs: `docs/bitcode/construct_inventory.md`,
  `docs/passes/lto_prelink.md`,
  `docs/roadmap/historical/completed_epics/09_optional_bitcode_debug_lto_tracks.md`

## Plan

- [x] Refresh which Zig modes request bitcode, LTO, ThinLTO, or object-only
      behavior.
- [x] Classify bitcode support as parser/input, writer/output, or no local need
      for each accepted fixture.
- [x] Add construct inventory rows for every accepted IR feature in the current
      corpus.
- [x] Keep ThinLTO summary emission deferred unless a concrete Zig path needs
      local reproduction.
- [x] Add LTO prelink pipeline docs for optimizer behavior that differs from
      normal ReleaseFast.
- [x] Define activation criteria for building a real bitcode writer.

## Exit Criteria

- [x] Bitcode/LTO requirements are source-backed and mode-specific.
- [x] Optional LTO work does not blur with core optimizer correctness.
- [x] A future bitcode writer has a construct inventory tied to accepted IR.

## Completion Notes

- `docs/bitcode/construct_inventory.md` now maps Zig mode paths to
  parser/input, writer/output, or no-local-need categories and lists construct
  coverage for accepted corpus rows.
- `docs/lto/behavior_gaps.md` records the exact boundary: Zig's non-debug LTO
  modes use LLVM's pre-link builder locally modeled by `lto-prelink-o3` and
  `lto-prelink-oz`, while bitcode output and ThinLTO summaries remain deferred.
- Pipeline descriptor tests keep the local aliases pinned as pre-link optimizer
  surfaces rather than bitcode writer or ThinLTO-summary implementations.
