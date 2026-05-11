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

## Finish Cycles 01-25 Archive

- [x] [Finish Cycles 01-25 Archive](roadmap/historical/finish_cycles_01_25_archive/README.md)

## Current Finish Burn-Down

- [x] [Cycle 01: Finish Criteria and Gap Burn-Down](roadmap/01_finish_criteria_and_gap_burndown_cycle.md)
- [x] [Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)
- [x] [Cycle 02: Stale ReleaseSmall Corpus Row Closure](roadmap/02_stale_release_small_corpus_row_closure_cycle.md)
- [ ] [Cycle 03: Future Raw Debug and ReleaseSafe Row Policy](roadmap/03_future_raw_debug_release_safe_policy_cycle.md)
- [ ] [Cycle 04: Vector Future Boundary Closure](roadmap/04_vector_future_boundary_closure_cycle.md)
- [ ] [Cycle 05: Optimizer Quality Burn-Down](roadmap/05_optimizer_quality_burndown_cycle.md)
- [ ] [Cycle 06: Debug Salvage Boundary Burn-Down](roadmap/06_debug_salvage_boundary_burndown_cycle.md)
- [ ] [Cycle 07: Handoff Proof Burn-Down](roadmap/07_handoff_proof_burndown_cycle.md)
- [ ] [Cycle 08: Final Readiness Audit](roadmap/08_final_readiness_audit_cycle.md)

The selected active implementation slice is kept short in
[next_steps.md](next_steps.md).

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
