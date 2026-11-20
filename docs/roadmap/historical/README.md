# Historical roadmaps

For the current proposal and its acceptance criteria, see [next steps](../../next_steps.md).
For the implementation decisions behind earlier releases, see the
[compiler development handoffs through November 19, 2026](handoffs-through-2026-11-19.md).

## Compiler milestones

| Milestone | Plan and results |
| --- | --- |
| Installed ReleaseFast compiler rebuilt Zig and its provider without host LLVM, Clang or LLD | [Dependency-removal plan](../../plans/2026-11-19-x86_64-releasefast-llvm-dependency-removal.md) · [Package qualification](../../evidence/llvm_free_self_rebuild_20261119.md) |
| Full local optimization of the upstream behavior suite | [ReleaseSafe plan](../../plans/2026-11-14-release-safe-preopt-behavior.md) · [Safe](../../evidence/release_safe_preopt_acceptance_20261116.md), [Fast](../../evidence/release_fast_preopt_acceptance_20261117.md) and [Small](../../evidence/release_small_preopt_acceptance_20261117.md) results |
| Shared compiler mechanisms and throughput | [Generalization plan](../../plans/2026-11-16-generalize-compiler-mechanisms.md) · [Deferred scheduler experiment](../../evidence/compiler_generalization_stage5_20261116.md) · [Compile-time measurements](../../evidence/compiler_throughput_20261114.md) |
| Earlier compiler-object route and self-rebuild with LLVM | [Implementation plan](../../plans/2026-11-11-complete-compiler-object-and-self-rebuild.md) · [Four-mode acceptance](../../evidence/compiler_behavior_follow_up_acceptance_20261113.json) |

The [architecture refactor](../architecture_refactor_plan.md), [project improvement plan](../project_improvement_plan.md)
and [validation performance plan](../../plans/2026-11-09-validation-performance-improvement.md)
record changes to the backend and the tools used to qualify it.

## Earlier roadmap cycles

| Area | Archived records |
| --- | --- |
| Compiler foundations | [Numbered epics](completed_epics/README.md) · [Optimizer slices](completed_cycle_slices/README.md) · [Larger optimizer cycles](completed_big_cycles/README.md) |
| Zig-emitted IR | [Corpus blockers](completed_corpus_blocker_cycles/README.md) · [Corpus expansion](completed_corpus_expansion_cycles/README.md) · [Source-backed cycles](completed_source_backed_cycles/README.md) · [Readiness audit](../source_backed_readiness_audit.md) |
| Completion criteria | [Finish-oriented cycles](completed_finish_oriented_cycles/README.md) · [Cycles 01–25](finish_cycles_01_25_archive/README.md) · [Remaining gaps](../finish_gap_burndown_table.md) · [Final cycles 01–08](finish_burndown_01_08/README.md) · [Finish statement](../project_finish_statement.md) |
| Review and tooling | [Discovery cycles](completed_discovery_cycles/README.md) · [Tooling cycles](completed_tooling_cycles/README.md) · [Stub replacement](../llvm_shaped_stub_replacement_plan.md) |

The [optimizer backlog](../future_optimizer_backlog.md) records deferred ideas.
The [stub replacement procedure](../../development/stub_replacement_cycle.md) documents how individual slices were reviewed.

## Original design notes

The [upstream LLVM replacement context](upstream_llvm_replacement_context.md),
[Zig LLVM workflow](zig_llvm_workflow.md) and [original pass pipeline plan](zig_llvm_pass_pipeline_plan.md)
describe the assumptions behind the early work. For the compiler that shipped,
see the [current architecture](../../architecture.md).
