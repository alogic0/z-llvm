# Cycle 7: Release Pipeline Conformance

## Goal

Tie accepted corpus expansion back to Zig's actual LLVM pass pipeline by
running mode-specific local pipelines over accepted fixtures and documenting
which LLVM passes remain no-op placeholders, conservative gaps, or real parity
targets.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig`,
  `../ziglang/src/zig_llvm.cpp`
- Local docs: `docs/inventory/zig_llvm_pass_pipeline_inventory.md`,
  `docs/fixtures/zig_ir/README.md`,
  `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`
- Local runner: `scripts/run_zig_corpus.sh`

## Plan

- [x] Refresh the pass inventory against current `../ziglang` before changing
      pipeline expectations.
- [x] Define local pipeline aliases for Debug, ReleaseSafe, ReleaseFast, and
      ReleaseSmall accepted subsets.
- [x] Make `scripts/run_zig_corpus.sh` select pipeline aliases from manifest
      metadata rather than one global `PASSES` value.
- [x] Add a summary report of accepted, unsupported, future, and debug-only
      corpus rows.
- [x] For every placeholder pass in a selected pipeline, require a doc entry
      saying why a no-op is currently behavior-preserving for the fixture.
- [x] Promote corpus rows from unsupported only after parser, verifier,
      analyses, and selected pipeline passes all agree.
- [x] Keep codegen/object output out of scope unless validating optimizer
      handoff facts.

## Exit Criteria

- [x] The corpus runner can execute per-row pipeline aliases.
- [x] Every accepted corpus row records the local pipeline used.
- [x] Remaining LLVM pass gaps are classified as parser blocker, analysis
      blocker, pass blocker, optional track, or deliberate conservative gap.

## Completion Notes

- Added `zig-debug-accepted`, `zig-release-safe-accepted`,
  `zig-release-fast-accepted`, and `zig-release-small-accepted` local pipeline
  aliases.
- `scripts/run_zig_corpus.sh` now requires `local-pipeline=<alias>` metadata
  for each accepted optimizer-input row unless `PASSES=...` is supplied for an
  experiment.
- The selected accepted-subset aliases intentionally contain no placeholder
  passes. Placeholder-heavy full descriptors such as `release-o3`, `release-oz`,
  and `debug-o0` remain documented inventory surfaces, while accepted corpus
  rows use only passes that current fixtures can validate.
