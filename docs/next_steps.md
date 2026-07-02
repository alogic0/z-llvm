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

Stop state recorded 2026-07-02 after convergence-progress item 5:

- Active convergence-progress item: 6,
  `distribution-real-rows --limit=1` gate exists and is wired into
  `distribution-all`.
- Current staged `real_*` counters: unopened (`real_functions_lowered=-`,
  `real_objects_emitted=-`, `real_native_linked=-`, `real_executed=-`,
  `real_programs_ok=-`).
- Current candidate denominator:
  `docs/evidence/real_candidates_releasefast_v1.tsv`,
  hash
  `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`,
  selector `real-candidate-selector-v1`, Zig pin
  `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`.
- Current inventory counter:
  `unsupported_functions (ReleaseFast, compiler-core-module)=55479`, cited
  by `docs/evidence/real_candidates_releasefast_v1.summary`.
- Recommended next action: implement item 6 using the ranked candidate file
  as the denominator for the first `distribution-real-rows --limit=1` gate.

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
