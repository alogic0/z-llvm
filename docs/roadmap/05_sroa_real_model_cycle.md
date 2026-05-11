# Cycle 5: SROA Real Model

## Goal

Rebuild SROA around LLVM's slice and partition model for the local supported IR
surface, instead of growing ad hoc aggregate rewrites.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/SROA.cpp`
- LLVM support: DataLayout, alloca slices, partitioning, rewrite decisions
- Local docs: `docs/passes/sroa.md`, `docs/target/datalayout.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [ ] Add or document the LLVM SROA algorithm contract.
- [ ] Represent alloca slices for supported scalar and aggregate uses.
- [ ] Partition compatible slices.
- [ ] Use DataLayout offset and size reasoning for GEP and aggregate accesses.
- [ ] Add rewrite decisions for simple scalar replacement cases.
- [ ] Preserve explicit rejection for unsupported vector, packed aggregate,
      overlapping, and non-integral pointer cases.
- [ ] Add mem2reg hardening checks if SROA output exposes gaps.
- [ ] Add Zig-emitted aggregate fixtures as primary inputs.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] SROA is slice/partition based for accepted cases.
- [ ] DataLayout-backed offset reasoning is documented and tested.
- [ ] Unsupported aggregate/vector behavior is explicit.
- [ ] Downstream mem2reg and canonicalization still pass fixtures.

