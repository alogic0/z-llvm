# Cycle 5: Corpus Capture Automation

## Goal

Make source-backed Zig-emitted IR expansion repeatable so future corpus rows do
not rely on manual command transcription.

## Source Anchors

- Manifest: `docs/fixtures/zig_ir/manifest.tsv`
- Policy: `docs/environment.md`, `docs/development_cycle.md`
- Scripts: `scripts/run_zig_corpus.sh`, `scripts/run_readiness_checks.sh`
- Zig emitter: `../ziglang/build/stage4/bin/zig`

## Plan

- [x] Add a checked script that verifies the stage4 Zig version matches
      `../ziglang` HEAD before capturing fixtures.
- [x] Add a capture helper for one manifest row or source group that writes to
      `test/zig/captured/`.
- [x] Keep raw Debug and ReleaseSafe broad captures under `tmp/` unless reduced.
- [x] Add a manifest lint that checks field counts, checked paths, and
      `local-pipeline` metadata for accepted rows.
- [x] Wire lightweight manifest linting into readiness checks.

## Exit Criteria

- [x] Corpus capture commands are reproducible from scripts.
- [x] Manifest mistakes fail fast.
- [x] Readiness checks still pass without requiring fixture regeneration.

## Completion Notes

- Added `scripts/check_zig_stage4_emitter.sh`,
  `scripts/capture_zig_ir.sh`, and `scripts/lint_zig_ir_manifest.sh`.
- Readiness checks now run manifest linting, but capture remains explicit.
- The capture helper writes broad Debug and ReleaseSafe output under
  `tmp/zig_ir/raw/` by default.
