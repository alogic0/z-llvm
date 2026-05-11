# Cycle 12: Corpus Refresh And Readiness Audit

## Goal

Refresh the Zig-emitted corpus and readiness picture after the new active cycle
series, then decide the next roadmap wave from observed blockers rather than
from speculation.

## Source Anchors

- Zig source checkout: `../ziglang`
- Emitter check: `scripts/check_zig_stage4_emitter.sh`
- Corpus scripts: `scripts/capture_zig_ir.sh`, `scripts/run_zig_corpus.sh`
- Readiness docs: `docs/upstream_integration_readiness.md`,
      `docs/fixtures/zig_ir/manifest.tsv`

## Plan

- [x] Confirm the authoritative stage4 emitter still matches `../ziglang` HEAD.
- [x] Refresh selected ReleaseFast, ReleaseSmall, ReleaseSafe, and Debug rows
      only where the current roadmap needs updated evidence.
- [x] Run manifest linting and corpus checks after every classification change.
- [x] Produce a short blocker inventory grouped by parser, verifier, optimizer,
      target, debug, atomics, and backend handoff.
- [x] Archive completed active cycles and create the next wave from the highest
      value remaining source-backed blockers.
- [x] Update `docs/README.md` and historical roadmap indexes after archiving.

## Exit Criteria

- [x] The manifest records current emitter versions and honest row
      classifications.
- [x] Readiness checks pass.
- [x] The next roadmap wave is chosen from concrete refreshed corpus evidence.

## Completed Slice

- `scripts/check_zig_stage4_emitter.sh` confirmed
      `../ziglang/build/stage4/bin/zig` reports
      `0.17.0-dev.304+9787df942`, matching `../ziglang` HEAD `9787df942`.
- Fresh `ReleaseFast` and `ReleaseSmall` captures for `tiny_scalar` matched the
      tracked stripped captures byte-for-byte.
- A fresh `ReleaseSmall` capture for `floats_math` matched the tracked stripped
      capture byte-for-byte.
- A fresh `ReleaseSafe` raw capture for `tiny_scalar` still expands to broad
      safety and std support, so the reduced current-row safety fixtures remain
      the honest checked evidence.
- The blocker inventory and next wave live in
      `docs/roadmap/source_backed_readiness_audit.md` and
      `docs/roadmap/future_optimizer_backlog.md`.
