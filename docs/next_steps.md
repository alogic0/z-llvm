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

None.

Stop state recorded 2026-07-05 after item 12 guarded-memcpy cycle:

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
  Debug std-hello cycles lowered the model-owned guarded direct-call wrapper
  in `compiler_rt.ssp.__memmove_chk` and the guarded copy body in
  `compiler_rt.ssp.__memcpy_chk` without name admission; the focused build now
  fails at `compiler_rt.ssp.__strncat_chk` with
  `error.UnsupportedCodegenControlFlow`.
- First failing real row/stage beyond the enforced prefix: none known after
  the strict `--limit=100` close.
- Strict ratchet `real_*` counters:
  `real_functions_lowered=100`, `real_objects_emitted=100`,
  `real_native_linked=100`, `real_executed=0`, `real_programs_ok=0`.
- Current candidate denominator:
  `docs/evidence/real_candidates_release_v2.tsv`,
  hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`,
  selector `real-candidate-selector-v2`, Zig pin
  `bdee02bc0c7f227c0f11bc9a449df673fe803540`. The migration from selector-v1
  is recorded in `docs/evidence/real_candidates_release_v2.summary`.
- Enforcement state: `distribution-all` runs
  `distribution-real-rows --strict --limit=100`.
- Saved log paths: `tmp/std_debug_hello_debug_build_after_memcpy_chk.log`
  and `tmp/distribution_all_after_memcpy_chk.log`.
- Tracked evidence summaries:
  `docs/evidence/ziglang_pin_stage4_optional_layout.summary`,
  `docs/evidence/real_rows_releasefast_limit200_after_optional_layout.summary`,
  `docs/evidence/real_rows_releasesafe_limit100_after_intcast_safe.summary`,
  `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary`, and
  `docs/evidence/real_rows_strict_limit100_after_optional_layout_failure.summary`,
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`.
- Recommended next action: take tracker item 12a first (the
  `tools/clean_tmp.zig` tool plus export-cache self-pruning; full spec on
  the item) as the next cycle — `tmp/` refills with every pin bump and
  long run, so land the hygiene tool before resuming the blocker chain.
  Then continue item 12 by fixing `compiler_rt.ssp.__strncat_chk`,
  starting from `ZLLVM_DEBUG_DUMP_IR_SOURCE=__strncat_chk` on the focused
  Debug std-hello build; before fixing it alone, check whether the
  remaining ssp `_chk` wrappers share a guard/trap/body shape that one
  model-owned family lowering can cover. Keep the lowering model-owned and
  fail-closed. For remaining compiler_rt builtin families, use
  width-parametric lowerings where the model-owned shapes match, recording
  partial item-14 credit when a parametric family subsumes per-width
  special cases.

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
