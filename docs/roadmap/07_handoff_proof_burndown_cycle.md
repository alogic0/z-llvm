# Cycle 07: Handoff Proof Burn-Down

## Goal

Add one non-trivial native backend or AIR handoff proof that demonstrates
accepted optimized IR can move toward Zig-owned codegen.

## Evidence

The finish table says backend parity is out of scope, but current finish
evidence needs at least scalar, memory, loop, and global handoff proof plus
x86_64 text/object smoke coverage for the local backend subset.

## Plan

- [x] Inspect current handoff validation fixtures and identify the weakest
      covered shape.
- [x] Select one non-trivial shape, such as call plus stack plus memory, loop
      plus memory, or global access plus call.
- [x] Keep the backend target bounded to the existing x86_64 smoke path unless
      a source-backed AArch64 handoff requirement exists.
- [x] Add the smallest fixture and validation command needed to prove the
      selected handoff.
- [x] Update codegen handoff docs, readiness scripts, and the finish table.
- [x] Keep register allocation, scheduling, broad ABI lowering, debug unwind,
      and object-format parity out of scope.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] One non-trivial handoff proof is added.
- [x] The proof is covered by the readiness gate.
- [x] Backend scope remains bounded and Zig-aligned.

## Completed Slice

```text
Cycle 07 selects the weakest existing native handoff shape: calls and fixed
stack slots were covered separately, but explicit IR stack memory feeding a
direct call was not. The new `call_stack_slot` x86_64 fixture lowers one
alloca/store/load chain into the fixed `%rsp` slot, reloads `%edi`, emits a
direct `callq`, and validates the same `R_X86_64_PLT32` relocation smoke path
as the other direct-call fixtures.
Readiness passed with `manifest rows=37 optimizer_input=30` and
`summary accepted=30 unsupported=0 future=4 debug-info-only=0`.
```
