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

Item 15 stage-two pressure blocker. The same row,
`compiler_rt.udivmodei4.__udivei5`, has failed three consecutive fix attempts
without leaving `no_spill_envelope` / `stage2-register-pressure`:
unsigned div/rem instruction support moved it to the pressure boundary, then
stack-object pressure exemption and the bounded spill-frame slice both left it
at the same boundary. Stop here per the hard-stop rule; do not template the row.

Stop state recorded 2026-07-09:

- Active convergence-progress item: item 15 is pulled forward as an
  architectural migration under item 12's std-hello real-program track. The
  real-row track remains closed through item 10 at strict `--limit=100`, but
  every stop report still states both tracks.
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
  validated terminal-template routines. Current item-15 accounting is
  composed-selection rows 6, terminal-template rows 17, and open
  integer-helper fallback candidates 37. The latest focused report-all run
  selected 443 compiler_rt functions, emitted 126, and reported 317 failures
  before failing closed with no object output. The first failing function is
  `compiler_rt.udivmodei4.__udivei5` at selector tag/detail
  `no_spill_envelope` / `stage2-register-pressure`.
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
- Saved log paths: `tmp/std_debug_hello_debug_stage2_spill_frame.log` and
  `tmp/distribution_all_after_stage2_spill_frame.log`.
- Tracked evidence summary:
  `docs/evidence/std_debug_hello_stage2_spill_frame.summary`.
- Recommended next action: review the item-15 stage-two pressure design before
  making another `__udivei5` fix attempt. The next implementation slice should
  add explicit pressure diagnostics and a real liveness-driven spill plan for
  high-pressure multi-loop functions with large stack-array payloads, then
  resume composed selection. Keep terminal routines prohibited for this row,
  keep recognizers as fallback only, and keep the 44 `UnsupportedTailCallAbi`
  rows as a separate ABI family.

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
