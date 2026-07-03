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

Stop state recorded 2026-07-03 after the ninth item 9 real-row fix:

- Active convergence-progress item: 9. This opens two active tracks:
  `distribution-real-rows --limit=25` ratchet work and the syscall-hello
  real-program track from item 11.
- Real-row track status: ReleaseFast `--limit=25` report mode is green for
  all 25 ranked rows through typed lowering, x86_64 object emission, and
  native link. ReleaseSafe `--limit=25` report mode is now also green
  through native link. ReleaseSmall was rechecked with the cache bypassed and
  still fails before typed lowering during AIR export.
- Syscall-hello track status: opened by item 9; no implementation work
  started yet.
- First failing stage: `air-export` for
  `../ziglang/src/main.zig/math.raiseInvalid` in ReleaseSmall.
- Current staged `real_*` counters for the first failing mode:
  `real_functions_lowered=0`, `real_objects_emitted=0`,
  `real_native_linked=0`, `real_executed=0`, `real_programs_ok=0`.
- Current candidate denominator:
  `docs/evidence/real_candidates_releasefast_v1.tsv`,
  hash
  `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`,
  selector `real-candidate-selector-v1`, Zig pin
  `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`.
- Enforcement state: `distribution-all` runs
  `distribution-real-rows --strict --limit=10`.
- Saved log paths: `tmp/real_rows_limit25_after_assert_runtime.log` and
  `tmp/real_rows_limit25_releasesmall_fresh_recheck.log`.
- Tracked evidence summaries:
  `docs/evidence/real_rows_limit25_after_assert_runtime.summary` and
  `docs/evidence/real_rows_limit25_releasesmall_fresh_recheck.summary`.
- Recommended next action: debug the ReleaseSmall AIR export failure. The
  summary reports rank 1 (`math.raiseInvalid`) because descriptor validation
  fails before per-row lowering; confirm the missing or corrupt descriptor
  entry before changing lowering or codegen. Keep the syscall-hello track
  open in every stop report.

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
