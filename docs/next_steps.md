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

Stop state recorded 2026-07-06 after atomic fetch-and cycle:

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
  in `compiler_rt.ssp.__memmove_chk`, the guarded copy body in
  `compiler_rt.ssp.__memcpy_chk`, and the checked string append bodies in
  `compiler_rt.ssp.__strncat_chk` and `compiler_rt.ssp.__strcat_chk`
  without name admission; the checked string copy family in
  `compiler_rt.ssp.__strncpy_chk` and `compiler_rt.ssp.__strcpy_chk` is also
  lowered without name admission; the noreturn trap stub in
  `compiler_rt.ssp.__chk_fail` is lowered without name admission; the
  unguarded byte-copy fast family in `compiler_rt.memmove.memmoveFast` and
  `compiler_rt.memcpy.memcpyFast` is lowered without name admission; the
  naked stack-probe inline-asm/unreachable body in
  `compiler_rt.stack_probe.zig_probe_stack` is lowered without name
  admission; the spinlock-protected variable memcpy shape in
  `compiler_rt.atomics.__atomic_load` is lowered without name admission; the
  atomic compare-exchange family in
  `compiler_rt.atomics.__atomic_compare_exchange_{1,2,4,8,16}` is lowered
  without name admission using scalar `cmpxchg` and i128 spinlock shapes; the
  atomic exchange family in `compiler_rt.atomics.__atomic_exchange_{1,2,4,8,16}`
  is lowered without name admission using scalar `atomicrmw xchg` and i128
  spinlock shapes; the atomic store family in
  `compiler_rt.atomics.__atomic_store_{1,2,4,8,16}` is lowered without name
  admission using scalar seq_cst `xchg` and i128 spinlock shapes; the atomic
  load family in `compiler_rt.atomics.__atomic_load_{1,2,4,8,16}` is lowered
  without name admission using scalar seq_cst loads and i128 spinlock shapes;
  the atomic fetch unsigned-min family in
  `compiler_rt.atomics.__atomic_fetch_umin_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around `llvm.umin.i128`; the atomic fetch unsigned-max family in
  `compiler_rt.atomics.__atomic_fetch_umax_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around `llvm.umax.i128`; the atomic fetch NAND family in
  `compiler_rt.atomics.__atomic_fetch_nand_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around the `and`/`xor -1` update; the atomic fetch XOR family in
  `compiler_rt.atomics.__atomic_fetch_xor_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around the `xor` update; the atomic fetch OR family in
  `compiler_rt.atomics.__atomic_fetch_or_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around the `or` update; the atomic fetch AND family in
  `compiler_rt.atomics.__atomic_fetch_and_{1,2,4,8,16}` is lowered without
  name admission using scalar seq_cst `cmpxchg` loops and an i128 spinlock
  shape around the `and` update; item 12a added tmp/cache hygiene between the
  copy and string-append fixes. The focused build now fails at
  `compiler_rt.atomics.__atomic_fetch_sub_16` with
  `error.UnsupportedCodegenControlFlow`.
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
  `distribution-real-rows --strict --limit=100`.
- Saved log paths: `tmp/std_debug_hello_debug_build_after_fetch_and.log`,
  `tmp/distribution_all_after_fetch_and.log`,
  `tmp/clean_tmp_fixture_pair.log`, and
  `tmp/real_rows_releasefast_after_clean_tmp.log`.
- Tracked evidence summaries:
  `docs/evidence/ziglang_pin_stage4_optional_layout.summary`,
  `docs/evidence/real_rows_releasefast_limit200_after_optional_layout.summary`,
  `docs/evidence/real_rows_releasesafe_limit100_after_intcast_safe.summary`,
  `docs/evidence/real_rows_strict_limit100_after_intcast_safe.summary`, and
  `docs/evidence/real_rows_strict_limit100_after_optional_layout_failure.summary`,
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`, and
  `docs/evidence/clean_tmp.summary`.
- Recommended next action: continue item 12 by fixing
  `compiler_rt.atomics.__atomic_fetch_sub_16`, starting from
  `ZLLVM_DEBUG_DUMP_IR_SOURCE=__atomic_fetch_sub_16` on the focused
  Debug std-hello build. The current diagnostic is
  `error.UnsupportedCodegenControlFlow`; check whether the remaining
  compiler_rt atomic fetch wrappers share one model-owned family shape, and
  keep unsupported variants fail-closed. For remaining compiler_rt builtin
  families, use width-parametric lowerings where the model-owned shapes match,
  recording partial item-14 credit when a parametric family subsumes per-width
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
