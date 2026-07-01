# Next Steps

This file is only for short-lived blocker and handoff notes.

The durable implementation queue is:

- `docs/roadmap/x86_64_compiler_core_family_checklist.md`

The worker cycle rules are:

- `docs/working-cycle.md`

Do not use this file as a routine progress log. Normal implementation cycles
should check off completed family items in the compiler-core family checklist
and update generated counters only when counters changed.

## Current Operating Rule

Pick the highest-priority actionable family from
`docs/roadmap/x86_64_compiler_core_family_checklist.md`, then implement one
unchecked item inside that family per cycle.

Stay in the same family until:

- the family is complete;
- refreshed inventory shows a different family is clearly higher value;
- the next item needs hook-contract or architectural review;
- validation exposes an unexpected blocker.

## Active Blocker

No active blocker is recorded here.

When the worker stops, record only:

- active family;
- blocked checklist item;
- exact failure or missing hook fact;
- saved log path;
- recommended next action.

## Documentation Rule

Do not update this file after every successful cycle.

Update this file only when:

- the active family is blocked;
- the next item needs a hook-contract or architectural decision;
- the worker changes active family;
- the worker stops with a blocker.
