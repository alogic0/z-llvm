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

- [x] Refresh the Zig LLVM pass inventory from `../ziglang` before starting the
      cycle.
- [x] Regenerate or validate Zig-emitted IR fixtures with the configured
      stage4 compiler from `../ziglang`.
- [x] Classify every corpus fixture by parser support, verifier support,
      optimizer-input readiness, debug-info-only status, unsupported IR, or
      future backend relevance.
- [x] Add a corpus runner that can execute selected local pass pipelines over
      accepted Zig-originated IR.
- [x] Map each failing corpus case to one of:
      parser gap, verifier gap, analysis gap, pass correctness gap, deliberate
      conservative difference, or out-of-scope LLVM feature.
- [x] Promote the smallest useful corpus gaps into focused implementation
      slices.
- [x] Keep object/codegen work out of scope unless it directly validates the
      optimizer-to-Zig-native-backend handoff.
- [x] Update pass docs with corpus coverage, not only synthetic fixture
      coverage.

## Exit Criteria

- [x] The project can say which Zig-emitted IR families are accepted by the
      local optimizer today.
- [x] Each remaining blocker is classified with an owning future cycle.
- [x] The roadmap stays aligned with Zig's native-backend LLVM-removal path.
- [x] `zig build test` and the relevant corpus/`opt-22` comparison runners pass.

## Completed Corpus Runner Slice

- [x] Added `scripts/run_zig_corpus.sh` to run checked `optimizer-input`
      manifest rows through a local pass pipeline and normalize the result.
- [x] Validated the current accepted corpus row:
      `tiny_scalar_release_fast` with `verify,instcombine,dce`.
- [x] Kept unsupported corpus families classified in
      `docs/fixtures/zig_ir/manifest.tsv`; current blockers remain parser and
      IR-surface gaps for aliases, raw attrs, intrinsics, metadata, atomics,
      arrays, and broader loop/call forms.
- [x] Documented corpus runner usage in `docs/fixtures/zig_ir/README.md`.
- [x] Verified with `scripts/run_zig_corpus.sh`.

## Current Corpus Status

Accepted optimizer-input rows:

```text
tiny_scalar_release_fast
```

Unsupported or future rows are already classified in the manifest and map to
future parser/verifier/analysis slices rather than object or codegen work.
