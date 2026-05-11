# Zig LLVM Removal Epic Plans

This document is the main roadmap entrypoint. It breaks
`roadmap/zig_upstream_llvm_removal_path.md` into implementable epics for this
repository.

The purpose is to keep the project aligned with Zig's upstream LLVM-removal
path:

```text
inventory
  -> Zig-emitted IR corpus
  -> verifier and semantic prerequisites
  -> mandatory canonicalization
  -> memory legality
  -> scalar optimization
  -> loop optimization
  -> native-backend handoff study
  -> optional bitcode/debug/LTO tracks
```

## Epics

- [ ] [Epic 1: Zig LLVM Dependency Inventory](roadmap/01_zig_llvm_dependency_inventory.md)
- [ ] [Epic 2: Zig-Emitted IR Corpus](roadmap/02_zig_emitted_ir_corpus.md)
- [ ] [Epic 3: LLVM-Compatible IR Verifier Foundation](roadmap/03_llvm_compatible_ir_verifier_foundation.md)
- [ ] [Epic 4: Mandatory Canonicalization Passes](roadmap/04_mandatory_canonicalization_passes.md)
- [ ] [Epic 5: Memory And Side-Effect Semantics](roadmap/05_memory_and_side_effect_semantics.md)
- [ ] [Epic 6: Scalar Optimization Pipeline](roadmap/06_scalar_optimization_pipeline.md)
- [ ] [Epic 7: Loop Optimization Pipeline](roadmap/07_loop_optimization_pipeline.md)
- [ ] [Epic 8: Native Backend Handoff Study](roadmap/08_native_backend_handoff_study.md)
- [ ] [Epic 9: Optional LLVM Bitcode, Debug, And LTO Tracks](roadmap/09_optional_bitcode_debug_lto_tracks.md)

## Operating Rule

Do not implement these as one giant milestone. Select one epic, extract a
day-sized slice into `next_steps.md` or the active next-steps file,
then close that slice with fixtures, docs, and comparison notes.

## Optimizer Parity Rule

Optimizer epics use `roadmap/llvm_algorithm_parity_gap_closure_plan.md` as a
quality rubric, not as a global blocker. A local pass should not be described
as reproduced just because a same-named pass exists.

Every optimizer pass should carry one status:

- [ ] `placeholder`: known pass, not implemented.
- [ ] `LLVM-shaped subset`: follows the broad LLVM pass structure for the local
      IR surface.
- [ ] `fixture-equivalent`: matches LLVM 22 for listed fixtures.
- [ ] `algorithm-parity target`: implements the same core LLVM data structures
      and algorithm flow for the supported IR surface.

For each pass, record LLVM source files, entry points/classes, required
analyses, core data structures, unsupported LLVM behavior, and exact fixtures
compared with `opt-22`.
