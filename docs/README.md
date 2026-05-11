# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The first optimizer cycle slices are complete and archived under
`roadmap/historical/completed_cycle_slices/`. The first larger optimizer cycles
are complete and archived under `roadmap/historical/completed_big_cycles/`.
The first raw Zig-emitted IR corpus blocker wave is complete and archived under
`roadmap/historical/completed_corpus_blocker_cycles/`. The first source-backed
corpus expansion cycles are complete and archived under
`roadmap/historical/completed_corpus_expansion_cycles/`. The first
source-backed roadmap cycles are complete and archived under
`roadmap/historical/completed_source_backed_cycles/`. The finish-oriented
roadmap cycles are complete and archived under
`roadmap/historical/completed_finish_oriented_cycles/`.

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
  -> scalar FP compare and multiply
  -> scalar FP surface closure
  -> FP conservative optimizer pass-through
  -> target features and function attributes normalization
  -> ReleaseSmall corpus acceptance
  -> ReleaseSafe safety IR expansion
  -> debug metadata corpus expansion
  -> AArch64 DataLayout optimizer-input policy
  -> atomic and inline-asm boundary from Zig rows
  -> error, optional, and aggregate ABI expansion
  -> alias and memory precision for source-backed rows
  -> corpus refresh and readiness audit
  -> inline asm IR representation
  -> atomic RMW, cmpxchg, and fence representation
  -> vector IR parser and verifier bootstrap
  -> vector lane operation boundary
  -> target-cost policy for vector and FP transforms
  -> AArch64 optimizer-input promotion
  -> Debug-mode source-backed reduction expansion
  -> debug intrinsics and debug-value boundary
  -> FP constants, literals, and strict semantics
  -> extended scalar FP operations
  -> fast-math flags parser and verifier
  -> conservative FP optimization comparison
  -> path-aware MemorySSA foundation
  -> DSE with MemorySSA and partial-overwrite boundaries
  -> GVN load and PRE expansion with MemorySSA
  -> LICM memory-hoisting legality
  -> alias metadata policy
  -> function and call ModRef precision
  -> exception and EH IR boundary
  -> sanitizer, safety, and instrumentation boundary
  -> bitcode, LTO, and ThinLTO boundary
  -> ABI expansion for byval, sret, varargs, and aggregate returns
  -> native backend and AIR handoff mapping
  -> full corpus refresh and differential audit
  -> debug intrinsic variable location boundary
  -> debug metadata graph verification
  -> debug info salvage preservation
  -> APFloat-equivalent FP semantics
  -> strict FP fold legality
  -> fast-math optimization enablement
  -> FP lattice and value numbering legality
  -> MemorySSA updater and phi precision
  -> alias stack precision expansion
  -> GVN PRE and load redundancy parity
  -> DSE partial-overwrite and MemorySSA parity
  -> LICM memory promotion legality
  -> ADCE control-dependence parity
  -> SROA aggregate slice parity
  -> InstCombine integer and pointer parity
  -> SimplifyCFG canonical shape parity
  -> vector target-cost and lane optimization
  -> vector FP and select transform boundary
  -> atomic ordering and syncscope semantics
  -> TLS and concurrency IR acceptance
  -> EH pad and invoke boundary
  -> module linkage, COMDAT, and global optimization
  -> bitcode, LTO, and ThinLTO compatibility decision
  -> upstream readiness finish audit
