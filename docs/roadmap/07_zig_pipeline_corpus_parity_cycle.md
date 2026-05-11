# Cycle 7: Zig Pipeline Corpus Parity

## Goal

Tie individual pass work back to Zig's real LLVM-removal path by running the
local optimizer against a growing Zig-emitted IR corpus and by tracking which
LLVM pass-pipeline requirements remain blockers.

## Source Anchors

- Zig source: `../ziglang/src/codegen/llvm.zig` and related LLVM backend files
- Local docs: `docs/inventory/zig_llvm_api_inventory.md`,
  `docs/roadmap/zig_aligned_llvm_removal_plan.md`,
  `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`,
  `docs/environment.md`
- Local fixtures: `fixtures/zig_ir/manifest.tsv`
- Local runner: `scripts/compare_opt.sh`

## Plan

- [ ] Refresh the Zig LLVM pass inventory from `../ziglang` before starting the
      cycle.
- [ ] Regenerate or validate Zig-emitted IR fixtures with the configured
      stage4 compiler from `../ziglang`.
- [ ] Classify every corpus fixture by parser support, verifier support,
      optimizer-input readiness, debug-info-only status, unsupported IR, or
      future backend relevance.
- [ ] Add a corpus runner that can execute selected local pass pipelines over
      accepted Zig-originated IR.
- [ ] Map each failing corpus case to one of:
      parser gap, verifier gap, analysis gap, pass correctness gap, deliberate
      conservative difference, or out-of-scope LLVM feature.
- [ ] Promote the smallest useful corpus gaps into focused implementation
      slices.
- [ ] Keep object/codegen work out of scope unless it directly validates the
      optimizer-to-Zig-native-backend handoff.
- [ ] Update pass docs with corpus coverage, not only synthetic fixture
      coverage.

## Exit Criteria

- [ ] The project can say which Zig-emitted IR families are accepted by the
      local optimizer today.
- [ ] Each remaining blocker is classified with an owning future cycle.
- [ ] The roadmap stays aligned with Zig's native-backend LLVM-removal path.
- [ ] `zig build test` and the relevant corpus/`opt-22` comparison runners pass.

