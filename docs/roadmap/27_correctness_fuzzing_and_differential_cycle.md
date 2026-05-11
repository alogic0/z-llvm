# Cycle 27: Correctness Fuzzing And Differential Testing

## Goal

Add broader confidence around parser, verifier, and optimizer correctness with
small differential tests against LLVM and generated accepted-IR cases.

## Source Anchors

- Existing runners: `scripts/compare_opt.sh`, `scripts/run_zig_corpus.sh`
- Local normalizer: `src/normalize_cli.zig`
- LLVM tools: `opt-22`, `lli` or target-specific execution when available

## Plan

- [ ] Add generated scalar IR cases within the accepted parser surface.
- [ ] Differentially compare local pass output with `opt-22` for supported
      pipelines.
- [ ] Add negative generation for unsupported IR forms to verify fail-closed
      behavior.
- [ ] Add optional execution checks for pure scalar functions when a runner is
      available.
- [ ] Track flaky or non-deterministic LLVM differences in fixture metadata.
- [ ] Keep fuzzing artifacts out of tracked docs unless minimized.

## Exit Criteria

- [ ] Differential coverage goes beyond hand-written fixtures.
- [ ] Unsupported parser/verifier behavior is stress-tested.
- [ ] Generated failures produce minimized fixtures before becoming roadmap
      tasks.

