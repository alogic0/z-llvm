# distribution-all Phase 0 timing baseline

schema_version=1
date=2026-07-11
source_commit=b94ea844379145dc33b7e1efcac3869cf90cb17c
worktree_state=identical uncommitted Phase 0 timing patch in build.zig and tools/run_distribution_all_gates.zig
zig_version=0.16.0
ziglang_pin=bdee02bc0c7f227c0f11bc9a449df673fe803540
target=x86_64-unknown-linux-gnu
fresh_command=zig build distribution-all -- --fresh-real-rows
fresh_log=tmp/distribution_all_timing_fresh.log
fresh_exit=0
fresh_wall_ms=3764620
fresh_child_ms=3764298
fresh_orchestration_overhead_ms=322
fresh_orchestration_overhead_percent=0.009
cached_command=zig build distribution-all
cached_log=tmp/distribution_all_timing_cached.log
cached_exit=0
cached_wall_ms=2289680
cached_child_ms=2289633
cached_orchestration_overhead_ms=47
cached_orchestration_overhead_percent=0.002
wall_measurement=log birth timestamp through final-write timestamp, rounded to nearest millisecond
semantic_summary_comparison=match
semantic_summary_command=diff of summary records after excluding distribution-all-slowest and distribution-all-timing records
ratchet_summary_comparison=match

## Per-subgate timings

| Gate | Fresh ms | Fresh cache | Cached ms | Cached cache |
| --- | ---: | --- | ---: | --- |
| `run_distribution_no_llvm_codegen_subset` | 54,999 | none | 53,584 | none |
| `run_native_link_object_inspection` | 2,273 | none | 2,269 | none |
| `run_distribution_native_link_m5` | 3,767 | none | 3,728 | none |
| `probe_native_linker_compatibility` | 3,706 | none | 3,703 | none |
| `run_distribution_zig_source_native_link` | 28,081 | none | 27,365 | none |
| `run_distribution_zig_integrated_object` | 136,311 | none | 135,349 | none |
| `run_distribution_zig_integrated_object --pipeline=preopt` | 555,836 | none | 565,374 | none |
| `run_distribution_zig_integrated_object --ir-writer` | 81,267 | none | 82,688 | none |
| `run_distribution_zig_integrated_object --release-source-owned` | 91,331 | none | 91,952 | none |
| `distribution_real_rows_gate ReleaseFast` | 875,114 | miss | 353,635 | hit |
| `distribution_real_rows_gate ReleaseSafe` | 912,473 | miss | 379,508 | hit |
| `distribution_real_rows_gate ReleaseSmall` | 745,905 | miss | 313,933 | hit |
| `run_distribution_zig_integrated_exe` | 1,657 | none | 1,536 | none |
| `run_native_link_object_inspection --release-source-owned` | 91,484 | none | 90,909 | none |
| `run_distribution_native_link_m5 --release-source-owned` | 90,175 | none | 91,640 | none |
| `probe_native_linker_compatibility --release-source-owned` | 89,172 | none | 91,723 | none |
| `run_distribution_boundary_gates` | 747 | none | 737 | none |

## Five slowest subgates

Fresh:

| Rank | Gate | Duration ms | Cache |
| ---: | --- | ---: | --- |
| 1 | `distribution_real_rows_gate ReleaseSafe` | 912,473 | miss |
| 2 | `distribution_real_rows_gate ReleaseFast` | 875,114 | miss |
| 3 | `distribution_real_rows_gate ReleaseSmall` | 745,905 | miss |
| 4 | `run_distribution_zig_integrated_object --pipeline=preopt` | 555,836 | none |
| 5 | `run_distribution_zig_integrated_object` | 136,311 | none |

Cached:

| Rank | Gate | Duration ms | Cache |
| ---: | --- | ---: | --- |
| 1 | `run_distribution_zig_integrated_object --pipeline=preopt` | 565,374 | none |
| 2 | `distribution_real_rows_gate ReleaseSafe` | 379,508 | hit |
| 3 | `distribution_real_rows_gate ReleaseFast` | 353,635 | hit |
| 4 | `distribution_real_rows_gate ReleaseSmall` | 313,933 | hit |
| 5 | `run_distribution_zig_integrated_object` | 135,349 | none |

## Phase 1 decision

decision=no-go
threshold=repeated tool compilation/startup must be at least 10 percent of cached wall time
measured_cached_orchestration_overhead_percent=0.002
rationale=The baseline does not separately prove that repeated tool compilation/startup consumes at least 228,968 ms of the cached run. Nearly all wall time is attributed to child gates, and the only isolated orchestration overhead is 47 ms. The forced-fresh comparison proves that real-row export caching saves 1,474,940 ms overall, but that is not evidence for the Phase 1 compiled-tool reuse threshold. Defer Phase 1 and return to the __udivei5 capability chain.

No correctness, ownership, expected-failure, or ratchet summary changed between
the fresh and cached logs. Both runs ended with `local_fail=0`.
