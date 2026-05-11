# Cycle 2: Scalar FP Surface Closure

## Goal

Close the common scalar floating-point instruction surface that Zig is likely to
emit for small source-backed examples, while keeping complex FP semantics and
fast-math transforms out of scope.

## Source Anchors

- Corpus rows: `floats_math_release_fast`, `float_compare_release_fast`
- Local docs: `docs/unsupported_ir.md`, `docs/fixtures/zig_ir/README.md`
- LLVM IR: scalar `fadd`, `fmul`, future `fsub`, `fdiv`, and `fcmp`
- Local code: IR parser, verifier, printer, pass preservation paths

## Plan

- [x] Add scalar `fsub` and `fdiv` parsing, printing, verification, and tests
      only after a Zig-emitted source fixture requires them.
      Current corpus has no such row, so they remain rejected with tests.
- [x] Add the common ordered and unordered scalar `fcmp` predicates needed by
      captured Zig rows.
- [x] Add FP literal/constant handling only for spellings observed in Zig
      captures.
      Current captures use SSA operands only, so no FP literal surface was added.
- [x] Keep fast-math flags rejected or preserved conservatively until a separate
      semantics cycle handles them.
- [x] Add local-only negative fixtures for vector FP, constrained FP, and
      unsupported predicates.
- [x] Update the manifest classifications for FP rows after each accepted
      surface addition.
      No manifest classification changed beyond Cycle 1 because the rows stay
      parse/verify/float-ir/future.

## Exit Criteria

- [x] Common source-backed scalar FP instructions parse, verify, and print.
- [x] Unsupported FP features fail closed with named diagnostics or tests.
- [x] The FP surface is documented as semantic support, not optimization parity.
