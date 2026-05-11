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

- [ ] Refresh which Zig modes request bitcode, LTO, ThinLTO, or object-only
      behavior.
- [ ] Classify bitcode support as parser/input, writer/output, or no local need
      for each accepted fixture.
- [ ] Add construct inventory rows for every accepted IR feature in the current
      corpus.
- [ ] Keep ThinLTO summary emission deferred unless a concrete Zig path needs
      local reproduction.
- [ ] Add LTO prelink pipeline docs for optimizer behavior that differs from
      normal ReleaseFast.
- [ ] Define activation criteria for building a real bitcode writer.

## Exit Criteria

- [ ] Bitcode/LTO requirements are source-backed and mode-specific.
- [ ] Optional LTO work does not blur with core optimizer correctness.
- [ ] A future bitcode writer has a construct inventory tied to accepted IR.

