# Epic 7: Loop Optimization Pipeline

## Goal

Implement the loop analysis and loop optimization foundations needed by Zig's
discovered LLVM optimization pipeline.

## Inputs

- Verifier foundation from `03_llvm_compatible_ir_verifier_foundation.md`
- Canonicalization passes from `04_mandatory_canonicalization_passes.md`
- Memory legality from `05_memory_and_side_effect_semantics.md`
- Existing loop analysis and LICM work

## Plan

- [ ] Add the optimizer parity checklist to every loop pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [ ] Document canonical loop shapes:
      header, latch, preheader, exiting blocks, exit blocks, dedicated exits,
      and LCSSA.
- [ ] Add helper APIs:
      loop header, latches, preheader, exiting blocks, exit blocks, backedges,
      loop depth, contains block, and loop-invariant value.
- [ ] Implement loop-simplify checks and conservative transforms.
- [ ] Implement LCSSA checks and minimal formation for covered cases.
- [ ] Harden LICM with:
      dominance checks, memory legality, trap safety, invariant operand checks,
      and hoist-point use checks.
- [ ] Record where LLVM loop passes depend on analyses not yet present locally:
      ScalarEvolution, LoopAccessAnalysis, MemorySSA, TargetTransformInfo, and
      profile data.
- [ ] Add loop rotate only after loop shape invariants are verified.
- [ ] Add simple unswitching only after branch and dominance updates are robust.
- [ ] Add unroll foundations only for small constant trip-count cases.
- [ ] Keep vectorization out of this epic unless a later Zig-aligned need makes
      it active.
- [ ] For each loop pass, mark status as `placeholder`, `LLVM-shaped subset`,
      `fixture-equivalent`, or `algorithm-parity target`.
- [ ] Compare LLVM-equivalent fixtures against `opt-22`; document conservative
      gaps separately.

## Deliverables

- [ ] Loop semantics and canonical-form doc.
- [ ] Loop helper API implementation.
- [ ] LICM hardening and fixtures.
- [ ] Per-pass parity checklist entries.
- [ ] Loop pass gap table.

## Exit Criteria

- [ ] Loop passes operate only on verified loop shapes.
- [ ] LICM cannot move memory, trapping, or side-effecting instructions without
      a documented proof.
- [ ] Later loop transforms have stable analysis APIs to build on.
- [ ] Loop pass status labels do not overclaim LLVM behavior without matching
      fixtures.
