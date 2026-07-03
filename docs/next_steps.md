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

Stop state recorded 2026-07-03 after the second item 9 real-row fix:

- Active convergence-progress item: 9. This opens two active tracks:
  `distribution-real-rows --limit=25` ratchet work and the syscall-hello
  real-program track from item 11.
- Real-row track status: ReleaseFast `--limit=25` report mode now clears
  `../ziglang/src/main.zig/codegen.aarch64.legalizeFeatures` through object
  emission and native link, and clears
  `../ziglang/src/main.zig/Io.Event.reset` through typed lowering. The first
  failing row remains `../ziglang/src/main.zig/Io.Event.reset`.
- Syscall-hello track status: opened by item 9; no implementation work
  started yet.
- First failing stage: `object-emission`.
- Current staged `real_*` counters: `real_functions_lowered=23`,
  `real_objects_emitted=22`, `real_native_linked=22`, `real_executed=0`,
  `real_programs_ok=0`.
- Current candidate denominator:
  `docs/evidence/real_candidates_releasefast_v1.tsv`,
  hash
  `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`,
  selector `real-candidate-selector-v1`, Zig pin
  `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`.
- Enforcement state: `distribution-all` runs
  `distribution-real-rows --strict --limit=10`.
- Saved log path: `tmp/real_rows_limit25_after_Io_Event_reset.log`.
- Tracked evidence summary:
  `docs/evidence/real_rows_limit25_after_Io_Event_reset.summary`.
- Recommended next action: debug `Io.Event.reset` object emission with
  `ZLLVM_DEBUG_DUMP_IR_SOURCE=reset zig build distribution-real-rows -- --mode=ReleaseFast --limit=25`,
  fix the `object-emission` failure through the normal ownership chain, and
  keep the syscall-hello track open in the stop report.

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
