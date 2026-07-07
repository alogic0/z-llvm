# Next Steps

This file is only for short-lived blocker and handoff notes.

The durable implementation queue is:

- `docs/roadmap/convergence_progress.md` (live tracker; the strategy
  reference is `docs/roadmap/end_to_end_convergence_plan.md`)

The family tactic list, used when a convergence goal directs family work:

- `docs/roadmap/x86_64_compiler_core_family_checklist.md`

The worker cycle rules are:

- `docs/working-cycle.md`

Do not use this file as a routine progress log. Normal implementation cycles
should check off completed items in `docs/roadmap/convergence_progress.md`,
update its Ratchet State table when counters changed, and check off family
items in the family checklist when the goal was a family item.

## Current Operating Rule

Pick the cycle goal in this order:

1. the first failing `distribution-real-rows` entry, when that gate exists;
2. the first failing real-program milestone gate, when it exists;
3. the first unchecked item in `docs/roadmap/convergence_progress.md`,
   top to bottom.

Stay on the selected goal until:

- the goal is complete;
- the next step needs hook-contract or architectural review;
- validation exposes an unexpected blocker.

## Active Blocker

Architectural review: item 12 report-all inventory shows the largest
remaining compiler_rt cluster is soft-float/libm/conversion work with 259
failures and 180 mechanical family/diagnostic buckets. Per the item-12
soft-float escalation rule, pull item 15 forward before implementing this
cluster rather than stacking generic-CFG shapes one family at a time.

Stop state recorded 2026-07-07 after compiler_rt report-all inventory cycle:

- Active convergence-progress item: item 12 on the std-hello real-program
  track. The real-row track closed item 10 at strict
  `--limit=100`, but every stop report still states both tracks.
- Real-row track status: strict `distribution-real-rows --strict --limit=100`
  is green in ReleaseFast, ReleaseSafe, and ReleaseSmall, and
  `distribution-all` enforces that strict limit. Selector-v2 ReleaseFast
  report-mode `distribution-real-rows --mode=ReleaseFast --limit=200` remains
  green through typed lowering, x86_64 object emission, and native link with
  counters `real_functions_lowered=200`, `real_objects_emitted=200`,
  `real_native_linked=200`, `real_executed=0`, `real_programs_ok=0`.
- Real-program track status: item 11 syscall hello is closed by
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`. Patched Zig plus
  z_llvm object emission and Zig native `build-exe -fno-lld` build a no-std
  `_start` executable in ReleaseFast, ReleaseSafe, and ReleaseSmall; each run
  prints `hello\n` and exits 0. Item 12 std hello remains open. The latest
  process-improvement cycle added opt-in z_llvm report-all object-emission
  mode for the focused compiler_rt sub-compilation. The Debug std-hello
  report-all run selected 443 compiler_rt functions, emitted 103, and
  reported 340 failures before failing closed with no object output. The
  remaining Cluster Board order is now largest-first: soft-float/libm/
  conversion helpers 259 failures, integer helper families 66 failures, and
  limb64 loops 15 failures. The previous first failing function remains
  `compiler_rt.limb64.__mulo_limb64`, but it is no longer the largest cluster.
  The soft-float cluster has 180 mechanical family/diagnostic buckets across
  157 namespace families.
- First failing real row/stage beyond the enforced prefix: none known after
  the strict `--limit=100` close.
- Strict ratchet `real_*` counters:
  `real_functions_lowered=100`, `real_objects_emitted=100`,
  `real_native_linked=100`, `real_executed=0`, `real_programs_ok=1`.
- Current candidate denominator:
  `docs/evidence/real_candidates_release_v2.tsv`,
  hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`,
  selector `real-candidate-selector-v2`, Zig pin
  `bdee02bc0c7f227c0f11bc9a449df673fe803540`. The migration from selector-v1
  is recorded in `docs/evidence/real_candidates_release_v2.summary`.
- Enforcement state: `distribution-all` runs
  `src/distribution_real_rows_gate.zig --strict --limit=100` for ReleaseFast,
  ReleaseSafe, and ReleaseSmall.
- Saved log paths: `tmp/std_debug_hello_debug_report_all.log`,
  `tmp/std_debug_hello_debug_build_abs_limb64_after.log`,
  `tmp/distribution_all_after_abs_limb64.log`,
  `tmp/real_rows_strict_limit100_releasefast_after_abs_limb64.log`,
  `tmp/real_rows_strict_limit100_releasesafe_after_abs_limb64.log`,
  `tmp/real_rows_strict_limit100_releasesmall_after_abs_limb64.log`,
  `tmp/clean_tmp_fixture_pair.log`, and
  `tmp/real_rows_releasefast_after_clean_tmp.log`.
- Tracked evidence summaries:
  `docs/evidence/ziglang_pin_stage4_optional_layout.summary`,
  `docs/evidence/real_rows_releasefast_limit200_after_optional_layout.summary`,
  `docs/evidence/real_rows_releasesafe_limit100_after_intcast_safe.summary`,
  `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary`, and
  `docs/evidence/real_rows_strict_limit100_after_optional_layout_failure.summary`,
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`,
  `docs/evidence/clean_tmp.summary`, and
  `docs/evidence/std_debug_hello_compiler_rt_report_all.summary`.
- Recommended next action: do an item-15 architectural-review cycle before
  implementing the soft-float/libm/conversion cluster. The review should
  decide whether to introduce a broader generic-CFG/semantic lowering
  architecture for the 259-row soft-float cluster instead of adding many
  family-specific CFG recognizers. If the review explicitly defers soft-float,
  continue item 12 largest-actionable-cluster-first with the 66-row integer
  helper cluster, using width-plus-operation-parametric lowerings where the
  model-owned shapes match. The limb64 queue, including
  `compiler_rt.limb64.__mulo_limb64`, is now third by size with 15 rows.

When the worker stops, record only:

- active convergence-progress item (and active family, when the goal was a
  family item);
- blocked checklist item;
- exact failure or missing hook fact;
- the first failing real row and current staged `real_*` counter values,
  once the real-row gate exists;
- saved log path or tracked evidence summary path;
- recommended next action.

## Documentation Rule

Do not update this file after every successful cycle.

Update this file only when:

- the active goal is blocked;
- the next item needs a hook-contract or architectural decision;
- the worker changes active goal track (real rows / real program / family);
- the worker stops with a blocker.
