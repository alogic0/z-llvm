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

- [ ] Map accepted optimized IR shapes to AIR/liveness concepts.
- [ ] Add handoff tests for scalar returns, direct calls, and simple stack slots.
- [ ] Keep register allocation and scheduling out of scope unless required by
      a handoff validation test.
- [ ] Document which local IR facts should disappear in a true Zig-native path.
- [ ] Add comparison notes between local MC experiments and Zig native backend
      responsibilities.

## Exit Criteria

- [ ] Handoff tests explain what optimizer facts are useful to Zig.
- [ ] MC/codegen experiments remain validation-only.
- [ ] Backend work does not derail optimizer parity tracking.

