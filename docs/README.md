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
`roadmap/historical/completed_source_backed_cycles/`.

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

- [x] [Cycle 1: Inline Asm IR Representation](roadmap/01_inline_asm_ir_representation_cycle.md)
- [x] [Cycle 2: Atomic RMW, Cmpxchg, And Fence Representation](roadmap/02_atomic_rmw_cmpxchg_fence_cycle.md)
- [x] [Cycle 3: Vector IR Parser And Verifier Bootstrap](roadmap/03_vector_ir_parser_verifier_bootstrap_cycle.md)
- [x] [Cycle 4: Vector Lane Operation Boundary](roadmap/04_vector_lane_operation_boundary_cycle.md)
- [x] [Cycle 5: Target-Cost Policy For Vector And FP Transforms](roadmap/05_target_cost_policy_cycle.md)
- [x] [Cycle 6: AArch64 Optimizer-Input Promotion](roadmap/06_aarch64_optimizer_input_promotion_cycle.md)
- [x] [Cycle 7: Debug-Mode Source-Backed Reduction Expansion](roadmap/07_debug_mode_reduction_expansion_cycle.md)
- [x] [Cycle 8: Debug Intrinsics And Debug-Value Boundary](roadmap/08_debug_intrinsics_value_boundary_cycle.md)
- [x] [Cycle 9: FP Constants, Literals, And Strict Semantics](roadmap/09_fp_constants_literals_semantics_cycle.md)
- [x] [Cycle 10: Extended Scalar FP Operations](roadmap/10_scalar_fp_ops_extended_cycle.md)
- [x] [Cycle 11: Fast-Math Flags Parser And Verifier](roadmap/11_fast_math_flags_parser_verifier_cycle.md)
- [x] [Cycle 12: Conservative FP Optimization Comparison](roadmap/12_conservative_fp_optimization_comparison_cycle.md)
- [x] [Cycle 13: Path-Aware MemorySSA Foundation](roadmap/13_path_aware_memoryssa_foundation_cycle.md)
- [x] [Cycle 14: DSE With MemorySSA And Partial Overwrite Boundaries](roadmap/14_dse_memoryssa_partial_overwrite_cycle.md)
- [x] [Cycle 15: GVN Load And PRE Expansion With MemorySSA](roadmap/15_gvn_load_pre_memoryssa_cycle.md)
- [x] [Cycle 16: LICM Memory-Hoisting Legality](roadmap/16_licm_memory_hoisting_legality_cycle.md)
- [x] [Cycle 17: Alias Metadata Policy](roadmap/17_alias_metadata_policy_cycle.md)
- [x] [Cycle 18: Function And Call ModRef Precision](roadmap/18_call_modref_attribute_precision_cycle.md)
- [x] [Cycle 19: Exception And EH IR Boundary](roadmap/19_exception_eh_ir_boundary_cycle.md)
- [x] [Cycle 20: Sanitizer, Safety, And Instrumentation Boundary](roadmap/20_sanitizer_safety_instrumentation_boundary_cycle.md)
- [x] [Cycle 21: Bitcode, LTO, And ThinLTO Boundary](roadmap/21_bitcode_lto_thinlto_boundary_cycle.md)
- [x] [Cycle 22: ABI Expansion For Byval, Sret, Varargs, And Aggregate Returns](roadmap/22_abi_byval_sret_varargs_cycle.md)
- [x] [Cycle 23: Native Backend And AIR Handoff Mapping](roadmap/23_native_backend_air_handoff_mapping_cycle.md)
- [x] [Cycle 24: Full Corpus Refresh And Differential Audit](roadmap/24_full_corpus_refresh_differential_audit_cycle.md)

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
