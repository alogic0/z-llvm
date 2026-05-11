# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The first optimizer cycle slices are complete and archived under
`roadmap/historical/completed_cycle_slices/`. The first larger optimizer cycles
are complete and archived under `roadmap/historical/completed_big_cycles/`.
The active roadmap now targets raw Zig-emitted IR corpus blockers.

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

## Active Corpus Blocker Cycles

- [x] [Cycle 1: Raw Zig IR Parser Surface](roadmap/01_raw_zig_ir_parser_surface_cycle.md)
- [x] [Cycle 2: Intrinsics And Call Semantics](roadmap/02_intrinsics_and_call_semantics_cycle.md)
- [x] [Cycle 3: Pointer And Memory Corpus](roadmap/03_pointer_memory_corpus_cycle.md)
- [x] [Cycle 4: Aggregate And Array IR Expansion](roadmap/04_aggregate_array_ir_expansion_cycle.md)
- [x] [Cycle 5: Globals, Aliases, And Global Optimization](roadmap/05_globals_aliases_and_globalopt_cycle.md)
- [x] [Cycle 6: Loop Metadata, LCSSA, And Assume](roadmap/06_loop_metadata_lcssa_and_assume_cycle.md)
- [x] [Cycle 7: Release Pipeline Conformance](roadmap/07_release_pipeline_conformance_cycle.md)
- [x] [Cycle 8: Debug Metadata Preservation](roadmap/08_debug_metadata_preservation_cycle.md)
- [x] [Cycle 9: Target DataLayout And ABI Semantics](roadmap/09_target_datalayout_and_abi_semantics_cycle.md)
- [x] [Cycle 10: Interprocedural Optimization And Inlining Boundary](roadmap/10_interprocedural_optimization_cycle.md)
- [ ] [Cycle 11: Vector IR And Target Cost Boundary](roadmap/11_vector_ir_and_target_cost_cycle.md)
- [ ] [Cycle 12: Sanitizer, Instrumentation, And Safety IR](roadmap/12_sanitizer_instrumentation_and_safety_cycle.md)
- [ ] [Cycle 13: Bitcode, LTO, And ThinLTO Boundary](roadmap/13_bitcode_lto_and_thinlto_cycle.md)
- [ ] [Cycle 14: Native Backend Handoff Validation](roadmap/14_native_backend_handoff_validation_cycle.md)
- [ ] [Cycle 15: Algorithm Parity Audit](roadmap/15_algorithm_parity_audit_cycle.md)
- [ ] [Cycle 16: MemorySSA And Alias Precision](roadmap/16_memoryssa_and_alias_precision_cycle.md)
- [ ] [Cycle 17: Loop Optimization Parity](roadmap/17_loop_optimization_parity_cycle.md)
- [ ] [Cycle 18: Scalar Optimization Quality](roadmap/18_scalar_optimization_quality_cycle.md)
- [ ] [Cycle 19: Machine IR Lowering Boundary](roadmap/19_machine_ir_lowering_boundary_cycle.md)
- [ ] [Cycle 20: Object, Debug, And Unwind Boundary](roadmap/20_object_debug_and_unwind_cycle.md)
- [ ] [Cycle 21: Error Handling And EH IR](roadmap/21_error_handling_and_eh_ir_cycle.md)
- [ ] [Cycle 22: Inline Assembly And Atomics](roadmap/22_inline_asm_and_atomics_cycle.md)
- [ ] [Cycle 23: Module Flags, COMDAT, And Linkage](roadmap/23_module_flags_comdat_and_linkage_cycle.md)
- [ ] [Cycle 24: Concurrency And TLS](roadmap/24_concurrency_and_tls_cycle.md)
- [ ] [Cycle 25: Profile-Guided And Size Optimization](roadmap/25_profile_guided_and_size_optimization_cycle.md)
- [ ] [Cycle 26: Target Feature And CPU Model](roadmap/26_target_feature_and_cpu_model_cycle.md)
- [ ] [Cycle 27: Correctness Fuzzing And Differential Testing](roadmap/27_correctness_fuzzing_and_differential_cycle.md)
- [ ] [Cycle 28: Upstream Integration Readiness](roadmap/28_upstream_integration_readiness_cycle.md)

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
