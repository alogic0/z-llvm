# Cycle 14: Native Backend Handoff Validation

## Goal

Validate that local optimizer facts are useful to Zig's actual LLVM-removal
path: they should either feed Zig's native backends, explain why an LLVM-only
behavior is deferred, or provide corpus-backed correctness comparisons.

## Source Anchors

- Zig native backends under `../ziglang/src/arch/`
- Zig AIR/Liveness: `../ziglang/src/Air.zig`,
  `../ziglang/src/Air/Liveness.zig`
- Local docs: `docs/codegen/zig_native_backend_handoff.md`,
  `docs/target/scalar_abi.md`,
  `docs/mc/elf_object_writer.md`
- Local codegen/MC experiments: `src/codegen/`, `src/mc/`

## Plan

- [ ] Map each accepted optimizer output fact to a possible Zig AIR/native
      backend consumer.
- [ ] Identify optimizer facts that are LLVM-IR-specific and should not be
      ported into Zig's native path.
- [ ] Add handoff validation fixtures for scalar, memory, loop, and global
      optimized IR shapes.
- [ ] Keep object emission experiments validation-only unless they answer a
      concrete handoff question.
- [ ] Compare optimized local IR against Zig native backend expectations where
      the same source shape exists.
- [ ] Document target/ABI blockers that must be solved before backend handoff.
- [ ] Decide the next roadmap wave based on measured handoff gaps, not generic
      LLVM subsystem names.

## Exit Criteria

- [ ] Every major local optimizer subsystem has a documented Zig-native handoff
      story or a reason it remains LLVM-compatibility-only.
- [ ] Handoff validation distinguishes optimizer correctness from object/codegen
      completeness.
- [ ] The next roadmap wave is driven by concrete Zig backend gaps.

