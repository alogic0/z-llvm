# Cycle 1: Scalar FP Compare And Multiply

## Goal

Promote the source-backed `float_compare_release_fast` blocker from unsupported
IR into the parsed and verified scalar floating-point surface, without claiming
floating-point optimization parity.

## Source Anchors

- Corpus: `float_compare_release_fast`
- Zig source: `test/zig/inputs/float_compare.zig`
- Captured IR: `test/zig/captured/float_compare.ReleaseFast.x86_64.ll`
- LLVM IR: `fmul double`, `fcmp olt float`
- Local code: `src/ir/core.zig`, `src/ir/parser.zig`, `src/ir/verifier.zig`

## Plan

- [x] Add scalar `fmul` to the local binary-op model, parser, printer, and
      verifier for `float` and `double`.
- [x] Add scalar `fcmp` instruction representation, parser, printer, verifier,
      and def-use support for the observed `olt` predicate.
- [x] Preserve `fmul` and `fcmp` through existing pass pipelines without folding
      or reassociation.
- [x] Add parser and verifier tests for accepted scalar FP multiply and compare.
- [x] Add rejected tests for unsupported FP predicates or operand types that are
      still outside this cycle.
- [x] Update `docs/unsupported_ir.md` and FP/pass docs so the supported surface
      and remaining gaps are explicit.

## Exit Criteria

- [x] `float_compare_release_fast` is no longer `unsupported`.
- [x] The row is classified as `parse,verify,float-ir,future`, or
      `parse,verify,optimizer-input` only after the local release pipeline
      preserves it correctly.
- [x] No optimizer pass folds or rewrites FP values without an explicit
      `opt-22` fixture.
