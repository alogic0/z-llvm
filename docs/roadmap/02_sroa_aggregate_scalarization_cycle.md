# Cycle 2: SROA Aggregate Scalarization

## Goal

Move SROA beyond zero-offset GEP forwarding toward real alloca slicing and
scalar replacement for simple aggregate-shaped stack objects emitted by Zig.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/SROA.cpp`
- LLVM utility: `llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp`
- Local docs: `docs/passes/sroa.md`, `docs/passes/mem2reg.md`,
  `docs/analysis/memory_location.md`
- Local code: `src/passes/sroa.zig`, `src/passes/mem2reg.zig`,
  `src/analysis/memory_location.zig`
- Corpus: `fixtures/zig_ir/manifest.tsv`

## Plan

- [ ] Extend the accepted IR surface for the smallest Zig-emitted aggregate
      forms needed by SROA fixtures.
- [ ] Build real alloca slice records with byte offsets, sizes, access type,
      and use kind.
- [ ] Partition compatible non-overlapping slices.
- [ ] Reject overlapping, packed, vector, variable-index, escaped, volatile,
      atomic, and unknown-size cases explicitly.
- [ ] Create replacement allocas for simple scalar partitions.
- [ ] Rewrite loads and stores that exactly cover a scalar partition.
- [ ] Preserve existing zero-offset GEP forwarding as a fast accepted case.
- [ ] Hand rewritten scalar allocas to mem2reg and verify downstream passes.
- [ ] Add Zig-originated aggregate fixtures before synthetic edge fixtures.
- [ ] Compare LLVM-equivalent SROA cases with `opt-22`; document local-only
      conservative gaps.

## Exit Criteria

- [ ] SROA can split at least one real Zig-originated aggregate stack object
      into scalar allocas.
- [ ] Unsupported aggregate/vector cases fail closed and are documented.
- [ ] SROA output remains accepted by mem2reg, verifier, and comparison tests.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

