# Cycle 21: EH Pad and Invoke Boundary

## Goal

Define the exception-handling IR boundary for Zig-emitted rows and fail closed
for unsupported EH control flow.

## Plan

- [x] Inventory `invoke`, `landingpad`, `resume`, `cleanupret`, `catchret`,
      `catchswitch`, `callbr`, and funclet constructs from Zig and reduced
      fixtures.
- [x] Parse only the forms required to preserve or reject current source-backed
      rows with clear diagnostics.
- [x] Add CFG verifier checks for EH pad placement and terminator edges for any
      accepted form; no EH forms are accepted in this slice, so rejection is the
      verifier boundary.
- [x] Keep optimization across EH edges disabled until control dependence and
      exceptional memory effects are modeled.
- [x] Add fixtures for rejected unsupported EH, accepted preservation-only EH
      if required, and malformed EH edges.
- [x] Update `docs/ir_exception_handling.md` and `docs/unsupported_ir.md`.
- [x] Compare preservation or rejection expectations with LLVM behavior.

## Exit Criteria

- [x] EH constructs are no longer accidental parser failures.
- [x] Any accepted EH form has CFG verification.
- [x] Optimizers remain fail-closed around exceptional control flow.

## Completed Slice

- Extended explicit parser rejection coverage to `callbr` and `catchret` in
  addition to `invoke`, `landingpad`, `resume`, `catchswitch`, `cleanupret`,
  `catchpad`, `cleanuppad`, and function `personality` attributes.
- Kept all EH forms out of optimizer input, so SimplifyCFG, ADCE, and memory
  passes cannot accidentally treat exceptional edges as ordinary CFG.
