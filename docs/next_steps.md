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

Mid-cycle stop recorded 2026-07-02 by the docs/verification agent (the
worker stopped without reporting).

- Active convergence-progress item: pre-adoption family work (family 10,
  packed aggregates) — checklist item "Implement common aligned packed
  aggregate call arguments". Note: this cycle began before the convergence
  plan adoption commit (f860ba86); after finishing it, goal selection must
  switch to `docs/roadmap/convergence_progress.md` (next item: 2, evidence
  tooling).
- Modified files (uncommitted, intentional, keep):
  `test/zig/frontier/frontier_sysv_aggregate_classes.zig` (adds
  `helperPackedMixedHigh` + `frontier_packed_mixed_call_high`) and
  `test/zig/harnesses/frontier_frontier_sysv_aggregate_classes.c` (extern +
  check, exit code 28).
- Exact failure: the new row is functionally green — ReleaseFast reports
  `discovered_functions=755`, `executable_ok_rows=14`, `local_fail=0`,
  `object_failures=0` — but the strict finish gate fails on the count:
  `strict-finish-failure mode=ReleaseFast field=discovered_functions
  expected=753 actual=755`. The strict finish expectations were not yet
  bumped for the 2 added functions.
- Saved log path: `tmp/frontier_packed_call_arg.log`.
- Recommended next action: bump the strict finish count (`.functions = 753`
  -> `755`, `src/uncurated_air_gate_helpers.zig:237`), re-run the
  all-release-modes frontier gate, check off the family checklist item,
  commit, then select the next goal from
  `docs/roadmap/convergence_progress.md`.

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
