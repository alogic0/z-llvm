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

Stop state recorded 2026-07-03 after item 9 strict close:

- Active convergence-progress items: 9a on the real-row track and 11 on the
  syscall-hello real-program track. Single-worker mode still applies, but
  every stop report must state both tracks.
- Real-row track status: selector-v2 `distribution-real-rows --strict
  --limit=25` is green in ReleaseFast, ReleaseSafe, and ReleaseSmall through
  typed lowering, x86_64 object emission, and native link.
- Syscall-hello track status: opened by item 9; no implementation work
  started yet.
- First failing real row/stage: none for the enforced limit-25 prefix.
- Current staged `real_*` counters:
  `real_functions_lowered=25`, `real_objects_emitted=25`,
  `real_native_linked=25`, `real_executed=0`, `real_programs_ok=0`.
- Current candidate denominator:
  `docs/evidence/real_candidates_release_v2.tsv`,
  hash
  `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`,
  selector `real-candidate-selector-v2`, Zig pin
  `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`. The migration from selector-v1
  is recorded in `docs/evidence/real_candidates_release_v2.summary`.
- Enforcement state: `distribution-all` runs
  `distribution-real-rows --strict --limit=25`.
- Saved log path: `tmp/real_rows_strict_limit25_v2.log`.
- Tracked evidence summary:
  `docs/evidence/real_rows_strict_limit25_v2.summary`.
- Recommended next action: run the item 9a wide report-mode discovery
  (`--limit=200`, ReleaseFast), populate the Cluster Board from the resulting
  clusters, and keep the syscall-hello item 11 track open in the stop report.

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
