# z_llvm documentation

| I want to… | Start here |
| --- | --- |
| Use the compiler | [Compile the hello program with the SDK](../README.md#use-the-packaged-compiler), or [build the optimizer from a fresh clone](../README.md#build-the-standalone-optimizer). Check [which tasks need LLVM](../README.md#do-i-need-llvm). |
| Understand the architecture | [Follow the IR from the Zig driver to the native ELF linker](architecture.md). See [current state](current_state.md) for the target, modes and test coverage. |
| Compare results with LLVM | [Compare compiler time, generated-program runtime and binary size](performance.md). Each result links to the workload and its baseline. |
| Contribute | [Set up a development checkout](../CONTRIBUTING.md), [choose the checks for a change](validation_tiers.md) and [read the current proposal](next_steps.md). |

<details>
<summary>Historical LLVM-removal roadmap and completed milestones</summary>

## Earlier milestones

The [architecture refactor plan](roadmap/architecture_refactor_plan.md) records
the earlier consolidation and performance baseline. The November 13
[compiler-object, behavior and self-rebuild plan](plans/2026-11-11-complete-compiler-object-and-self-rebuild.md)
finished at backend source `dbf7ade0`. Its
[final acceptance](evidence/compiler_behavior_follow_up_acceptance_20261113.json)
records both compiler generations matching the reference in four modes through
normal LLVM and local-hook routes, all 20 delivered local objects independently
audited, and a normal-resource self-rebuild with fresh backend execution. That
configuration used LLVM for frontend optimization and its declared providers.

For compiler performance investigations, follow [compiler profiling](compiler_profiling.md)
for the verified hardware-sampling setup, recording commands and evidence checks.

The [measured throughput follow-up](evidence/compiler_throughput_20261114.md)
records a 4.1% median reduction for the fixed Debug behavior emission workload.
The [ReleaseSafe preopt behavior plan](plans/2026-11-14-release-safe-preopt-behavior.md)
is complete: its [acceptance](evidence/release_safe_preopt_acceptance_20261116.md)
matches all 2,097 ordered reference outcomes with complete audited runtime and
test objects. The completed
[compiler generalization plan](plans/2026-11-16-generalize-compiler-mechanisms.md)
accepts four mechanism stages, ending with all 17 integration gates and all 233
native populations passing. Its
[scheduler experiment](evidence/compiler_generalization_stage5_20261116.md) is
measured and deferred because the declared benefit was not demonstrated.

The subsequent Fast and Small qualifications each match all 2,097 ordered
outcomes in one complete local preopt run. Their separate references, module
inventories and failure controls are recorded in the
[Fast result](evidence/release_fast_preopt_acceptance_20261117.md) and
[Small result](evidence/release_small_preopt_acceptance_20261117.md).

The [validation and compiler performance improvement plan](plans/2026-11-09-validation-performance-improvement.md)
records the toolchain, profiling, and validation-reuse work. See
[next steps](next_steps.md) for the active direction and
[contributing](../CONTRIBUTING.md) for the checks used in GitHub CI.

This document is the main roadmap entrypoint for replacing the LLVM library
dependency that Zig uses in its distribution. The local replacement is scoped
around the LLVM IR, optimizer, target, and backend handoff behavior Zig
actually exercises, rather than around cloning all of LLVM.

The initial Zig LLVM removal epics are complete and archived under
`roadmap/historical/completed_epics/`.
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
`roadmap/historical/completed_finish_oriented_cycles/`. Completed tooling
cycles are archived under `roadmap/historical/completed_tooling_cycles/`.

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

## Completed Finish Burn-Down 01-08

- [x] [Finish Burn-Down 01-08](roadmap/historical/finish_burndown_01_08/README.md)
- [x] [Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)
- [x] [Project Finish Statement](roadmap/project_finish_statement.md)

## Completed Discovery Cycles

- [x] [Completed Discovery Cycles](roadmap/historical/completed_discovery_cycles/README.md)

Cycle 08 decision: stop this burn-down wave. The readiness gate passes, every
remaining finish gap has a status, and no new measured cycle is active. Future
work should be selected from the backlog or a new source-backed blocker.

The sole authoritative current-action entry is kept short in
[next_steps.md](next_steps.md); roadmap queues are proposals and history.

The [Project Improvement Plan](roadmap/project_improvement_plan.md) prioritizes
artifact-store simplification and maximum justified cleanup, followed by
validation correctness, reproducible builds and tests, executable coverage,
and current project status.

## Completed Tooling Cycles

- [x] [Completed Tooling Cycles](roadmap/historical/completed_tooling_cycles/README.md)

## Completed Stub Replacement Plan

- [x] [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

## Completed Discovery Cycles

- [x] [Completed Discovery Cycles](roadmap/historical/completed_discovery_cycles/README.md)

## Future Backlog

- [Future Optimizer Backlog](roadmap/future_optimizer_backlog.md)

Use [Stub Replacement Cycle](stub_replacement_cycle.md) only if a future audit
adds new slices to the LLVM-shaped stub replacement plan.

## Operating Rule

Do not implement these as one giant milestone. When an explicit directive
authorizes a cycle, record that one bounded slice in `next_steps.md`, then close
it with the required fixtures, docs, and comparison notes. This backlog does
not authorize a slice by itself.

For code-layout-only work, use
[Refactoring Large Zig Files](refactoring_large_zig_files.md) as the local
guide for reducing oversized `.zig` files without mixing behavior changes into
mechanical splits.

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

</details>
