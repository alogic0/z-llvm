# INBOX-83 O2-2 unified liveness and value-use transaction

Status: delivered for Supervisor/Reviewer review. O2-3 is not authorized.

## Frozen base and scope

The accepted production base is commit `d28a8d39`. Work resumed from the
documentation-only authorization head `acce907a`; `git diff d28a8d39..acce907a
-- src tools build.zig` is empty. O2-2 changes no mandatory runner, candidate
selection, emitter ordering, gate inventory, or public CLI contract.

This slice is baseline-byte-identical. The new multi-request authority is
exported for white-box testing but is not called by any lowering consumer.
O2-3 remains responsible for closing the frozen resolution/materialization
bypasses; O2-2 neither claims zero bypasses nor advances a frontier row.

## Part A: one liveness authority

`valueIsLiveAfterCurrent` and `valueIsLiveAtOrAfterCurrent` now delegate to one
error-bearing `valueIsLiveAtBoundary` authority with explicit
`after_current`/`at_or_after_current` boundaries. Both direct intervals and
address-dependency owner intervals use the same boundary comparison. Thus a
dependency is not live-after when its owner ends at the current position, but
is required at-or-after that same position.

Errors now propagate through `valueMustSurviveClobber`,
`liveAccumulatorName`, `liveAccumulatorNameExcept`, and their callers. A
nonempty domain with a missing plan and an owner missing its plan entry retain
the O2-1 fail-closed errors. An empty domain with no plan retains the legacy
`false` result.

Focused coverage proves both exact-position boundaries, transitive dependency
liveness through that boundary, and malformed-domain error propagation through
all accumulator-preservation callers.

## Part B: dormant multi-request authority

`ValueUseTransaction` has explicit `registering -> sealed -> prepared ->
materializing -> materialized -> committed` phases. All requests must register
before sealing; late registration and preparation before sealing fail without
selector mutation. Identical requests for one source coalesce. Incompatible
duplicates, conflicting physical destinations, and genuine register-copy
cycles are rejected during sealing; the cycle error explicitly records the O4
boundary. Safe acyclic overlap remains permitted.

Each request owns a stable inline copy of its named `ir.Value` identity and
records the expected IR type, register class, use form, and destination. There
is no caller-supplied dependency list. Named requests validate the canonical
address-dependency domain, and preparation/materialization resolve the current
location again rather than retaining the location observed at seal time.
Ephemeral staging never rebinds a source; only existing clobber preservation
may perform a genuine durable spill relocation.

The skeleton supports:

- GPR32/GPR64, EAX/RAX, and scalar spill views;
- pointer register/spill views and stack-object addresses;
- dynamic `stack_i32_ptr` descriptors with canonical index/addend edges;
- readonly-table pointers in register or spill storage;
- existing register/spill i128 pairs as strictly read-only low/high or
  high/low limb views;
- typed address-space-zero pointer `null_value`, materialized directly as zero
  without a binding, dependency edge, or relocation.

It fails closed before mutation for XMM/aggregate sources, stack-argument
destinations, new pair ownership, unsupported address forms, unresolved
sources, and type/register-class mismatches. Pair allocation, pair
preservation, result ownership, and cycle resolution remain outside O2-2.

One transaction snapshot restores instructions, bindings, spill assignments,
virtual-register/spill/edge/stack counters, stack allocation flags, accumulator
domain, EFLAGS plus semantic-record length, address dependencies, and the
preservation flag. Rollback also clears request storage/phase and closes the
transaction. Tests exercise rollback after clobbering, a live spill, and
partial emission; post-preparation re-resolution; dead/live aliases sharing a
physical register; both pair orders; phase violations; fixed-capacity
overflow; stable identity lifetime; typed null acceptance/rejection; and every
supported/rejected source family.

## Fixed capacity and copy-amplification measurement

The request store is fixed inline storage:

```text
max_requests=16
max_identity_bytes=192
```

The transaction performs exactly one whole `AddressDependencyDomain` snapshot
at `begin`, independent of request count:

```text
address_domain_snapshot_copies_per_transaction=1
address_domain_snapshot_bytes=149761
address_domain_copies_per_request=0
```

There is no request-time or materialization-time domain copy. A transaction
with one request and a transaction with sixteen requests therefore have the
same one-domain-copy cost. Capacity overflow is a fail-closed error before
mutation.

## Frozen bypass enforcement

The source guard pins
`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` at SHA-256
`1590b6d3fe37c79ed04829a74271095ab6524f6c1bdc8aaa83ceb6f174b63e54`.
It parses real Zig function bodies and checks every frozen gateway occurrence
by file, enclosing function, operation, and count. Growth inside an existing
function or in a newly introduced function is rejected; unclassified
production files remain rejected. The inventory remains the accepted O2-0 map
(91 functions, two zero-site files, 254 occurrences), not a premature
zero-bypass claim.

The new value-use authority is separately classified. Its three raw
`resolveValue` sites are function-scoped to `prepare`, `validateRequest`, and
`materializeRequest`; their total is exact. Function/callee/family-name
predicates are forbidden in both the address-dependency domain and value-use
authority. Negative fixtures prove bypass growth and the predicate rejection.

## Non-Tier-3 validation

The final code state ran the complete authorized non-Tier-3 set once:

```text
strengthened_tier2=28/28 steps
unit_tests=1117/1117
structural_smoke=8/8
combined_build_summary=1125/1125
abi_differential=60/60 cases; 30/30 real functions; result=pass
integrated_exe=7/7; local_fail=0
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
```

The fresh post-final-code cohort log is
`tmp/inbox83_full_report.log`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only projection was regenerated from the frozen 285-row input:

```text
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
composed_block=40
composed_cfg=127
legacy_envelope=17
structural_fallback=101
ledger=167/17/101
```

The frozen identity tuple is therefore exact:
`49a19f04 / 443-285-158-truncl / 061a64e4 / 5d91960e / 167-17-101`.
No Tier 3 was run. Stop for O2-2 review before O2-3.
