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

- [x] Add the optimizer parity checklist to every loop pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [x] Document canonical loop shapes:
      header, latch, preheader, exiting blocks, exit blocks, dedicated exits,
      and LCSSA.
- [x] Add helper APIs:
      loop header, latches, preheader, exiting blocks, exit blocks, backedges,
      loop depth, contains block, and loop-invariant value.
- [x] Implement loop-simplify query checks for the currently accepted canonical
      shape; keep CFG-mutating transforms deferred until phi rewrites and
      dominator updates are robust.
- [x] Implement LCSSA-form checks for covered cases and document phi insertion
      as a required future transform before loop sinking, deletion, unswitching,
      or richer loop transforms.
- [x] Harden LICM with:
      dominance checks, memory legality, trap safety, invariant operand checks,
      and hoist-point use checks.
- [x] Record where LLVM loop passes depend on analyses not yet present locally:
      ScalarEvolution, LoopAccessAnalysis, MemorySSA, TargetTransformInfo, and
      profile data.
- [x] Keep loop rotate deferred until loop shape invariants are verified.
- [x] Keep simple unswitching deferred until branch and dominance updates are
      robust.
- [x] Keep unroll foundations deferred until small constant trip-count proof
      exists.
- [x] Keep vectorization out of this epic unless a later Zig-aligned need makes
      it active.
- [x] For each loop pass, mark status as `placeholder`, `LLVM-shaped subset`,
      `fixture-equivalent`, or `algorithm-parity target`.
- [x] Compare LLVM-equivalent fixtures against `opt-22`; document conservative
      gaps separately.

## Deliverables

- [x] Loop semantics and canonical-form doc.
- [x] Loop helper API implementation.
- [x] LICM hardening and fixtures.
- [x] Per-pass parity checklist entries.
- [x] Loop pass gap table.

## Exit Criteria

- [x] Loop passes operate only on documented canonical loop shapes or remain
      placeholders.
- [x] LICM cannot move memory, trapping, or side-effecting instructions without
      a documented proof.
- [x] Later loop transforms have stable analysis APIs to build on.
- [x] Loop pass status labels do not overclaim LLVM behavior without matching
      fixtures.
