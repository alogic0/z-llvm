# INBOX-62 O0 Selection-Atomicity Stop Evidence

Status: **unaccepted; hard stop for separately authorized atomicity repair**

Directive: `INBOX-62`

Baseline: `51675de1c3ec23562763ac82bbe94712307771e8`

Date: 2026-07-15

## Outcome

The required unsupported-speculation snapshot exposed two externally visible
`MachineFunction` state leaks. O0 therefore stopped before adding the
`selection_owner` authority or owner manifest, and before Tier 2. No rollback
repair is included in this stop commit.

| Snapshotted authority | Before | After unsupported selection | Restored |
| --- | --- | --- | --- |
| `instructions` | one seeded `.ud2` | the same one `.ud2` | yes |
| `owned_labels` | one seeded label | seeded label plus speculative return-epilogue label | **no: 1 -> 2** |
| `codegen_path` | `.structural_matcher` | `.structural_matcher` | yes |
| ABI entry metadata | `entry_xmm_defined_bits[0] = 7` | `entry_xmm_defined_bits[0] = 64` | **no: 7 -> 64** |

`MachineFunction` has no separate committed frame descriptor at this baseline;
the speculative frame's instruction is covered by the instruction snapshot
and its owned return-epilogue label is covered by `owned_labels`. There is no
`selection_owner` field at the baseline. The owner authority was deliberately
not introduced after the prerequisite snapshot failed, so no speculative
owner state exists to retain or repair in this cycle.

## Reproduction

The temporary negative test called the public
`generic_cfg_selector.tryLower` authority, not the composed-selector
implementation directly. It seeded all existing externally visible mutable
fields, then used this verified IR near miss:

```llvm
target triple = "x86_64-unknown-linux-gnu"

define i128 @atomicity_near_miss(double %fp, i32 %flag) {
entry:
  %slot = alloca i64, align 8
  br label %next
next:
  %condition = icmp ne i32 %flag, 0
  %selected = select i1 %condition, i128 1, i128 2
  ret i128 %selected
}
```

This shape is intentionally speculative and unsupported:

1. binding the `double` parameter changes XMM0 entry definedness to 64 bits;
2. frame preparation emits a stack adjustment and allocates an owned shared
   return-epilogue label;
3. multi-block composition reaches the unsupported immediate-i128 select;
4. the public fail-closed wrapper returns
   `composed-block-select-width` and truncates instructions to the starting
   length;
5. the label list and XMM entry metadata remain mutated.

The temporary test was run with:

```text
zig build test -- --test-filter "generic cfg selector unsupported speculation"
```

The deterministic snapshot output was:

```text
selection_atomicity instructions=true owned_labels=false codegen_path=true abi_metadata=false labels_before=1 labels_after=2 xmm0_before=7 xmm0_after=64
```

The aggregate assertion failed as required. The remaining 1024 unit tests in
that invocation passed. The deliberately failing temporary test was then
removed; this evidence record, not a permanently red test suite, is the only
worktree change retained.

## Root Boundary

`src/codegen/x86_64/generic_cfg_selector.zig` snapshots only
`machine.instructions.items.len` in both
`tryLowerComposedBlockFailClosed` and `tryLowerComposedCfgFailClosed`. It does
not snapshot or restore `owned_labels` or `entry_xmm_defined_bits`.

The speculative mutations occur below that authority:

- `src/codegen/x86_64/generic_cfg/composed_selector_impl.zig:bindParams`
  writes `machine.entry_xmm_defined_bits` for XMM parameters;
- the multi-block path asks
  `src/codegen/x86_64/generic_cfg/composed_selector_cfg.zig` for an owned
  return-epilogue label after frame preparation;
- the fail-closed wrapper truncates the instruction list but leaves the other
  fields unchanged.

The repair must be a separately authorized transaction/atomicity slice. It
must define ownership-safe rollback for newly allocated labels (including
freeing only speculative allocations), all ABI/frame metadata, instructions,
and the future owner state on both unsupported results and mapped errors. A
post-hoc manifest or owner assignment cannot make the current selection
transaction atomic.

## Validation And Stop State

No AIR export, patched-Zig rebuild, distribution gate, Tier 2, Tier 3,
accepted-object comparison, real-program boundary, ratchet, or mandatory
summary was run or changed. Tier 2 was not eligible after the mandatory
atomicity prerequisite failed.

`INBOX-62` is acknowledged as an **unaccepted stop**. O0 has no
`selection_owner`, no per-row owner manifest, no acceptance claim, and no
report or object-byte delta. O1 and every other slice remain unstarted.
