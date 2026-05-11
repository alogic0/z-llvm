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

- [x] Inventory error-union and optional lowering shapes in Zig-emitted IR.
- [x] Confirm whether accepted Zig modes emit LLVM EH constructs for target
      fixtures.
- [x] Parse non-EH error-union scalar/control-flow shapes where needed.
- [x] Keep LLVM EH terminators rejected until CFG, verifier, and optimizer
      rules are designed.
- [x] Add rejected fixtures for `invoke`, `landingpad`, and `resume`.
- [x] Document the difference between Zig errors and LLVM EH.

## Exit Criteria

- [x] Zig error-lowering blockers are not conflated with LLVM EH blockers.
- [x] EH IR rejection is explicit and tested.
- [x] Accepted error-union-like scalar patterns are owned by parser/pass cycles.

## Completion Notes

- Added explicit parser rejection for LLVM EH pad/terminator forms such as
  `landingpad` and `resume`.
- Existing `invoke` rejection remains classified as an unsupported call
  terminator.
- Added `docs/ir_exception_handling.md` to separate Zig error-control-flow
  handling from LLVM EH semantics.
