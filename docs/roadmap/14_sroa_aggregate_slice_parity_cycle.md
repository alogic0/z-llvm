# Cycle 14: SROA Aggregate Slice Parity

## Goal

Expand SROA for Zig aggregate stack patterns using explicit slice and layout
reasoning.

## Plan

- [ ] Inventory aggregate alloca patterns from Zig rows: structs, arrays,
      optionals, errors, slices, and ABI temporaries.
- [ ] Add slice construction based on DataLayout offsets and access ranges.
- [ ] Split simple alloca aggregates into scalar replacements when every use is
      understood.
- [ ] Preserve or reject lifetime, debug, volatile, atomic, byval, and escaping
      uses explicitly.
- [ ] Add fixtures for scalarizable structs, arrays, partial fields, escaped
      pointers, debug-bearing allocas, and ABI attributes.
- [ ] Compare supported SROA cases with `opt-22`.
- [ ] Update SROA and DataLayout docs with the supported slice model.

## Exit Criteria

- [ ] At least one source-backed aggregate alloca scalarizes.
- [ ] Unsupported aggregate uses fail conservative checks.
- [ ] Slice reasoning is shared with alias and DSE where practical.
