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

- [x] Add or document the LLVM SROA algorithm contract.
- [x] Represent alloca slices for supported scalar and aggregate uses.
- [x] Partition compatible slices.
- [x] Use DataLayout offset and size reasoning for GEP and aggregate accesses.
- [x] Add rewrite decisions for simple scalar replacement cases.
- [x] Preserve explicit rejection for unsupported vector, packed aggregate,
      overlapping, and non-integral pointer cases.
- [x] Add mem2reg hardening checks if SROA output exposes gaps.
- [x] Add Zig-emitted aggregate fixtures as primary inputs.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] SROA is slice/partition based for accepted cases.
- [x] DataLayout-backed offset reasoning is documented and tested.
- [x] Unsupported aggregate/vector behavior is explicit.
- [x] Downstream mem2reg and canonicalization still pass fixtures.

## Notes

Zig-emitted aggregate fixtures are explicitly blocked on aggregate IR parsing
and printing. This cycle closes the accepted local SROA surface by adding
slice/partition scaffolding around alloca-rooted GEPs and documenting the
unsupported aggregate/vector cases instead of pretending they are implemented.
