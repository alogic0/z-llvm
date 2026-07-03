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

Stop state recorded 2026-07-03 after the eighth item 9 real-row fix:

- Active convergence-progress item: 9. This opens two active tracks:
  `distribution-real-rows --limit=25` ratchet work and the syscall-hello
  real-program track from item 11.
- Real-row track status: ReleaseFast `--limit=25` report mode is green for
  all 25 ranked rows through typed lowering, x86_64 object emission, and
  native link. ReleaseSafe `--limit=25` report mode now lowers and emits
  objects for all 25 ranked rows; the first remaining ReleaseSafe failure is
  native-link for `../ziglang/src/main.zig/debug.SafetyLock.assertUnlocked`.
- Syscall-hello track status: opened by item 9; no implementation work
  started yet.
- First failing stage: `native-link` for
  `../ziglang/src/main.zig/debug.SafetyLock.assertUnlocked` in ReleaseSafe.
- Current staged `real_*` counters: `real_functions_lowered=25`,
  `real_objects_emitted=25`, `real_native_linked=24`, `real_executed=0`,
  `real_programs_ok=0`.
- Current candidate denominator:
  `docs/evidence/real_candidates_releasefast_v1.tsv`,
  hash
  `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`,
  selector `real-candidate-selector-v1`, Zig pin
  `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`.
- Enforcement state: `distribution-all` runs
  `distribution-real-rows --strict --limit=10`.
- Saved log path: `tmp/real_rows_limit25_after_assertUnlocked_object.log`.
- Tracked evidence summary:
  `docs/evidence/real_rows_limit25_after_assertUnlocked_object.summary`.
- Recommended next action: debug the ReleaseSafe native-link failure for
  `debug.SafetyLock.assertUnlocked`, then rerun the all-mode strict
  `distribution-real-rows --limit=25` close. ReleaseSmall also reported an
  `air-export` failure at rank 1 during the failed strict close and must be
  rechecked after the ReleaseSafe native-link fix. Keep the syscall-hello
  track open in every stop report.

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
