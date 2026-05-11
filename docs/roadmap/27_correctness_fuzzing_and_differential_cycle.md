# Cycle 27: Correctness Fuzzing And Differential Testing

## Goal

Add broader confidence around parser, verifier, and optimizer correctness with
small differential tests against LLVM and generated accepted-IR cases.

## Source Anchors

- Existing runners: `scripts/compare_opt.sh`, `scripts/run_zig_corpus.sh`
- Local normalizer: `src/normalize_cli.zig`
- LLVM tools: `opt-22`, `lli` or target-specific execution when available

## Plan

- [x] Add generated scalar IR cases within the accepted parser surface.
- [x] Differentially compare local pass output with `opt-22` for supported
      pipelines.
- [x] Add negative generation for unsupported IR forms to verify fail-closed
      behavior.
- [x] Add optional execution checks for pure scalar functions when a runner is
      available.
- [x] Track flaky or non-deterministic LLVM differences in fixture metadata.
- [x] Keep fuzzing artifacts out of tracked docs unless minimized.

## Exit Criteria

- [x] Differential coverage goes beyond hand-written fixtures.
- [x] Unsupported parser/verifier behavior is stress-tested.
- [x] Generated failures produce minimized fixtures before becoming roadmap
      tasks.

## Completion Notes

- Added `scripts/run_generated_scalar_diff.sh` for temp-dir generated scalar
  differential cases against `opt-22`.
- Added generated negative checks for unsupported vector and atomic RMW forms.
- Added optional `lli-22` execution smoke for a pure scalar `main` when the
  runner is installed.
- Generated artifacts remain temporary; minimized regressions should be promoted
  to named fixtures before being tracked.
