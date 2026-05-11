# Cycle 14: SROA Aggregate Slice Parity

## Goal

Expand SROA for Zig aggregate stack patterns using explicit slice and layout
reasoning.

## Plan

- [x] Inventory aggregate alloca patterns from Zig rows: structs, arrays,
      optionals, errors, slices, and ABI temporaries.
- [x] Add slice construction based on DataLayout offsets and access ranges.
- [x] Split simple alloca aggregates into scalar replacements when every use is
      understood.
- [x] Preserve or reject lifetime, debug, volatile, atomic, byval, and escaping
      uses explicitly.
- [x] Add fixtures for scalarizable structs, arrays, partial fields, escaped
      pointers, debug-bearing allocas, and ABI attributes.
- [x] Compare supported SROA cases with `opt-22`.
- [x] Update SROA and DataLayout docs with the supported slice model.

## Exit Criteria

- [x] At least one source-backed aggregate alloca scalarizes.
- [x] Unsupported aggregate uses fail conservative checks.
- [x] Slice reasoning is shared with alias and DSE where practical.

## Completed Slice

Cycle 14 extends the SROA slice model from struct-only integer fields to simple
fixed integer arrays. The local pass now scalarizes exact-cover struct
field/array element accesses, still rejecting escaped pointers, debug-declare
allocas, volatile/atomic memory, byval parameter boundaries, and unknown uses.
