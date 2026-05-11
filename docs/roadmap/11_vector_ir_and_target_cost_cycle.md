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

- [ ] Inventory vector-like constructs in Zig-emitted corpus and upstream pass
      inventory.
- [ ] Add parser rejection tests for vector types, shufflevector, insertelement,
      extractelement, and vector constants until accepted.
- [ ] Add a minimal vector type representation only when a source-backed fixture
      requires parsing.
- [ ] Document target-cost model requirements before enabling vector transforms.
- [ ] Keep LoopVectorize and SLP as no-op placeholders for scalar-only accepted
      pipelines.
- [ ] Add future fixtures showing why vectorization quality matters for Zig
      ReleaseFast once native backend handoff reaches vector IR.

## Exit Criteria

- [ ] Vector unsupported behavior is deliberate and tested.
- [ ] Target-cost model gaps are visible in the pass inventory.
- [ ] Accepted scalar pipelines cannot accidentally run vector placeholders as
      if they were implemented.

