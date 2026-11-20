# INBOX-117 O2-3I-A2a — dormant current-home eq-zero action

## Frozen base and scope

```text
accepted_code_commit=3e2a204a
working_head_with_supervisor_docs=8337c9359c532c274caf6612f48b8878cc666b39
working_head_tree=2f70e0e34240736dee74e670279995576cab63d5
audit_row=I13_eq_zero_current_home
production_wiring=none
production_icmp_change=none
ratchet_before=187
ratchet_after=187
performance_run=not-run
tier3=not-run
stash_at_0=untouched
```

This slice adds only the dormant closed semantic action for audit row I13.
The remaining current-home gateways are not modeled or migrated. The
production `composed_selector_icmp.zig` file and both frozen bypass
inventories are byte-identical to the accepted tree.

## Closed action and lifecycle

The public `CurrentHomeEqZeroAction` intent contains only the result identity
and semantic operand type. The named operand is referenced through its
registered request handle. No physical register, location, spill slot,
staging order, preservation policy, displacement policy, or prepared
location is exposed to a consumer.

The action executes this sequence internally:

1. Run the accepted `liveAccumulatorNameAfterCurrent` /
   `preserveLiveAccumulatorValue` preamble.
2. Rebuild the source prepared record from canonical selector state after
   that relocation.
3. Classify only the audited current homes: EAX/RAX, matching scalar
   argument/scratch registers, or `spill64`.
4. Emit the direct test, or reload a spill to RCX and test it, as the EFLAGS
   definition.
5. Call the subordinate accumulator session's
   `prepare(.preserve, .spill_live)` while preserving that definition.
6. Emit `sete` as the EFLAGS use.
7. Call `ownActionIdentity` immediately before the
   `.zeroExtending(1)` result definition, finalize the subordinate session,
   and leave the sole outer transaction to commit.

The physical behavior does not use `.reuse_source`; displacement remains the
existing `.preserve` / `.spill_live` accumulator policy. The transaction
internally owns the possible RCX and accumulator writes during planning.

Request-scoped failures distinguish:

```text
unresolved source -> composed-block-icmp-lhs
unsupported semantic/binding width -> composed-block-icmp-lhs-width
unsupported current home -> composed-block-icmp-lhs-loc
```

The `.spill128` arm is an explicit location rejection. Its current home is
never materialized, and it cannot advance any O2 target row.

## Focused proofs and source guard

The focused transaction suite covers:

- all admitted current homes: EAX, RAX, matching argument/scratch registers,
  a low-32 semantic view over an audited wider spill binding, and an i64
  spill;
- a source already resident in live EAX and live RAX, preserving it to the
  accepted scratch home and re-resolving it canonically before the test;
- a separately live prior accumulator result, preserving it before source
  classification without changing EFLAGS;
- spill reload-to-RCX ordering before the test and accumulator preparation;
- distinct unresolved, width, and location provenance mappings;
- explicit `.spill128` rejection with no instruction mutation;
- cross-instruction result lookup after outer commit and transaction
  teardown, followed by the existing zext/use;
- exact rollback after the test definition and after accumulator preparation,
  restoring instructions, bindings, spill/vreg counters, accumulator state,
  EFLAGS semantic records, labels, and address dependencies.

The source guard enforces the closed semantic intent, accepted preamble /
canonical-refresh / classify / test / prepare / `sete` / durable-definition /
finalize order, explicit admitted-home set and `.spill128` rejection, and the
absence of `.reuse_source`, prepared-location exposure, or raw resolution in
the action. It also rejects any production use of the new action/form/errors
and extends the durable-identity guard to this definition path.

Guard negatives cover physical intent smuggling, premature production wiring
in both icmp and calls consumers, reordered lifecycle phases, and a direct
transaction-local action identity passed to the durable definition.

## Frozen identities and target frontier

The fresh report input remains
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`.

```text
fresh_report=tmp/inbox117_current_home_eq0/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only input remains `tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`.

```text
accepted_object=tmp/inbox117_current_home_eq0/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox117_current_home_eq0/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

All six `.spill128` targets remain at
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-icmp-lhs-loc`:

```text
compiler_rt.floatuntidf.__floatuntidf
compiler_rt.floatuntisf.__floatuntisf
compiler_rt.floatuntihf.__floatuntihf
compiler_rt.floattidf.__floattidf
compiler_rt.floattisf.__floattisf
compiler_rt.floattihf.__floattihf
```

The target extract is
`tmp/inbox117_current_home_eq0/spill128_targets.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
The `exp`/`expf` collateral watch retains the exact
`composed-block-gep-readonly-table-global` diagnostic; its extract SHA-256 is
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`.
No O2 target advanced.

## Validation

```text
full_unit=1236/1236
full_unit_log=tmp/inbox117_current_home_eq0/full_unit.log
full_unit_log_sha256=74012c46c299ed146446ca5f7af01f1ff98a838e3517bd76e63755fd5fe73096

abi_differential=60/60 cases; 30/30 real functions; result=pass
source_guard=current-tree and focused negatives pass
git_diff_check=pass
production_icmp_diff=none
ratchet=187
tier3=not-run
```

The exact report, object, and owner identities prove that the action remains
dormant and byte-identical. INBOX-117 stops here before any I13 production
wiring or I-A2b design.
