# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The first optimizer cycle slices are complete and archived under
`roadmap/historical/completed_cycle_slices/`. The first larger optimizer cycles
are complete and archived under `roadmap/historical/completed_big_cycles/`.
The first raw Zig-emitted IR corpus blocker wave is complete and archived under
`roadmap/historical/completed_corpus_blocker_cycles/`. The first source-backed
corpus expansion cycles are complete and archived under
`roadmap/historical/completed_corpus_expansion_cycles/`.

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

## Active Source-Backed Roadmap Cycles

- [x] [Cycle 1: Scalar FP Compare And Multiply](roadmap/01_scalar_fp_compare_and_multiply_cycle.md)
- [x] [Cycle 2: Scalar FP Surface Closure](roadmap/02_scalar_fp_surface_closure_cycle.md)
- [x] [Cycle 3: FP Conservative Optimizer Pass-Through](roadmap/03_fp_conservative_optimizer_passthrough_cycle.md)
- [x] [Cycle 4: Target Features And Function Attributes Normalization](roadmap/04_target_features_and_function_attrs_cycle.md)
- [x] [Cycle 5: ReleaseSmall Corpus Acceptance](roadmap/05_release_small_corpus_acceptance_cycle.md)
- [x] [Cycle 6: ReleaseSafe Safety IR Expansion](roadmap/06_release_safe_safety_ir_expansion_cycle.md)
- [x] [Cycle 7: Debug Metadata Corpus Expansion](roadmap/07_debug_metadata_corpus_expansion_cycle.md)
- [ ] [Cycle 8: AArch64 DataLayout Optimizer-Input Policy](roadmap/08_aarch64_datalayout_optimizer_policy_cycle.md)
- [ ] [Cycle 9: Atomic And Inline-Asm Boundary From Zig Rows](roadmap/09_atomic_inline_asm_boundary_from_zig_rows_cycle.md)
- [ ] [Cycle 10: Error, Optional, And Aggregate ABI Expansion](roadmap/10_error_optional_aggregate_abi_expansion_cycle.md)
- [ ] [Cycle 11: Alias And Memory Precision For Source-Backed Rows](roadmap/11_alias_memory_precision_source_backed_cycle.md)
- [ ] [Cycle 12: Corpus Refresh And Readiness Audit](roadmap/12_corpus_refresh_and_readiness_audit_cycle.md)

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
