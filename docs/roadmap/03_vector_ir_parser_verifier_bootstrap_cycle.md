# Cycle 3: Vector IR Parser And Verifier Bootstrap

## Goal

Add a minimal vector type and instruction surface for source-backed future Zig
rows, while keeping vector optimization and target-cost decisions disabled.

## Source Anchors

- Manifest row: `vector_future_release_fast`
- LLVM IR: fixed vector types, vector constants, lane operations
- Local docs: `docs/unsupported_ir.md`, target-cost roadmap notes
- Local code: `src/ir/core.zig`, parser, verifier, printer

## Plan

- [x] Represent fixed vector types with lane count and element type.
- [x] Parse and print basic vector function signatures and vector values.
- [x] Verify vector type equality, lane counts, and scalar-vs-vector operand
      mismatches.
- [x] Add negative fixtures for scalable vectors, unsupported element types, and
      unsupported operations.
- [x] Keep vector optimizer passes, target costs, and lowering out of scope.
- [x] Update unsupported docs with the accepted vector parser/verifier subset.

## Exit Criteria

- [x] A reduced vector fixture can parse, print, and verify.
- [x] Unsupported vector constructs fail closed.
- [x] No local optimizer treats vector operations as scalar operations.

## Completed Slice

- Added fixed-vector type representation for integer, float, double, and ptr
      element types.
- Parsed vector function signatures, vector returns, typed vector constants,
      and basic vector binary instructions.
- Verified lane counts, element types, vector constants, and scalar/vector
      mismatches.
- Kept vector rows out of optimizer-input and prevented scalar InstSimplify/CSE
      logic from treating vector binary operations as scalar expressions.
- Kept scalable vectors, lane operations, target costs, and native lowering
      unsupported.
