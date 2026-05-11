# Cycle 21: Bitcode, LTO, And ThinLTO Boundary

## Goal

Define the minimum bitcode/LTO compatibility boundary needed by Zig's LLVM
dependency story without building a full bitcode writer or LTO pipeline.

## Source Anchors

- Docs: bitcode construct inventory, pass pipeline inventory
- LLVM APIs: bitcode writer/reader, LTO, ThinLTO summaries
- Zig build modes and link paths
- Local text IR corpus and pipeline validation

## Plan

- [x] Inventory which Zig use cases require LLVM bitcode or LTO handoff.
- [x] Map accepted text IR constructs to missing bitcode constructs.
- [x] Add explicit unsupported docs for ThinLTO summaries and module indexes.
- [x] Keep local optimizer validation text-IR based unless a source-backed need
      requires bitcode.
- [x] Add reduced fixtures only for bitcode-related metadata that appears in text
      IR captures.
- [x] Update roadmap status for bitcode, LTO, and ThinLTO.

## Exit Criteria

- [x] Bitcode/LTO requirements are classified as needed, deferred, or out of
      scope.
- [x] No docs imply the project has full bitcode/LTO support.
- [x] Future work is tied to a concrete Zig use case.

## Completed Slice

- Added a requirement-classification table for text IR comparison, explicit
  bitcode output, LTO handoff, ThinLTO summaries, bitcode input parsing, and
  native backend validation.
- Made ThinLTO module summaries, combined indexes, import/export, WPD, CFI,
  and post-link LTO explicit unsupported behavior.
- Kept local optimizer and LTO pre-link validation text-IR based; no new
  bitcode fixture was added because the current text captures do not require a
  bitcode-only construct.
