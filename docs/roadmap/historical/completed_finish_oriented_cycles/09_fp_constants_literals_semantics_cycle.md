# Cycle 9: FP Constants, Literals, And Strict Semantics

## Goal

Accept source-backed floating-point constants and literal spellings while
documenting strict FP semantics before any folding is attempted.

## Source Anchors

- Current FP corpus rows and future literal-producing Zig rows
- LLVM IR: decimal and hexadecimal FP constants, NaN, infinity, signed zero
- Local docs: `docs/ir_scalar.md`, `docs/unsupported_ir.md`
- Local code: parser, verifier, printer, constant handling

## Plan

- [x] Capture or reduce a Zig fixture that emits FP constants.
- [x] Add a typed FP constant value representation if required.
- [x] Parse and print only observed FP literal spellings first.
- [x] Verify FP constants match their scalar FP type.
- [x] Reject or preserve NaN, infinity, and signed-zero spellings until their
      semantics are documented.
- [x] Keep FP constant folding disabled unless compared with `opt-22`.

## Exit Criteria

- [x] Source-backed FP constants parse, verify, and print.
- [x] Strict FP semantic gaps are documented.
- [x] No FP literal support enables unsafe integer-style folding.

## Completed Slice

- Added `fp_constants.zig` and captured its ReleaseFast LLVM IR with observed
      decimal `float` and `double` constants.
- Added raw FP literal value representation, parser/printer support, and
      verifier checks that permit literals only for scalar `float`/`double`.
- Added negative tests for NaN, infinity, and signed-zero spellings.
- Added an `opt-22` preservation fixture and kept all FP constant folding out
      of scope.
