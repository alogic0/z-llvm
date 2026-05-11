# Cycle 24: Full Corpus Refresh And Differential Audit

## Goal

Refresh the corpus and produce a finish-oriented differential audit that decides
which remaining gaps matter for Zig's LLVM-removal path.

## Source Anchors

- Zig source checkout: `../ziglang`
- Scripts: `check_zig_stage4_emitter.sh`, `capture_zig_ir.sh`,
      `run_zig_corpus.sh`, `run_readiness_checks.sh`
- Manifest: `docs/fixtures/zig_ir/manifest.tsv`
- Audit docs: source-backed readiness and upstream integration readiness

## Plan

- [x] Rebuild or verify the authoritative stage4 Zig emitter.
- [x] Refresh selected Debug, ReleaseSafe, ReleaseFast, ReleaseSmall, and
      non-host target rows.
- [x] Compare refreshed captures with checked fixtures and record byte-identical
      or changed rows.
- [x] Run local optimizer, corpus, handoff, and generated scalar differential
      gates.
- [x] Produce a remaining-gap table grouped by correctness, optimizer quality,
      target/backend, debug, atomics, vector, and LTO.
- [x] Archive completed active cycles and create the next wave from the highest
      value remaining gaps.

## Exit Criteria

- [x] Manifest provenance is current and honest.
- [x] Readiness checks pass or failures are documented as blockers.
- [x] The project has a concrete next-finish decision based on refreshed data.

## Completed Slice

- Verified the authoritative stage4 emitter:
  `0.17.0-dev.304+9787df942` matches `../ziglang` HEAD `9787df942`.
- Refreshed representative Debug, ReleaseSafe, ReleaseFast, ReleaseSmall, and
  AArch64 rows under `tmp/zig_ir/cycle24/`.
- Confirmed the checked `tiny_scalar` ReleaseFast/ReleaseSmall and `integers`
  AArch64 captures are byte-identical to the refreshed output.
- Ran the full readiness gate and recorded the remaining-gap table in
  `docs/roadmap/cycle24_corpus_refresh_differential_audit.md`.
