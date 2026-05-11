# Cycle 04: APFloat Semantics Foundation

## Goal

Build the floating-point semantic model needed before enabling LLVM-like FP
folds.

## Plan

- [ ] Define local FP value representation for IEEE zero, signed zero, NaN,
      infinity, normal, subnormal, and target-sized scalar types already parsed.
- [ ] Preserve textual literal spellings while exposing semantic queries to
      optimizers.
- [ ] Add DataLayout-aware type checks for supported FP widths.
- [ ] Add verifier checks for invalid FP constants and unsupported target
      widths.
- [ ] Add fixtures for signed zero, quiet NaN, signaling-unknown NaN spelling,
      infinity, and ordinary literals.
- [ ] Document how this model maps to LLVM `APFloat` behavior and what remains
      deferred.
- [ ] Keep all FP transforms disabled unless later cycles opt into specific
      legality rules.

## Exit Criteria

- [ ] FP constants have semantic classification, not only string preservation.
- [ ] Unsupported FP widths and malformed constants fail closed.
- [ ] Docs explain the precise subset of `APFloat` being modeled.
