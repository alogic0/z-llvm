# Cycle 3: Float IR Surface

## Goal

Classify and then minimally accept the floating-point IR surface emitted by the
new `floats_math` Zig corpus group without claiming broad floating-point
optimization parity.

## Source Anchors

- Corpus: `floats_math_release_fast`
- Zig source: `test/zig/inputs/floats_math.zig`
- Captured IR: `test/zig/captured/floats_math.ReleaseFast.x86_64.ll`
- LLVM: `fadd`, floating-point `select`, float/double function signatures
- Local code: `src/ir/core.zig`, `src/ir/parser.zig`, `src/ir/verifier.zig`

## Plan

- [x] Add `float` and `double` type records to the local IR without enabling
      vector or arbitrary FP semantics.
- [x] Parse and print `fadd` for scalar `float`/`double`.
- [x] Extend verifier value/type checks for scalar FP values.
- [x] Keep InstCombine, GVN, SCCP, and BDCE conservative for FP until explicit
      opt fixtures exist.
- [x] Move `floats_math_release_fast` to `parse,verify` first, and only mark
      `optimizer-input` after no pass mutates FP incorrectly.
- [x] Add local-only rejection fixtures for unsupported FP operations.

## Exit Criteria

- [x] The float corpus row has an honest classification update.
- [x] Scalar FP parse/print/verifier support is covered by tests.
- [x] Optimizer docs state which passes ignore or preserve FP instructions.

## Completion Notes

- `floats_math_release_fast` is now `parse,verify,float-ir,future`, not
  `optimizer-input`.
- The local optimizer does not fold or value-number `fadd`; FP optimization
  remains blocked until explicit LLVM comparison fixtures exist.
- Unsupported `fmul` and `fcmp` stay fail-closed through parser tests.
