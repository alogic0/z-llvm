# Cycle 21: Error Handling And EH IR

## Goal

Separate Zig error-union/control-flow lowering from LLVM exception-handling IR,
and decide which constructs must be parsed, preserved, or rejected for Zig's
actual LLVM-removal path.

## Source Anchors

- Zig corpus: aggregate/control-flow fixtures with error-union-like lowering
- LLVM IR: `landingpad`, `invoke`, `resume`, personality functions
- Local docs: `docs/unsupported_ir.md`, `docs/ir_control_flow.md`

## Plan

- [ ] Inventory error-union and optional lowering shapes in Zig-emitted IR.
- [ ] Confirm whether accepted Zig modes emit LLVM EH constructs for target
      fixtures.
- [ ] Parse non-EH error-union scalar/control-flow shapes where needed.
- [ ] Keep LLVM EH terminators rejected until CFG, verifier, and optimizer
      rules are designed.
- [ ] Add rejected fixtures for `invoke`, `landingpad`, and `resume`.
- [ ] Document the difference between Zig errors and LLVM EH.

## Exit Criteria

- [ ] Zig error-lowering blockers are not conflated with LLVM EH blockers.
- [ ] EH IR rejection is explicit and tested.
- [ ] Accepted error-union-like scalar patterns are owned by parser/pass cycles.

