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

None. The item-15 architectural review was approved and recorded; proceed with
the item-15 migration order before soft-float implementation.

Stop state recorded 2026-07-08 after the interrupted item-15 `__umodei5`
terminal-template cycle:

- Active convergence-progress item: item 15 is pulled forward as an
  architectural migration under item 12's std-hello real-program track. The
  real-row track closed item 10 at strict `--limit=100`, but every stop report
  still states both tracks.
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
  prints `hello\n` and exits 0. Item 12 std hello remains open. The item-15
  architectural review split the Debug std-hello compiler_rt report-all
  inventory into selector/codegen buckets and an ordinary ABI bucket:
  soft-float/libm/conversion selector candidates 236 rows, integer helper
  selector candidates 45 rows, tail-call ABI 44 rows, and limb64 loops 15
  rows. Item-15 stage one has now closed the limb64 selector bucket: 15/15
  limb64 rows emit through the opt-in selector path, 0 limb64 rows use
  recognizer fallback for the migrated bucket, and 0 no-spill envelope
  rejections were introduced. The current interrupted cycle also closed
  `compiler_rt.udivmodei4.__umodei5` as a validated terminal-template routine,
  after the previously committed `__udivei4` template. These closures stand but
  are not composed per-instruction selection. Current item-15 accounting is
  composed-selection rows 0, terminal-template rows 17 (15 limb64 plus
  `__udivei4` and `__umodei5`), and open integer-helper fallback candidates 43.
  The latest focused report-all run selected 443 compiler_rt functions, emitted
  120, and reported 323 failures before failing closed with no object output.
  The next first failing function is `compiler_rt.udivmodei4.__udivei5`.
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
  `tmp/std_debug_hello_debug_addsub_selector_after.log`,
  `tmp/std_debug_hello_debug_umodei5_selector_after.log`,
  `tmp/distribution_all_after_umodei5_selector_rerun.log`,
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
- Recommended next action: do not template more rows. Continue item 15 by
  implementing block-local per-instruction selection with operand and register
  assignment, then prove it on one real remaining integer row, starting at
  `compiler_rt.udivmodei4.__udivei5` unless a simpler remaining row is selected
  first. The proof must be composed selection, with no terminal byte spans and
  no whole-function envelope. If that immediately requires liveness or spill
  handling, record it as the item-15 stage-two trigger and begin stage two per
  the design note. Keep existing shape recognizers as transitional fallback and
  ratchet `shape_recognizer_functions` toward zero on the real-program gate.
  Treat the 44 `UnsupportedTailCallAbi` rows as a separate ordinary ABI family,
  not a selector concern. `distribution-all` must stay green before every
  commit; if captured rows regress, use the loop-sum bisect discipline.

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
