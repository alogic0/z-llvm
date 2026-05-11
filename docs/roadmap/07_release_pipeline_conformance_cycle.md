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

- [ ] Refresh the pass inventory against current `../ziglang` before changing
      pipeline expectations.
- [ ] Define local pipeline aliases for Debug, ReleaseSafe, ReleaseFast, and
      ReleaseSmall accepted subsets.
- [ ] Make `scripts/run_zig_corpus.sh` select pipeline aliases from manifest
      metadata rather than one global `PASSES` value.
- [ ] Add a summary report of accepted, unsupported, future, and debug-only
      corpus rows.
- [ ] For every placeholder pass in a selected pipeline, require a doc entry
      saying why a no-op is currently behavior-preserving for the fixture.
- [ ] Promote corpus rows from unsupported only after parser, verifier,
      analyses, and selected pipeline passes all agree.
- [ ] Keep codegen/object output out of scope unless validating optimizer
      handoff facts.

## Exit Criteria

- [ ] The corpus runner can execute per-row pipeline aliases.
- [ ] Every accepted corpus row records the local pipeline used.
- [ ] Remaining LLVM pass gaps are classified as parser blocker, analysis
      blocker, pass blocker, optional track, or deliberate conservative gap.

