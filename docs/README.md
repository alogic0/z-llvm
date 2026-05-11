# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The first optimizer cycle slices are complete and archived under
`roadmap/historical/completed_cycle_slices/`. The active roadmap is now the
next set of larger optimizer cycles.

The purpose is to keep the project aligned with Zig's upstream LLVM-removal
path:

```text
completed foundation epics
  -> completed fixture-equivalent optimizer slices
  -> memory dependence and legality hardening
  -> SROA aggregate scalarization
  -> CFG mutation for ADCE/SimplifyCFG
  -> SCCP/InstCombine semantic expansion
  -> GVN/EarlyCSE value numbering and PRE foundation
  -> loop pipeline quality
  -> Zig pipeline corpus parity
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

## Active Big Cycles

- [x] [Cycle 1: Memory Dependence And Legality Hardening](roadmap/01_memory_dependence_legality_hardening_cycle.md)
- [x] [Cycle 2: SROA Aggregate Scalarization](roadmap/02_sroa_aggregate_scalarization_cycle.md)
- [x] [Cycle 3: CFG Mutation, ADCE, And SimplifyCFG](roadmap/03_cfg_mutation_adce_simplifycfg_cycle.md)
- [ ] [Cycle 4: SCCP And InstCombine Semantics Expansion](roadmap/04_sccp_instcombine_semantics_cycle.md)
- [ ] [Cycle 5: Value Numbering And PRE Foundation](roadmap/05_value_numbering_and_pre_cycle.md)
- [ ] [Cycle 6: Loop Pipeline Quality](roadmap/06_loop_pipeline_quality_cycle.md)
- [ ] [Cycle 7: Zig Pipeline Corpus Parity](roadmap/07_zig_pipeline_corpus_parity_cycle.md)

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
