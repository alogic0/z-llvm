# INBOX-105 — O2-3L-A2 dormant load diagnostic classification and precedence

Status: complete and validated; delivered for Supervisor/Reviewer review. This
slice changes only the dormant ValueUseTransaction load authority, its tests,
and the composed-selector source guard. It does not wire a load consumer and
does not authorize L-B1.

## Frozen source and scope

The accepted load-action parent is `94ab402b2c11aa6f39167dd2ad5f79734bb87fc4`
(tree `12842c7a42cdcc9736c014fa8529fb7566f6dc54`). Work began from the
Supervisor documentation-only descendant `ccceacb8dd314a7a8ca8a97eb00fce968325668b`.
No rebase or reset was used, and `stash@{0}` remains untouched.

`composed_selector_memory.zig` is byte-for-byte unchanged from `94ab402b`:

```text
consumer_sha256=5526b61f42d5aaddbfbeca6b02f7769100e38c68604611310aed0e08b2a81c7a
production_load_action_consumers=0
ratchet_before=221
ratchet_after=221
bypass_inventory_sha256=1cc1fbc62a1478008189b5e33a3ae33ae177a96ebf8d625cec537c6c0754315a
tier3=not-run
```

The INBOX-104 five-sample baseline at `94ab402b` remains retained evidence,
but it is explicitly non-authoritative for the L-B1 resume. A new five-run
baseline must be captured at the accepted L-A2 tree before production wiring.

## Closed semantic failures

`ValueUseTransaction.LoadRequestError` is a closed twelve-variant error set.
It exposes only semantic diagnostic classes: ordinary stack/array/pointer
width and rejected-home failures; readonly provenance/staging/alias/width/pair
failures; and table offset/type/staging failures. It exposes no source-home
category, `ValueLoc`, binding, register, spill slot, source identity, or retry
operation.

The action-registration width rejection was removed. A named request now
resolves canonically first, validates dependencies/liveness, and only then
classifies the load source. Every semantic failure is recorded against the
existing request handle and remains observable solely through
`failedRequestIs(handle)`. Authority-wide errors retain null provenance.

The accepted precedence is now explicit:

- ordinary: unresolved source -> home class -> the exact stack, array,
  pointer-width, or rejected-home error;
- readonly: provenance/resolution -> optional spill staging -> accumulator
  preservation -> width, so a staging failure wins over width; and
- table: address-space/allowed-offset checks -> optional spill staging ->
  shape/type, so offset wins before staging and staging wins before type.

The exhaustive semantic-error-to-diagnostic proof is test-only in L-A2. No
mapping is present in a production consumer.

## Complete 28-row proof

`docs/evidence/inbox105_o2_load_diagnostic_precedence.tsv` reconciles all 28
rows from the accepted L-A matrix with the exact phase sequence, semantic
failure, request provenance, mutation-before-failure state, and disposition.

```text
rows=28
columns=8
matrix_sha256=9b95445140220be4df3fa48114e18da17868ae71c7a0125fd0659aa558fff869
ordinary_i16_classes=4
ordinary_i16_diagnostics=stack-width/stack-array-width/ptr-width/ptr
```

Focused tests prove all four ordinary-i16 classes; unresolved-before-width;
readonly direct and spilled unsupported widths; spill-staging-before-width;
readonly rejected provenance; table offset-before-staging and
staging-before-type; existing successful direct/spill/indexed/pair/table
forms; request attribution after automatic rollback; and exact restoration of
instructions, bindings, spill counters, virtual-register counters, EFLAGS,
and durable results.

The source guard rejects a public load-home/binding query, a semantic mapping
outside `lowerLoad`, `lowerReadOnlyPointerIntegerLoad`, or
`lowerReadOnlyTableLoad`, a provenance query outside those approved sites, and
any home-switch/classification inside a mapper. The dormant action prohibition
remains active.

## Fresh validation

The final code change was formatted before the fresh validation.

```text
full_unit=1207/1207 pass
full_unit_and_abi_log=tmp/inbox105_load_diagnostics/full_unit_abi.log
full_unit_and_abi_log_sha256=97ffe903330d34372990f6e134b54fa284039ae094b6f0e72dc6c9e3c3df98d1
abi_differential=60/60 cases; 30/30 real functions; result=pass

full_report=tmp/inbox105_load_diagnostics/full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi

accepted_object=tmp/inbox105_load_diagnostics/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox105_load_diagnostics/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

Stop here for INBOX-105 review. After acceptance, L-B1 resumes from this
amendment with a newly captured authoritative performance baseline.
