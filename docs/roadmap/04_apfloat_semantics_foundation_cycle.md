# Cycle 04: APFloat Semantics Foundation

## Goal

Build the floating-point semantic model needed before enabling LLVM-like FP
folds.

## Plan

- [x] Define local FP value representation for IEEE zero, signed zero, NaN,
      infinity, normal, subnormal, and target-sized scalar types already parsed.
- [x] Preserve textual literal spellings while exposing semantic queries to
      optimizers.
- [x] Add DataLayout-aware type checks for supported FP widths.
- [x] Add verifier checks for invalid FP constants and unsupported target
      widths.
- [x] Add fixtures for signed zero, quiet NaN, signaling-unknown NaN spelling,
      infinity, and ordinary literals.
- [x] Document how this model maps to LLVM `APFloat` behavior and what remains
      deferred.
- [x] Keep all FP transforms disabled unless later cycles opt into specific
      legality rules.

## Exit Criteria

- [x] FP constants have semantic classification, not only string preservation.
- [x] Unsupported FP widths and malformed constants fail closed.
- [x] Docs explain the precise subset of `APFloat` being modeled.

## Completed Slice

Cycle 04 adds `src/analysis/fp_semantics.zig` as the local APFloat-shaped
literal classifier. It classifies zero, negative zero, NaN, infinity, normal,
and known subnormal spellings while preserving original text in the IR. No FP
arithmetic fold or value-numbering behavior is enabled by this cycle.
