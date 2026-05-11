# Cycle 4: SCCP And InstCombine Semantics Expansion

## Goal

Improve scalar semantic fidelity for the optimizations Zig is likely to depend
on: constants, undef, poison-adjacent freeze behavior, integer flags, casts,
comparisons, select, and PHI handling.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/SCCP.cpp`
- LLVM: `llvm/lib/Transforms/InstCombine/`
- LLVM: `llvm/lib/Analysis/ValueLattice.cpp`
- Local docs: `docs/passes/sccp.md`, `docs/passes/instcombine.md`,
  `docs/passes/inst_simplify.md`
- Local code: `src/passes/sccp.zig`, `src/passes/instcombine.zig`,
  `src/passes/inst_simplify.zig`

## Plan

- [ ] Expand SCCP lattice tests for undef, overdefined, constant, executable
      blocks, and executable edges.
- [ ] Add more precise handling for PHI incoming values from unreachable edges.
- [x] Add supported integer cast folds with width-aware signed/unsigned rules.
- [ ] Expand `icmp` folding for signed/unsigned predicates and known constants.
- [x] Add select folding cases that are legal under local undef/freeze rules.
- [ ] Audit all arithmetic folds involving flags (`nsw`, `nuw`, `exact`) and
      reject unsafe folds.
- [ ] Add fixtures from Zig-emitted scalar IR where possible before synthetic
      cases.
- [ ] Keep poison modeling explicit: implement only the cases whose semantics
      are documented and tested.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`; document any deliberate
      conservative differences.

## Exit Criteria

- [ ] SCCP and InstCombine have a shared documented semantic boundary for undef,
      freeze, flags, and integer widths.
- [ ] Unsafe flag-sensitive folds are covered by rejected fixtures.
- [ ] Scalar Zig-originated fixtures exercise the expanded behavior.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

## Completed Cast Semantics Slice

- [x] Updated constant `zext` and `sext` folding to interpret the source value
      through the source integer width instead of rejecting negative or
      unsigned textual forms.
- [x] Added `instcombine_cast_bitpatterns` to compare `zext i8 -1` and
      `sext i8 255` behavior against `opt-22`.
- [x] Documented the width-aware bitpattern boundary in
      `docs/passes/inst_simplify.md`.
- [x] Verified with `zig build test` and `bash scripts/compare_opt.sh`.

## Completed SCCP Select Slice

- [x] Adjusted SCCP select operand mapping so an overdefined condition does not
      block legal identical-arm simplification.
- [x] Added `sccp_select_same_arms` as an opt-22-equivalent fixture.
- [x] Documented the selected local SCCP semantic boundary in
      `docs/passes/sccp.md`.
- [x] Verified with `zig build test` and `bash scripts/compare_opt.sh`.
