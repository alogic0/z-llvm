# INBOX-101 — O2-3C0 shared O1/O2 composition foundation

Status: complete and validated; delivered for Supervisor/Reviewer review. The
foundation is dormant. No O1-composed consumer, including the fixed-destination
unary pilot, is wired by this slice.

## Frozen source and scope

The accepted memcpy-family parent is
`0294a16dbfb40d8fabde0b70da883d5de60e5738` (tree
`a512e3befcd3a89fa77f1c00d106c04f8efadefe`). The working branch also
contained Supervisor documentation-only descendants `9e066e50` and
`9ce06806`; their only diff from the accepted parent is
`docs/next_steps.md`. No branch movement, rebase, or reset was used, and
`stash@{0}` remains untouched.

Production changes are confined to the two transaction/state authorities.
Focused lifecycle tests and the source guard are the only other code changes.
There is no diff in any composed-selector consumer, mandatory runner, bypass
inventory, classification, or composition table.

## One-owner composition model

The accumulator definition implementation is now split into:

- `AccumulatorDefinitionSession`, the snapshot-free state-transition core;
- `AccumulatorDefinitionTransaction`, the unchanged standalone O1 rollback
  owner that wraps that core in its historical snapshot; and
- `ValueUseTransaction`, the sole outer rollback/commit owner when the core is
  opened as a subordinate session.

The subordinate API is obtainable only after the complete use plan is sealed.
Late registration remains rejected, and an attempt to open the session before
seal fails without mutation. The opaque session handle gives the outer
authority access to the existing prepare, call-preparation, materialize, spill,
define, and finalize semantics; it exposes no selector state or snapshot.

`commitAccumulatorSession` always rejects with
`ValueUseAccumulatorIndependentCommit`. `ValueUseTransaction.commit` rejects
with `ValueUseAccumulatorResultNotFinalized` whenever a subordinate session
was opened but its result was not finalized. Finalization installs the result
binding and accumulator-domain state speculatively; only the outer commit makes
the complete instruction authority durable.

Any subordinate error invokes the outer rollback. The first failing use
request remains owned by the outer provenance record and is still queryable
through `failedRequestIs` after rollback. The subordinate core allocates no
snapshot and has no rollback method.

## Focused lifecycle and rollback proofs

The added focused tests prove:

- registration and seal precede subordinate-session creation and mutation;
- use preparation/materialization plus accumulator prepare/define/finalize
  complete under one outer authority;
- independent subordinate commit is rejected, while outer commit is blocked
  until result finalization;
- rollback after result finalization restores instructions, bindings, spill
  assignments, PHI destinations, accumulator domain, EFLAGS and semantic
  records, durable labels, address dependencies, virtual/spill/label/stack
  counters, and retained-label pointer identity exactly once;
- a request failure after accumulator activity keeps its precise
  `failedRequestIs` provenance through automatic combined rollback; and
- the standalone O1 lifecycle retains its accepted materialization stream,
  binding, commit, and closed-transaction behavior.

The existing standalone accumulator suite also remains green in full. No O1
consumer call site changed, and the accepted-cohort object identity below is
the byte-level regression proof for all existing standalone production users.

## Snapshot and dormant guard proof

Compile-time contracts and focused assertions establish:

```text
outer_value_use_address_domain_snapshot_copies=1
outer_value_use_per_request_domain_copies=0
subordinate_accumulator_snapshot_copies=0
subordinate_accumulator_address_domain_snapshot_copies=0
measured_address_domain_snapshot_bytes=149761
snapshot_size_log=tmp/inbox101_c0/snapshot_size.log
snapshot_size_log_sha256=585d8cd59a25c2ea3f127ceb3e2c3d370268a98a48ad942009495597a1362eba
```

The source guard requires exactly one `ValueUseTransaction.Snapshot.init`
site, exactly one subordinate-session initialization, and no nested
`AccumulatorDefinitionTransaction.begin` in the use authority. It rejects all
subordinate-session calls from production consumers in C0, as well as a second
outer snapshot or direct snapshot-owning accumulator nesting.

The frozen bypass inventory is unchanged at 228 occurrences:

```text
bypass_inventory_sha256=a3cb560135662ded6f0a9abe004e9c4d2d5a5d43b4afc5c4bc666fdea0796abc
production_composition_consumers=0
ratchet_before=228
ratchet_after=228
```

## Fresh byte identities

The fresh report used
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`:

```text
full_report=tmp/inbox101_c0/full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only input remains `tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`:

```text
accepted_object=tmp/inbox101_c0/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox101_c0/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

The exact identities prove the shared-core refactor changes no existing O1 or
O2 emission, owner, diagnostic, counter, or frontier row.

## Non-Tier-3 validation

```text
full_unit=1194/1194
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log=tmp/inbox101_c0/full_unit.log
full_unit_log_sha256=a90d2a290f8a48abfed052ca93298b0339f4bfe3d4bfce6d3fa8a15b29cd47ea
source_guard=current-tree-pass; composition consumers=0
tier3=not-run
```

Stop here for INBOX-101 review. The seven-occurrence fixed-destination unary
pilot remains a separate, unauthorized follow-up until C0 is accepted.
