# Cycle 4: Aggregate And Array IR Expansion

## Goal

Expand the aggregate IR surface enough to accept more Zig aggregate patterns:
arrays, struct field GEPs, scalarized fields, optional/error-union lowering
shapes, and the SROA/mem2reg handoff cases they create.

## Source Anchors

- Corpus row: `aggregates_release_fast`
- Local code: `src/passes/sroa.zig`, `src/passes/mem2reg.zig`,
  `src/analysis/memory_location.zig`, `src/ir/parser.zig`
- LLVM: `llvm/lib/Transforms/Scalar/SROA.cpp`

## Plan

- [x] Inventory aggregate, array, and GEP syntax emitted by Zig in the corpus.
- [x] Extend the local type model from textual struct-only aggregates toward
      enough structured aggregate data to reason about offsets safely.
- [x] Add array GEP offset support for constant indices.
- [x] Keep variable-index, vector, packed, and target-layout-sensitive cases
      rejected until DataLayout support is real.
- [x] Extend SROA slices for exact-cover array and struct field accesses.
- [x] Add rejected fixtures for overlapping slices, volatile fields, escaped
      aggregate pointers, and unsupported padding.
- [x] Promote an aggregate corpus-derived fixture to accepted optimizer input.

## Exit Criteria

- [x] Aggregate corpus blockers are mapped to parser, type, DataLayout, or SROA
      owners.
- [x] At least one array or struct-field corpus-derived case is accepted.
- [x] SROA output still verifies and hands off to mem2reg where appropriate.

## Implementation Notes

- `src/ir/parser.zig` now accepts textual array types such as `[4 x i8]` and
  GEP prefixes such as `inbounds`, `nuw`, and `nusw`.
- `src/analysis/memory_location.zig` can size simple textual array types for
  constant-index memory-location reasoning.
- Existing SROA exact-cover struct fixtures remain the SROA handoff coverage;
  variable-index and target-layout-sensitive GEPs stay conservative.
- The raw `aggregates_release_fast` corpus row now parses, verifies, and runs
  through the local corpus pipeline.
