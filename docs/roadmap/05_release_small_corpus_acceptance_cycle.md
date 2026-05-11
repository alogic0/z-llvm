# Cycle 5: ReleaseSmall Corpus Acceptance

## Goal

Expand the source-backed corpus from ReleaseFast into ReleaseSmall, focusing on
real size-optimization IR differences that the local parser and optimizer must
understand.

## Source Anchors

- Manifest rows: existing `ReleaseSmall` entries and future captures
- Zig emitter: `../ziglang/build/stage4/bin/zig`
- Local scripts: `scripts/capture_zig_ir.sh`, `scripts/run_zig_corpus.sh`
- LLVM pipeline inventory: ReleaseSmall and size-oriented pass behavior

## Plan

- [x] Select a small set of current source groups for ReleaseSmall recapture
      using the current authoritative stage4 compiler.
- [x] Add manifest rows as `unsupported,future` first unless parse, verify, and
      pipeline acceptance are proven.
- [x] Classify size-specific linkage, attributes, aliases, and section-like
      constructs separately from optimizer behavior.
- [x] Add reduced fixtures for the first ReleaseSmall-only blockers.
      No new ReleaseSmall-only parser blocker appeared in the selected rows;
      the existing raw `tiny_scalar_release_small` row remains the concrete
      unsupported/future blocker.
- [x] Compare local accepted size-pipeline behavior with `opt-22` where the
      local pipeline is intended to match.
- [x] Document deliberate gaps where LLVM's size pipeline is broader than the
      local subset.

## Exit Criteria

- [x] At least three source-backed ReleaseSmall rows are classified with source,
      emitter revision, command, and checked output where accepted.
- [x] ReleaseSmall blockers are captured as concrete future cycle candidates.
- [x] Readiness checks pass without requiring fixture regeneration.
