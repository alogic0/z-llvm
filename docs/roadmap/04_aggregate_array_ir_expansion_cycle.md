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

- [ ] Inventory aggregate, array, and GEP syntax emitted by Zig in the corpus.
- [ ] Extend the local type model from textual struct-only aggregates toward
      enough structured aggregate data to reason about offsets safely.
- [ ] Add array GEP offset support for constant indices.
- [ ] Keep variable-index, vector, packed, and target-layout-sensitive cases
      rejected until DataLayout support is real.
- [ ] Extend SROA slices for exact-cover array and struct field accesses.
- [ ] Add rejected fixtures for overlapping slices, volatile fields, escaped
      aggregate pointers, and unsupported padding.
- [ ] Promote an aggregate corpus-derived fixture to accepted optimizer input.

## Exit Criteria

- [ ] Aggregate corpus blockers are mapped to parser, type, DataLayout, or SROA
      owners.
- [ ] At least one array or struct-field corpus-derived case is accepted.
- [ ] SROA output still verifies and hands off to mem2reg where appropriate.

