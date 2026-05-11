# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The first optimizer cycle slices are complete and archived under
`roadmap/historical/completed_cycle_slices/`. The first larger optimizer cycles
are complete and archived under `roadmap/historical/completed_big_cycles/`.
The first raw Zig-emitted IR corpus blocker wave is complete and archived under
`roadmap/historical/completed_corpus_blocker_cycles/`. The active roadmap now
targets the next source-backed corpus expansion wave.

The purpose is to keep the project aligned with Zig's upstream LLVM-removal
path:

```text
completed foundation epics
  -> completed fixture-equivalent optimizer slices
  -> completed big optimizer cycles
  -> raw Zig IR parser surface
  -> intrinsics and call semantics
  -> pointer/memory corpus acceptance
  -> aggregate and array IR expansion
  -> globals, aliases, and global optimization
  -> loop metadata, LCSSA, and assume
  -> release pipeline conformance
  -> debug metadata preservation
  -> target DataLayout and ABI semantics
  -> interprocedural optimization and inlining boundary
  -> vector IR and target cost boundary
  -> sanitizer, instrumentation, and safety IR
  -> bitcode, LTO, and ThinLTO boundary
  -> native backend handoff validation
  -> algorithm parity audit
  -> MemorySSA and alias precision
  -> loop optimization parity
  -> scalar optimization quality
  -> Machine IR lowering boundary
  -> object, debug, and unwind boundary
  -> error handling and EH IR
  -> inline assembly and atomics
  -> module flags, COMDAT, and linkage
  -> concurrency and TLS
  -> profile-guided and size optimization
  -> target feature and CPU model
  -> correctness fuzzing and differential testing
  -> upstream integration readiness
  -> TLS concurrency acceptance
  -> switch table global constants
  -> float IR surface
  -> atomic and inline-asm fixture closure
  -> corpus capture automation
  -> next source-backed fixture wave
```

## Completed Foundation Epics

- [x] [Epic 1: Zig LLVM Dependency Inventory](roadmap/historical/completed_epics/01_zig_llvm_dependency_inventory.md)
- [x] [Epic 2: Zig-Emitted IR Corpus](roadmap/historical/completed_epics/02_zig_emitted_ir_corpus.md)
- [x] [Epic 3: LLVM-Compatible IR Verifier Foundation](roadmap/historical/completed_epics/03_llvm_compatible_ir_verifier_foundation.md)
- [x] [Epic 4: Mandatory Canonicalization Passes](roadmap/historical/completed_epics/04_mandatory_canonicalization_passes.md)
- [x] [Epic 5: Memory And Side-Effect Semantics](roadmap/historical/completed_epics/05_memory_and_side_effect_semantics.md)
- [x] [Epic 6: Scalar Optimization Pipeline](roadmap/historical/completed_epics/06_scalar_optimization_pipeline.md)
- [x] [Epic 7: Loop Optimization Pipeline](roadmap/historical/completed_epics/07_loop_optimization_pipeline.md)
- [x] [Epic 8: Native Backend Handoff Study](roadmap/historical/completed_epics/08_native_backend_handoff_study.md)
- [x] [Epic 9: Optional LLVM Bitcode, Debug, And LTO Tracks](roadmap/historical/completed_epics/09_optional_bitcode_debug_lto_tracks.md)

## Completed Cycle Slices

- [x] [Completed Optimizer Cycle Slices](roadmap/historical/completed_cycle_slices/README.md)

## Completed Big Cycles

- [x] [Completed Big Optimizer Cycles](roadmap/historical/completed_big_cycles/README.md)

## Completed Corpus Blocker Cycles

- [x] [Completed Corpus Blocker Cycles](roadmap/historical/completed_corpus_blocker_cycles/README.md)

## Active Corpus Expansion Cycles

- [x] [Cycle 1: TLS Concurrency Acceptance](roadmap/01_tls_concurrency_acceptance_cycle.md)
- [x] [Cycle 2: Switch Table Global Constants](roadmap/02_switch_table_global_constants_cycle.md)
- [x] [Cycle 3: Float IR Surface](roadmap/03_float_ir_surface_cycle.md)
- [x] [Cycle 4: Atomic And Inline-Asm Fixture Closure](roadmap/04_atomic_inline_asm_fixture_closure_cycle.md)
- [x] [Cycle 5: Corpus Capture Automation](roadmap/05_corpus_capture_automation_cycle.md)
- [x] [Cycle 6: Next Source-Backed Fixture Wave](roadmap/06_next_source_backed_fixture_wave_cycle.md)

## Future Backlog

- [ ] [Future Optimizer Backlog](roadmap/future_optimizer_backlog.md)

## Operating Rule

Do not implement these as one giant milestone. Select one cycle, extract a
day-sized slice into `next_steps.md` or the active next-steps file,
then close that slice with fixtures, docs, and comparison notes.

## Optimizer Parity Rule

Optimizer cycles use `roadmap/llvm_algorithm_parity_gap_closure_plan.md` as a
quality rubric, not as a global blocker. A local pass should not be described
as reproduced just because a same-named pass exists.

Every optimizer pass should carry one status:

- `placeholder`: known pass, not implemented.
- `LLVM-shaped subset`: follows the broad LLVM pass structure for the local
      IR surface.
- `fixture-equivalent`: matches LLVM 22 for listed fixtures.
- `algorithm-parity target`: implements the same core LLVM data structures
      and algorithm flow for the supported IR surface.

For each pass, record LLVM source files, entry points/classes, required
analyses, core data structures, unsupported LLVM behavior, and exact fixtures
compared with `opt-22`.