```

## Completed Foundation Epics

- [x] [Completed Foundation Epics](roadmap/historical/completed_epics/README.md)

## Completed Cycle Slices

- [x] [Completed Optimizer Cycle Slices](roadmap/historical/completed_cycle_slices/README.md)

## Completed Big Cycles

- [x] [Completed Big Optimizer Cycles](roadmap/historical/completed_big_cycles/README.md)

## Completed Corpus Blocker Cycles

- [x] [Completed Corpus Blocker Cycles](roadmap/historical/completed_corpus_blocker_cycles/README.md)

## Completed Corpus Expansion Cycles

- [x] [Completed Corpus Expansion Cycles](roadmap/historical/completed_corpus_expansion_cycles/README.md)

## Completed Source-Backed Roadmap Cycles

- [x] [Completed Source-Backed Roadmap Cycles](roadmap/historical/completed_source_backed_cycles/README.md)

## Current Readiness Audit

- [x] [Source-Backed Readiness Audit](roadmap/source_backed_readiness_audit.md)

## Completed Finish-Oriented Roadmap Cycles

- [x] [Completed Finish-Oriented Roadmap Cycles](roadmap/historical/completed_finish_oriented_cycles/README.md)

## Current Finish Roadmap Cycles

- [x] [Cycle 01: Debug Intrinsic Variable Location Boundary](roadmap/01_debug_intrinsic_variable_location_boundary_cycle.md)
- [x] [Cycle 02: Debug Metadata Graph Verification](roadmap/02_debug_metadata_graph_verification_cycle.md)
- [x] [Cycle 03: Debug Info Salvage Preservation](roadmap/03_debug_info_salvage_preservation_cycle.md)
- [x] [Cycle 04: APFloat Semantics Foundation](roadmap/04_apfloat_semantics_foundation_cycle.md)
- [x] [Cycle 05: Strict FP Fold Legality](roadmap/05_strict_fp_fold_legality_cycle.md)
- [x] [Cycle 06: Fast-Math Optimization Enablement](roadmap/06_fast_math_optimization_enablement_cycle.md)
- [ ] [Cycle 07: FP Lattice and Value Numbering Legality](roadmap/07_fp_lattice_value_numbering_legality_cycle.md)
- [ ] [Cycle 08: MemorySSA Updater and Phi Precision](roadmap/08_memoryssa_updater_phi_precision_cycle.md)
- [ ] [Cycle 09: Alias Stack Precision Expansion](roadmap/09_alias_stack_precision_expansion_cycle.md)
- [ ] [Cycle 10: GVN PRE and Load Redundancy Parity](roadmap/10_gvn_pre_load_redundancy_parity_cycle.md)
- [ ] [Cycle 11: DSE Partial-Overwrite and MemorySSA Parity](roadmap/11_dse_partial_overwrite_memoryssa_parity_cycle.md)
- [ ] [Cycle 12: LICM Memory Promotion Legality](roadmap/12_licm_memory_promotion_legality_cycle.md)
- [ ] [Cycle 13: ADCE Control-Dependence Parity](roadmap/13_adce_control_dependence_parity_cycle.md)
- [ ] [Cycle 14: SROA Aggregate Slice Parity](roadmap/14_sroa_aggregate_slice_parity_cycle.md)
- [ ] [Cycle 15: InstCombine Integer and Pointer Parity](roadmap/15_instcombine_integer_pointer_parity_cycle.md)
- [ ] [Cycle 16: SimplifyCFG Canonical Shape Parity](roadmap/16_simplifycfg_canonical_shape_parity_cycle.md)
- [ ] [Cycle 17: Vector Target-Cost and Lane Optimization](roadmap/17_vector_target_cost_lane_optimization_cycle.md)
- [ ] [Cycle 18: Vector FP and Select Transform Boundary](roadmap/18_vector_fp_select_transform_boundary_cycle.md)
- [ ] [Cycle 19: Atomic Ordering and SyncScope Semantics](roadmap/19_atomic_ordering_syncscope_semantics_cycle.md)
- [ ] [Cycle 20: TLS and Concurrency IR Acceptance](roadmap/20_tls_concurrency_ir_acceptance_cycle.md)
- [ ] [Cycle 21: EH Pad and Invoke Boundary](roadmap/21_eh_pad_invoke_boundary_cycle.md)
- [ ] [Cycle 22: Module Linkage, COMDAT, and Global Optimization](roadmap/22_module_linkage_comdat_globalopt_cycle.md)
- [ ] [Cycle 23: Bitcode, LTO, and ThinLTO Compatibility Decision](roadmap/23_bitcode_lto_thinlto_compatibility_decision_cycle.md)
- [ ] [Cycle 24: Upstream Readiness Finish Audit](roadmap/24_upstream_readiness_finish_audit_cycle.md)

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
