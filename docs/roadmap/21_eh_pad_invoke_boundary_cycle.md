# Cycle 21: EH Pad and Invoke Boundary

## Goal

Define the exception-handling IR boundary for Zig-emitted rows and fail closed
for unsupported EH control flow.

## Plan

- [ ] Inventory `invoke`, `landingpad`, `resume`, `cleanupret`, `catchret`,
      `catchswitch`, `callbr`, and funclet constructs from Zig and reduced
      fixtures.
- [ ] Parse only the forms required to preserve or reject current source-backed
      rows with clear diagnostics.
- [ ] Add CFG verifier checks for EH pad placement and terminator edges for any
      accepted form.
- [ ] Keep optimization across EH edges disabled until control dependence and
      exceptional memory effects are modeled.
- [ ] Add fixtures for rejected unsupported EH, accepted preservation-only EH
      if required, and malformed EH edges.
- [ ] Update `docs/ir_exception_handling.md` and `docs/unsupported_ir.md`.
- [ ] Compare preservation or rejection expectations with LLVM behavior.

## Exit Criteria

- [ ] EH constructs are no longer accidental parser failures.
- [ ] Any accepted EH form has CFG verification.
- [ ] Optimizers remain fail-closed around exceptional control flow.
