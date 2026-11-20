# INBOX-85 O2-3B0 dormant value-use structural amendments

Status: corrected by the final prepared-view escape closure and delivered for
Supervisor/Reviewer review. O2-3B1 is not authorized.

## Base and boundary

The accepted O2-3A code base is commit `9bc7e4de`, tree
`f561a0d03d9c56756f3a19dd496c390f35af9d45`. Work began at the
documentation-only authorization head `74ae5bb8`; its tree differs only in
documentation, and `git diff 9bc7e4de..74ae5bb8 -- src tools build.zig` is
empty.

This slice changes only the dormant `ValueUseTransaction`, its white-box
tests, its source guard, and this evidence. No composed-selector consumer calls
the new APIs. No emitter route, mandatory runner, tool, gate inventory, or
candidate identity changed.

## Same-source multi-destination requests

Registration now returns an opaque transaction-local `RequestHandle`.
Requests with the same source/type/form and the same destination coalesce;
requests with the same source/type/form and distinct destinations remain
separate. Different types or forms for one source remain incompatible. Seal
still rejects physical destination conflicts and genuine copy cycles before
mutation with the existing O4-boundary error.

The physical write set remains a boolean set, so preservation/clobbering runs
once per physical source/register. Every separate request resolves the source
again after preparation. Focused coverage forces one shared source to spill
once and then materialize to two destinations from the relocated canonical
home.

## Restricted prepared views and lifetime correction

`Destination.prepared_view` requests carry a closed `PreparedAction` intent
registered before seal. The action's physical destination therefore
participates in the same conflict, preservation, and copy-cycle planning as a
fixed request. Fixed-destination materializations complete first; only then
does the authority resolve private prepared records from canonical state. A
capability is available only through its request handle after `materializeAll`.

The internal, private `PreparedView` union contains only:

- register (GPR32/GPR64/EAX/RAX);
- scalar spill;
- stack object;
- typed address descriptor with inline-owned dependency identities;
- readonly table pointer with inline-owned symbol identity and register/spill
  storage;
- strictly read-only ordered pair limbs in registers or spills.

It is never returned, passed to a callback, or named by a production consumer.
The public API returns only a phase-bound lease. `executePreparedAction` takes
only that lease; it receives no generic consumer and crosses no private-view
pointer over the public API. The currently closed, general typed action forms
are shape validation and copy emission to a typed GPR/EAX/RAX destination.
The authority itself selects and emits the instruction form from the private
view. Every execution checks the lease generation, re-resolves the source,
and revalidates the expected type/register class, supported source form,
liveness, and canonical address-dependency closure at the point of use.

The transaction stores a private canonical record containing the source vreg,
the restricted representation, and vregs/homes for address dependencies.
Before executing the closed action it compares a freshly resolved record with
that canonical record. A relocation or rebind therefore returns
`ValueUsePreparedViewStale` before internal emission. It performs the same
comparison after action execution as defense in depth, so any internal source
mutation rolls back the complete authority including speculative emission.
Successful execution consumes the request capability. There is no public or
generic callback and no public/manual invalidation API. Phase, missing,
foreign, reused, relocated, and rebound capabilities fail closed.

The source guard now permits the one raw resolution authority only in
`resolveNamedCurrent` and keeps the total exact at one. It also rejects every
frozen raw resolution/materialization gateway, accumulator binding/clobber,
or spill helper inside a consumer function that obtains/executes a prepared
action. It also rejects reintroducing a public prepared-location union, a
returning `readPreparedView`, the old generic `consumePreparedView`, an
external `consume(..., view: anytype)` escape, a private-view pointer in a
public signature, a manual invalidation API, or a production consumer
naming/retaining/directly inspecting a prepared-location value.
The frozen inbox81 bypass inventory remains exact; it does not claim zero
bypasses.

## Owned-label rollback

The transaction snapshot records `MachineFunction.owned_labels.items.len`.
Rollback performs the required order:

1. truncate speculative instructions;
2. free every after-snapshot label exactly once;
3. truncate the owned-label list;
4. restore the edge-label counter with the remaining selector state.

Commit retains labels. The allocator-backed tests use multiple speculative
labels, partial emission, a failure after prepared-view exposure, explicit
rollback, and commit. They verify the retained pre-transaction label pointer
identity, instruction/list/counter restoration, and allocator-clean
free/deinit behavior.

## Capacity and copy amplification

The request and prepared-view stores are fixed inline arrays with capacity 16;
named identities are copied into fixed 192-byte inline storage. The address
domain remains copied exactly once at transaction begin:

```text
address_domain_snapshot_copies_per_transaction=1
address_domain_snapshot_bytes=149761
address_domain_copies_per_request=0
```

No request registration, prepared-view construction, or prepared-action
execution copies the whole domain.

## Final escape-closure proof

The first lifetime correction is commit `58a6d65a`. The follow-up-2 working
authorization head is a documentation-only descendant; its `src`, `tools`,
and `build.zig` state was byte-identical to `58a6d65a` before this correction.

The production-path negative registers a typed `emit_copy_to(.rax)` action,
acquires its capability for a source in RDI, and uses the real
`selector_state.bindValueLoc` authority to relocate that source to RSI.
Execution returns `ValueUsePreparedViewStale` before internal emission; the
instruction count remains zero and rollback restores the original RDI
binding. The same action on an unchanged source emits the expected
`mov_arg_rax(.rdi)` internally, returns no location, and a second execution of
the consumed capability fails closed and rolls the speculative instruction
back.

## Non-Tier-3 validation

The original B0 code state passed the complete authorized validation:

```text
full_unit=1124/1124
structural_smoke=8/8
strengthened_tier2=28/28 steps; 1132/1132 tests
abi_differential=60/60 cases; 30/30 real functions; result=pass
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
integrated_exe=7/7; local_fail=0
```

The final escape closure passed its bounded validation after the final code
change:

```text
escape_closure_value_use_focused=17/17
escape_closure_source_guard_focused=18/18
escape_closure_full_unit=1124/1124
escape_closure_source_guard=current-tree-pass; frozen-bypass-inventory-exact
escape_closure_production_consumer_wiring=none
```

The fresh post-escape-closure whole-cohort log is
`tmp/inbox85_followup2_full_report.log`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted projection regenerated from the frozen 285-row input remains:

```text
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
composed_block=40
composed_cfg=127
legacy_envelope=17
structural_fallback=101
ledger=167/17/101
```

The frozen identity tuple is exact:
`49a19f04 / 443-285-158-truncl / 061a64e4 / 5d91960e / 167-17-101`.
No Tier 3 was run. Stop for O2-3B0 review before any O2-3B1 consumer wiring.
