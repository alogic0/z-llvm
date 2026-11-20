# INBOX-113 — dormant scratch-compare durable-identity repair

## Scope and frozen base

INBOX-113 repairs the lifetime defect found by the hard-stopped I-B1 wiring
attempt. The code base is accepted I-A1 commit `bd223c83` plus Supervisor
documentation commits; the source repair is based on the unchanged I-A1
transaction implementation.

This slice changes only:

- `composed_selector_value_use_transaction.zig`;
- its focused tests;
- the composed-selector source guard; and
- this evidence summary.

`composed_selector_icmp.zig` is byte-identical to accepted I-A1:

```text
composed_selector_icmp_sha256=8d96a4c345f47ebf3393cf04a02df7f80d048f3d06287448c04bf247472cff4c
production_icmp_changed=0
textual_bypass_ratchet=216 (unchanged)
bypass_inventory_sha256=c5cf3caa4f4edfc715d8e139d736b399a4fb0b70a82b82f17af182ec88aace3e
```

The stopped I-B1 consumer wiring remains unapplied and preserved at:

```text
patch=tmp/inbox112_icmp_scratch_perf/inbox112_i_b1_hard_stop.patch
patch_sha256=78f75c9c2696885621a3e57ca363891fc5b7d739beaefb9efe19a41768c3a3b9
patch_applied_in_inbox113=0
```

`stash@{0}` remains untouched.

## Repair and ordering

The scratch-compare action now calls `ownActionIdentity` after setcc and
immediately before the subordinate accumulator definition. Only the resulting
allocator-owned slice is passed to `session.define`. The helper first duplicates
the bytes, then appends the owned entry with an `errdefer` on the duplicate.
Consequently:

- allocation failure occurs before any definition or binding;
- failure to append ownership frees the duplicate locally;
- every later action failure is covered by the one outer transaction snapshot;
  and
- commit retains the owned identity for the lifetime of the selector map.

The action's public intent, semantic classification, staging order, EFLAGS
sequence, and accumulator definition remain unchanged.

## Identity-flow audit

Every I-A1 scratch-compare output and every `ActionIdentity.slice()` path in
the value-use authority was audited.

| Flow | Lifetime/disposition |
| --- | --- |
| Scratch compare result | Repaired: `ownActionIdentity` precedes `session.define`; no direct action slice reaches the selector map. |
| Readonly-pointer pair result | Already calls `ownActionIdentity` before `bindResultLoc`. |
| Stack-i128 alias result | Already calls `ownActionIdentity` before `bindResultLoc`. |
| Table-i16 result | Already calls `ownActionIdentity` before `bindResultLoc`. |
| Byte-address result | Already calls `ownActionIdentity` before any durable bind. |
| Scaled-address result | Already calls `ownActionIdentity`; named index/addend identities use `ownRegisteredOperandName`. |
| Readonly-table address result and symbol | Both already call `ownActionIdentity` before durable binding/instruction retention. |
| `ActionIdentity.slice()` inside `ownActionIdentity` | Safe: it is only the source of the allocator duplication and never becomes a durable key directly. |
| `Identity.slice()` request-source uses | Transaction-local lookup/validation/materialization only; never inserted as a new durable selector key. |
| `PreparedIdentity.slice()` descriptor uses | Opaque prepared-view reconstruction only; closed actions own any identity before durable binding. |

The source guard rejects any `.result.slice()` flow, requires the exact
scratch-compare ownership helper before definition, and rejects missing or
reversed ownership/definition ordering.

## Focused lifecycle proof

The production-shaped cross-instruction regression performs the exact
`__mulosi4` sequence:

```text
%7 = icmp ult i64 %lhs, -4294967296
%spec.store.select = zext i1 %7 to i32
```

The compare commits, its outer transaction deinitializes, `%7` still resolves
to EAX, and the following real scalar-cast lowering consumes it. The asserted
stream is:

```text
mov rdi -> rcx
cmp rcx, -4294967296
setb eax
and eax, 1
```

An induced failure on the identity allocation proves no binding, no owned
entry, no successful allocation, and no leak. Separate failures after identity
ownership, after definition, and after finalization each observe exactly one
identity allocation and exactly one deallocation, an empty owned-entry list,
and no result binding. The standard testing allocator additionally detects any
leak or double free.

## Validation and frozen identities

```text
full_unit=1224/1224
full_unit_log=tmp/inbox113_scratch_identity/full_unit.log
full_unit_log_sha256=5c6a69f9aa0385e3beaddf2d49f5f0d3b6cf4916d6b12a50655ec3dd7a8fc3ea

abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox113_scratch_identity/abi_differential.log
abi_log_sha256=b052e67cf014d4ff03dbc37f37b4dd2e21a3b39d9c8cba271b37108d56ccd30f

fresh_report=tmp/inbox113_scratch_identity/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object=tmp/inbox113_scratch_identity/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox113_scratch_identity/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

The fresh report, accepted object, and owner manifest are each byte-identical
to the accepted I-A1 evidence. No performance run and no Tier 3 were run.
INBOX-113 stops here before resuming any fixed-scratch ICMP consumer wiring.
