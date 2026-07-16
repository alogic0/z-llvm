# INBOX-91 O2-3B2A dormant store action set

Status: implemented and validated; delivered for Supervisor/Reviewer review.
O2-3B2B production wiring is not authorized.

## Base and boundary

The accepted B1B production base is commit `b73ac7a7`, tree
`acddca7ed1d63e576999af7a89386e20d1792fac`. The directive arrived at
documentation-only descendant `eef93b00`; the sole intervening path is
`docs/next_steps.md`, and `git diff b73ac7a7..eef93b00 -- src tools build.zig`
is empty.

This slice changes only the dormant closed `ValueUseTransaction` action set,
its white-box tests, its source guard, the store API-fit audit, the future
B2B ratchet, and classification evidence. No store lowerer, memory consumer,
tool, mandatory runner, candidate selection, gate inventory, or frozen bypass
inventory changed.

The scope correction is explicit: `lowerStoreFp` and all FP/XMM paths remain
category 4, owned by O3. O2 store scope is exactly integer/scalar
`lowerStore`, its parent-owned `lowerStoreI64` paths, and
`lowerStoreStackPointer`. Pair, aggregate, FP/XMM, and ABI capability are not
added.

## Complete store API-fit matrix

`inbox91_o2_store_api_fit_audit.tsv` freezes every dispatcher boundary and
accepted/rejected branch for the admitted family. It records store type,
pointer and value homes, physical writes, accepted staging order, diagnostic
boundary, helper ownership, closed action, and API fit. Its SHA-256 is
`757180a3183597dcb3c3baf995127cc57afdafeda2fc22c2338b5d2ea910741a`.

The admitted accepted shapes are:

- i1 named/immediate values to an 8-bit integer stack slot;
- i32 named/immediate values through in-place GPR pointers, spilled pointers,
  stack-array bases, and stack-i32 descriptors with zero, one, or two canonical
  dependency components;
- i64 named values through GPR or spilled pointers, retaining the accepted
  pointer-before-value staging of the parent-owned helper; and
- the address of any scalar stack object stored into an aligned 64-bit integer
  stack slot.

The matrix also freezes barrier, readonly, width, address-space, alignment,
frame, unsupported source/home, readonly-table, and i64-immediate rejection
boundaries. The incidental pair/aggregate/FP switches are not widened into an
O2 capability.

## Closed typed store actions

The private action set adds four general semantic forms:

```text
store_scalar(pointer request, bits=1|32)
store_immediate(value i32, bits=1|32)
store_i64(value request)
store_stack_pointer(destination request)
```

Callers provide only typed intent and opaque handles registered before seal.
They never provide or receive a register, spill slot, stack descriptor, or
prepared location. Named scalar stores are owned by the value request, with
the pointer as semantic secondary, so i1/i32 retain value-before-address
ordering. I64 stores are owned by the pointer request, with the value as
secondary, retaining pointer-before-value ordering. Immediate intent has no
discovered source home and cannot escape as a generic scalar-immediate
materialization capability. Stack-pointer stores privately validate both
stack-object descriptors.

Every accumulator/RCX/R8 destination enters seal-time destination-conflict and
copy-cycle planning. The store variants own their ordered writes after seal,
so the existing prefix-closed planner may execute only a safe semantic prefix;
ordinary operands cannot be overtaken. Early homes are consumed without
rematerializing the original source. Genuine physical cycles still return
`ValueUseCopyCycleRequiresO4` before mutation.

Store emission remains inside the transaction authority. Store instructions
are EFLAGS-preserving. Address/index/addend arithmetic uses the emission-time
EFLAGS authority with `.write`, so a live definition rejects before the
arithmetic append and the outer snapshot rolls back every earlier stage.
Consumed operands may disappear only when the error-bearing liveness authority
proves they are dead after the instruction; a missing live operand or changed
surviving binding fails closed.

The existing snapshot owns instructions, bindings, spill state and counters,
accumulator state, EFLAGS and semantic records, labels, and address dependency
metadata. It therefore owns every compiler-visible effect of the dormant store
actions. The address domain is still copied once per instruction authority and
zero times per request.

## Focused coverage and dormant guard

The focused transaction and source-guard root passed 58/58 tests. Store
coverage includes:

- same physical register shared by distinct pointer/value aliases;
- named and immediate i1/i32 staging;
- exact value/index/addend/indexed-store semantic ordering;
- spill-backed pointer plus accumulator-resident i64 value in exact accepted
  order;
- stack-index and addend staging followed by live-EFLAGS rejection, with exact
  rollback of instructions, bindings, flags, and dependency metadata;
- stack-object pointer success and rollback after speculative address
  materialization;
- store destinations participating in conflict detection; and
- a store mapping cycle rejected before mutation by the existing O4 boundary.

The source guard rejects all four store-action tags in production consumer
files. A negative fixture proves the dormant `store_i64` tag cannot be wired.
Current-tree validation passes, and the frozen inbox81 bypass inventory remains
byte-identical:

```text
inventory_sha256=d928d02a154aeda3f4cb0b2269a0c4ca40cb70cada1f539849c2ea40fddd2249
production_store_action_wiring=none
focused_store_and_guard=58/58
focused_log=tmp/inbox91_b2a/focused_store_and_guard.log
focused_log_sha256=d17759fcd60b64a67aa22421bafa81507ed917c28bb547d63790829e1d9e6b04
```

## Frozen O2-3B2B ratchet

`inbox91_o2_store_b2b_ratchet.tsv` freezes exactly ten occurrences:

```text
lowerStore: emitValueIntoEax=1 lowerStoreI64=1 materializeLocIntoLoc=1 resolveValue=2 total=5
lowerStoreI64: emitValueIntoRax=1 materializeLocIntoLoc=2 total=3
lowerStoreStackPointer: resolveValue=2 total=2
b2b_ratchet_total=10
ratchet_sha256=761bad144a6124ec12fab0848c89192ee41c9aba60a42d2651a6c932ffc05cf3
```

The parent-owned helper occurrences collapse only with the complete
`lowerStore` authority. The separate `lowerStoreFp` inventory remains intact
and is not part of this ratchet.

## Non-Tier-3 validation

The final dormant source state passed:

```text
focused_store_and_guard=58/58
full_unit=1148/1148
full_unit_log=tmp/inbox91_b2a/full_unit.log
full_unit_log_sha256=2342c919c09e36537250700d24c4653c780f7919a5949952bb3dbcb5b5d3fe60
abi_differential_from_full_unit=60/60 cases; 30/30 real functions; result=pass
source_guard=current-tree-pass; frozen bypass inventory exact
production_store_action_wiring=none
tier3=not-run
```

The fresh post-final-code cohort report is
`tmp/inbox91_b2a/full_report.log`, generated from capture SHA-256
`7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The whole-cohort report is byte-identical to baseline. No Tier 3 was run.
Stop here for B2A review.

After B2A acceptance, B2B must recapture the authoritative five-run warmed
baseline at the accepted B2A tree, migrate the complete ten-occurrence store
family under one transaction per admitted leaf, reproduce
`061a64e4 / 49a19f04 / 5d91960e / 167-17-101`, and record per-family
transaction/snapshot/early-plan/demotion metrics under the existing blocking
performance thresholds. Branch/switch remains a later independent family.
