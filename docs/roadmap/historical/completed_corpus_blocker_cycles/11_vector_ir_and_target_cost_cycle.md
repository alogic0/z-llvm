# Cycle 11: Vector IR And Target Cost Boundary

## Goal

Prepare for Zig-emitted vector IR and LLVM vectorization gaps without
hand-rolling broad vector optimizations too early. The local system should parse
or reject vector constructs deliberately and model target-cost placeholders
honestly.

## Source Anchors

- LLVM: `LoopVectorize`, `SLPVectorizer`, `VectorCombine`,
  `TargetTransformInfo`
- Local docs: `docs/roadmap/historical/vector_ir_and_target_cost_epic.md`,
  `docs/passes/deferred_vector_coroutine_openmp.md`,
  `docs/target/datalayout.md`
- Local IR: `src/ir/parser.zig`, `src/ir/verifier.zig`

## Plan

- [x] Inventory vector-like constructs in Zig-emitted corpus and upstream pass
      inventory.
- [x] Add parser rejection tests for vector types, shufflevector, insertelement,
      extractelement, and vector constants until accepted.
- [x] Add a minimal vector type representation only when a source-backed fixture
      requires parsing.
- [x] Document target-cost model requirements before enabling vector transforms.
- [x] Keep LoopVectorize and SLP as no-op placeholders for scalar-only accepted
      pipelines.
- [x] Add future fixtures showing why vectorization quality matters for Zig
      ReleaseFast once native backend handoff reaches vector IR.

## Exit Criteria

- [x] Vector unsupported behavior is deliberate and tested.
- [x] Target-cost model gaps are visible in the pass inventory.
- [x] Accepted scalar pipelines cannot accidentally run vector placeholders as
      if they were implemented.

## Completion Notes

- Added parser rejection tests for vector type use, `shufflevector`,
  `insertelement`, `extractelement`, and vector constants.
- Added `test/zig/expected/vector_future.unsupported.ll` and classified it in
  the corpus manifest as `unsupported,future`.
- Added `docs/target/target_cost_model.md` to define the TargetTransformInfo
  boundary before vector transforms can become real.
- Accepted `zig-*-accepted` corpus pipelines are tested to exclude
  `loop-vectorize`, `slp-vectorizer`, and `vector-combine`; those remain
  executable placeholders only in full inventory descriptors.
