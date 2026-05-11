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

- [x] Extend the accepted IR surface for the smallest Zig-emitted aggregate
      forms needed by SROA fixtures.
- [x] Build real alloca slice records with byte offsets, sizes, access type,
      and use kind.
- [x] Partition compatible non-overlapping slices.
- [x] Reject overlapping, packed, vector, variable-index, escaped, volatile,
      atomic, and unknown-size cases explicitly.
- [x] Create replacement allocas for simple scalar partitions.
- [x] Rewrite loads and stores that exactly cover a scalar partition.
- [x] Preserve existing zero-offset GEP forwarding as a fast accepted case.
- [x] Hand rewritten scalar allocas to mem2reg and verify downstream passes.
- [x] Add Zig-originated aggregate fixtures before synthetic edge fixtures.
- [x] Compare LLVM-equivalent SROA cases with `opt-22`; document local-only
      conservative gaps.

## Exit Criteria

- [x] SROA can split at least one Zig-corpus-shaped aggregate stack object into
      scalar allocas.
- [x] Unsupported aggregate/vector cases fail closed and are documented.
- [x] SROA output remains accepted by mem2reg, verifier, and comparison tests.
- [x] `zig build test` and `bash scripts/compare_opt.sh` pass.

## Completed Slice

- [x] Added the narrow textual struct type surface needed for simple aggregate
      allocas and constant struct-field GEPs.
- [x] Added struct field offset/size helpers in `src/analysis/memory_location.zig`
      for SROA slice decisions.
- [x] Implemented exact-cover scalar integer field splitting in
      `src/passes/sroa.zig`, creating replacement allocas and handing them to
      mem2reg.
- [x] Preserved zero-offset scalar GEP forwarding while preventing aggregate
      field-zero GEPs from being mis-forwarded to the aggregate alloca.
- [x] Added `sroa_struct_two_i32` as an opt-22-equivalent fixture and kept
      volatile aggregate-field rejection as a local conservative unit test.

## Boundary Notes

The accepted aggregate fixture is a reduced SROA input shaped by the checked
Zig `aggregates` corpus row, not a full raw Zig-emitted IR fixture. The raw Zig
aggregate corpus still contains aliases, attrs, array byte GEPs, loop metadata,
and intrinsics outside this parser slice.

LLVM SROA can scalarize some volatile field cases into volatile accesses on a
replacement alloca. The local implementation rejects volatile and atomic
aggregate field accesses until memory-use rewriting is closer to LLVM's
`AllocaSlices` and rewrite-partition flow.
