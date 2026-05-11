# Cycle 19: Machine IR Lowering Boundary

## Goal

Clarify and test the boundary between local LLVM-IR-compatible optimization and
Zig native backend lowering, using tiny Machine IR experiments only when they
validate optimizer handoff facts.

## Source Anchors

- Zig native backends: `../ziglang/src/arch/`
- Local codegen: `src/codegen/`, `src/mc/`
- Local docs: `docs/codegen/zig_native_backend_handoff.md`,
  `docs/target/scalar_abi.md`

## Plan

- [x] Map accepted optimized IR shapes to AIR/liveness concepts.
- [x] Add handoff tests for scalar returns, direct calls, and simple stack slots.
- [x] Keep register allocation and scheduling out of scope unless required by
      a handoff validation test.
- [x] Document which local IR facts should disappear in a true Zig-native path.
- [x] Add comparison notes between local MC experiments and Zig native backend
      responsibilities.

## Exit Criteria

- [x] Handoff tests explain what optimizer facts are useful to Zig.
- [x] MC/codegen experiments remain validation-only.
- [x] Backend work does not derail optimizer parity tracking.

## Completion Notes

- Added `docs/codegen/air_liveness_handoff.md` to map accepted optimized IR
  facts to Zig AIR, Liveness, and backend lowering concepts.
- Extended `scripts/run_handoff_validation.sh` with explicit scalar return,
  direct-call, and stack-slot assembly checks while keeping the full assembly
  matrix as validation-only smoke coverage.
- Register allocation, scheduling, target costs, debug/unwind, and linker
  behavior remain out of scope for this cycle.
