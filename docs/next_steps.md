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

Current operating note recorded 2026-07-09:

- Active convergence-progress item: item 15 remains pulled forward as an
  architectural migration under item 12's std-hello real-program track.
  `compiler_rt.udivmodei4.__udivei5` and
  `compiler_rt.udivmodei4.__umodei4` are recorded stage-two-boundary rows, not
  next fix targets; do not attempt them again until the remaining
  integer-helper rows have pressure data or the register-allocator slice is
  selected by the decision rule. The real-row track remains closed through item
  10 at strict `--limit=100`, but every stop report still states both tracks.
- Real-row track status: strict `distribution-real-rows --strict --limit=100`
  is green in ReleaseFast, ReleaseSafe, and ReleaseSmall, and
  `distribution-all` enforces that strict limit. Selector-v2 ReleaseFast
  report-mode `distribution-real-rows --mode=ReleaseFast --limit=200` remains
  green through typed lowering, x86_64 object emission, and native link with
  counters `real_functions_lowered=200`, `real_objects_emitted=200`,
  `real_native_linked=200`, `real_executed=0`, `real_programs_ok=0`.
- Real-program track status: item 11 syscall hello is closed by
  `docs/evidence/zig_integrated_exe_syscall_hello.summary`. Item 12 std hello
  remains open. Item 15 stage one closed 15 limb64 terminal selector routines,
  and the interrupted integer-helper work left `__udivei4` and `__umodei5` as
  validated terminal-template routines. The composed selector now also closes
  `compiler_rt.udivmod.__umodti3` as an i128 stack out-param direct-call
  wrapper and `compiler_rt.udivmod.__modti3` as a signed i128 stack out-param
  direct-call wrapper with bounded pair spills. Current item-15 accounting is
  composed-selection rows 8,
  terminal-template rows 17, stage-two-boundary rows 2, and open
  integer-helper fallback candidates 34. Pressure diagnostics:
  `compiler_rt.udivmodei4.__udivei5` records `max_live_values=16`,
  `max_spill_slots_needed=10`, `max_spill_slots_over_envelope=4`,
  `first_exceed_block=Then8.prol`, `first_exceed_boundary=live_out`,
  `first_exceed_live_values=13`, and `first_exceed_spill_slots_needed=7`;
  `compiler_rt.udivmodei4.__umodei4` records `max_live_values=21`,
  `max_spill_slots_needed=15`, `max_spill_slots_over_envelope=9`,
  `first_exceed_block=Then9.prol`, `first_exceed_boundary=live_out`,
  `first_exceed_live_values=13`, and `first_exceed_spill_slots_needed=7`.
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
  `bdee02bc0c7f227c0f11bc9a449df673fe803540`.
- Enforcement state: `distribution-all` runs
  `src/distribution_real_rows_gate.zig --strict --limit=100` for ReleaseFast,
  ReleaseSafe, and ReleaseSmall.
- Saved log paths: `tmp/std_debug_hello_udivei5_pressure.log`,
  `tmp/std_debug_hello_umodei4_pressure.log`,
  `tmp/std_debug_hello_debug_umodti3_composed.log`, and
  `tmp/std_debug_hello_debug_modti3_composed.log`; latest distribution-all
  proof path is `tmp/distribution_all_after_modti3_composed.log`.
- Tracked evidence: `docs/evidence/std_debug_hello_udivei5_pressure.tsv` and
  `docs/evidence/std_debug_hello_umodei4_pressure.tsv`;
  `docs/evidence/std_debug_hello_umodti3_composed.summary`; and
  `docs/evidence/std_debug_hello_modti3_composed.summary`.
- Recommended next action: continue the remaining integer-helper rows in rank
  order through composed selection. Keep the intervening
  `compiler_rt.udivmod.__udivmodti4`, `__divti3`, and `__udivti3`
  `UnsupportedTailCallAbi` rows in the separate ABI family; the next active
  composed-selector integer-helper candidate is
  `compiler_rt.mulXi3.__mulsi3`. Record for every row whether it fits the
  current envelope and, if not, its live-value count. If five or more remaining
  rows hit the pressure boundary, the next major slice is the reviewed real
  register allocator with `__udivei5` as the acceptance row; otherwise revisit
  the two `udivmodei4` pressure rows as outliers after the bucket. Keep
  terminal routines frozen and keep the 44 `UnsupportedTailCallAbi` rows as a
  separate ABI family.

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
