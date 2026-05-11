# Cycle 4: Vector Lane Operation Boundary

## Goal

Accept or reject vector lane operations deliberately, starting with reduced
source-backed forms for extract, insert, and shuffle behavior.

## Source Anchors

- Future vector Zig captures
- LLVM IR: `extractelement`, `insertelement`, `shufflevector`
- Local code: IR parser, verifier, use-def logic
- LLVM comparison: `opt-22` preserve-only fixtures

## Plan

- [x] Add reduced fixtures for extract, insert, and shuffle spellings.
- [x] Represent only the lane operations required by source-backed rows.
- [x] Verify lane index type/range where statically knowable.
- [x] Keep poison/undef lane semantics conservative.
- [x] Add pass-through fixtures proving optimizers preserve accepted vector lane
      operations.
- [x] Document unsupported vector folds and vector canonicalization.

## Exit Criteria

- [x] Accepted lane operations parse, verify, print, and preserve operands.
- [x] Unsupported lane operations fail closed.
- [x] Vector lane support remains parser/verifier scope, not optimization parity.

## Completed Slice

- Added IR, parser, printer, verifier, and operand tracking for
      `extractelement`, `insertelement`, and `shufflevector`.
- Verified vector operand types, inserted element type, scalar integer lane
      indices, and constant lane/mask ranges where known.
- Added an opt-22 equivalent preserve fixture for used lane operations.
- Kept vector folds, canonicalization, vectorizer passes, target costs, and
      native lowering out of scope.
