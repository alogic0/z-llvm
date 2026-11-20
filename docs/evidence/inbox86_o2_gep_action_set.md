# INBOX-86 O2-3B1A dormant GEP action set

Status: implemented and validated; delivered for Supervisor/Reviewer review.
O2-3B1B is not authorized and no production consumer is wired.

## Base and boundary

The accepted B0 code base is commit `7779d4de2cd153617b3bc22f59987df008321c35`,
tree `9ede63b37d24e17283188f6829ae4a2e0f3310a6`. The authorization was
received at documentation-only descendant `57e6b0840f16b646a5e9f50f647b689247c4b6ff`,
tree `22482ce5a7b79e0647ba4eba9d74273363450443`; the only intervening path is
`docs/next_steps.md`. `git diff 7779d4de..57e6b084 -- src tools build.zig`
is empty, so B1A is based on the exact accepted B0 production state.

This slice changes only the dormant `ValueUseTransaction`, its white-box
tests, its source guard, and this evidence. No composed-selector consumer
imports or invokes the new address actions. No memory lowerer, emitter route,
tool, mandatory runner, bypass inventory, ratchet count, or gate changed.

## Closed semantic action set

The closed `PreparedAction` set now contains three general address-forming
actions:

- byte-address formation with a semantic constant offset or a previously
  registered request handle;
- scaled-address formation with a semantic scale and constant index/offset or
  a previously registered request handle;
- readonly-table address formation with a semantic symbol, table shape, and
  scale.

Each action also carries an inline-owned result identity. Identity capacity is
192 bytes and empty/oversize identities fail at registration. Descriptors
contain no discovered register, spill slot, `ValueLoc`, or private prepared
representation. Multi-source operands use opaque `RequestHandle`s that must
refer to earlier `prepared_source` requests in the same transaction and
generation. Foreign, late, missing, or non-source handles fail before
mutation.

`prepared_source` records are private and cannot produce a public lease. The
action authority validates and resolves every owner and operand from canonical
selector state after transaction preparation, then re-derives them after the
action as defense in depth. Callers provide intent only; the authority chooses
all physical moves and instruction forms internally.

## Seal planning and transactional ownership

Seal derives each action's complete physical destination set from the sealed
semantic action plus the source form. The sets cover RCX/R8 staging, scaled
indexing, table-base formation, and descriptor-only paths with no physical
write. They enter the existing destination-conflict, preservation, and copy
cycle graph before mutation. The focused negatives prove that a second RCX
writer is rejected and that the genuine RCX-to-R8/R8-to-RCX multi-source cycle
still returns the O4-boundary diagnostic.

Fixed materializations still finish first. Address actions then resolve their
current homes internally and can form:

- constant or named stack-array descriptors;
- constant or named byte-pointer addresses;
- constant or named scaled i32-element addresses;
- readonly-table addresses with owned symbol/shape metadata.

Durable result bindings, dependency identities, and table symbols are copied
into transaction-owned `MachineFunction.owned_labels` storage. The existing
snapshot owns their lifetime. On failure or explicit rollback it truncates
speculative instructions first, frees after-snapshot owned identities exactly
once, restores bindings and the canonical address-dependency domain, and
restores every other transaction field. Commit retains the binding and owned
identities. A multi-source EFLAGS rejection after staging proves partial
emission and all durable state roll back atomically.

The address domain remains copied exactly once at authority begin:

```text
address_domain_snapshot_copies_per_transaction=1
address_domain_snapshot_bytes=149761
address_domain_copies_per_request=0
```

No request registration, seal mapping, canonical re-resolution, or action
execution copies the whole domain.

## Guard and focused coverage

`validate_shape` remains available to white-box tests but the production
consumer guard now rejects any `.validate_shape` action use. The existing
guards continue to reject function/family predicates, private prepared-view
escapes, callbacks, raw resolution/materialization near a closed action, and
growth in the frozen inbox81 bypass inventory.

The focused transaction plus guard root passed 40/40 tests. New coverage
includes named and constant stack-array descriptor derivation, constant and
named byte offsets, spill-backed scaled indexing, readonly-table formation,
seal-time destination conflict and genuine-cycle rejection, invalid semantic
identity rejection, multi-source partial-emission rollback, result/dependency
binding rollback, owned-symbol commit, and the production `validate_shape`
negative. Current-tree source-guard validation passes with the frozen bypass
inventory unchanged.

## Non-Tier-3 validation

The final code state passed the authorized validation:

```text
focused_value_use_and_guard=40/40
full_unit=1129/1129
abi_differential=60/60 cases; 30/30 real functions; result=pass
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
integrated_exe=7/7; local_fail=0
strengthened_tier2=28/28 steps; 1137/1137 tests
source_guard=current-tree-pass; frozen-bypass-inventory-exact
production_consumer_wiring=none
```

The fresh post-final-code cohort log is `tmp/inbox86_b1a_full_report.log`:

```text
capture_sha256=7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The report is byte-identical to the accepted baseline. No production path can
reach the new actions, so the accepted object/owner projection remains frozen
by construction. No Tier 3 was run.

## Recorded sequel — not executed

After B1A acceptance, B1B is limited to `lowerGep`,
`lowerBytePointerGep`, `lowerI32ElementPointerGep`, and
`lowerReadOnlyTableGep`: exactly 11 bypass occurrences, one transaction per
selected path, no dispatcher/delegate nesting, and no target-row advance.
`exp`/`expf` remain exact collateral watches. The blocking performance gate
must take at least five warmed BEFORE samples at the accepted B1A tree and
matched AFTER samples at B1B, recording dynamic transaction/snapshot/copy
counts, median selector wall time, and maximum RSS. Stop thresholds remain
`max(5%, 100 ms)`, `+16 MiB`, nonconstant nesting, or more than one address
domain snapshot per instruction authority.

Stop here for B1A review. B1B has not started.
