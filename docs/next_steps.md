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

Active family: aggregate ABI at scale.

Blocked checklist item: lower slice arguments and returns as `{ ptr, len }`
aggregates.

Exact failure: a source-backed probe that exported `[]const i32` parameters and
returns in `test/zig/frontier/frontier_slice_pointer_arith.zig` failed before
z_llvm lowering. Patched Zig rejected the source during AIR export:

```text
test/zig/frontier/frontier_slice_pointer_arith.zig:144:36: error: parameter of type '[]const i32' not allowed in function with calling convention 'x86_64_sysv'
```

Saved log: `tmp/frontier_slice_aggregate_abi.log`.

Recommended next action: do not retry exported slice signatures as C ABI rows.
Either prove slice-as-aggregate ownership through an internal helper/direct-call
shape where Zig permits `[]T`, or reclassify this checklist item as a Zig ABI
frontier separate from C ABI executable harnesses.

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
