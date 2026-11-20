# INBOX-87 O2-3B1B GEP family production migration

Status: complete and validated; delivered for Supervisor/Reviewer review.
The next production family is not authorized.

## Base, preserved work, and boundary

The accepted B1A4 production base is commit `386820c5`, tree
`e41ba9b5891be2e5266635352356d385b7bd1ce9`. The working authorization head
was the documentation-only descendant `dc1ebc97`; there was no intervening
`src`, `tools`, or `build.zig` change.

The reconciled retry carrier was checked before reuse:

```text
patch=tmp/inbox87_second_resume_perf/inbox87_second_resume_hard_stop.patch
patch_sha256=755313923184c649f044a5e18bda0d2d8cda7716367a45a82b400b6171d21d69
clean_apply_base=386820c5 production state
git_apply_check=pass
```

The B1A4 action and sequencing implementation is unchanged. This slice wires
exactly `lowerGep`, `lowerBytePointerGep`, `lowerI32ElementPointerGep`, and
`lowerReadOnlyTableGep`. Each selected leaf owns one complete
`ValueUseTransaction`: it registers all uses and the address action before
mutation, seals the plan, executes planner-derived early materialization,
preserves and materializes the remaining operands, executes the closed action,
and commits only after the complete lowering succeeds. The dispatcher does not
open a nested authority. `lowerLoad`, `lowerStore`, and
`loadStackU64IntoRax` remain outside this family.

The recorded B1A4 boundary also remains unchanged: sharing one secondary
operand across multiple prepared actions fails closed as
`ValueUseEarlyOrderingConflict`. That is unsupported multi-action composition
owned by a future reviewed slice, not an O4 copy cycle. B1B uses one action per
leaf authority and does not exercise that unsupported shape.

## Exact bypass ratchet and composition accounting

The frozen inbox81 inventory shrank by exactly 11 occurrences and no
parent-owned helper was absorbed:

```text
lowerBytePointerGep emitValueIntoScratch=3 resolveValue=1 total=4
lowerGep            emitValueIntoScratch=1 resolveValue=1 total=2
lowerI32ElementPointerGep emitValueIntoScratch=3 resolveValue=1 total=4
lowerReadOnlyTableGep emitValueIntoScratch=1 total=1
ratchet_total=11
residual_occurrences=243
inventory_sha256=d928d02a154aeda3f4cb0b2269a0c4ca40cb70cada1f539849c2ea40fddd2249
```

The seven corresponding machine-readable classification rows now name
`O2-3B1B` and `migrated_complete_*`; the four composition rows are marked
`O2-3B1B-migrated` with `current_api_fit=yes`. The source guard validates the
ratcheted inventory and rejects reintroducing the removed gateways.

## Decisive byte-identity proof

The accepted 285-row cohort was regenerated after the final production code
change:

```text
object_log=tmp/inbox87_third_resume_perf/accepted_cohort.o
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox87_third_resume_perf/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
composed_block=40
composed_cfg=127
legacy_envelope=17
structural_fallback=101
ledger=167/17/101
```

The fresh whole-cohort log is
`tmp/inbox87_third_resume_perf/b1b_full_report.log`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

None of the twelve O2 frontier targets advanced. `compiler_rt.exp.exp` and
`compiler_rt.exp.expf` retain their exact
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-gep-readonly-table-global` diagnostics. The frozen identity
tuple is exact:
`49a19f04 / 443-285-158-truncl / 061a64e4 / 5d91960e / 167-17-101`.

## Blocking performance gate

The authoritative BEFORE measurements were captured first at the accepted
B1A4 production tree, and the AFTER measurements used the same captured input,
compiled command, CPU pin (`taskset -c 0`), warmed-cache protocol, `LC_ALL=C`,
and environment. The input SHA-256 was
`7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06`.
Every warmup and measured run exited through the expected report-all failure
path, emitted no stdout, and reproduced report hash `49a19f04`.

```text
before_raw=tmp/inbox87_third_resume_perf/before_samples.raw
before_raw_sha256=52c80b9d756f1706b7d93774d344207fad708968e4b8b5acf4cf52e8ef9a8e10
before_warmup_seconds/rss_kib=48.49/95592
before_1_seconds/rss_kib=48.57/95676
before_2_seconds/rss_kib=48.36/95684
before_3_seconds/rss_kib=48.44/95684
before_4_seconds/rss_kib=48.58/95680
before_5_seconds/rss_kib=48.07/95684
before_median_seconds=48.44
before_max_rss_kib=95684

after_raw=tmp/inbox87_third_resume_perf/after_samples.raw
after_raw_sha256=a27eff69571a2cb34570028f40a207175b47731d3cff089ec32b5fcd863086d8
after_warmup_seconds/rss_kib=48.82/95812
after_1_seconds/rss_kib=48.81/95812
after_2_seconds/rss_kib=48.62/95824
after_3_seconds/rss_kib=48.91/95220
after_4_seconds/rss_kib=48.80/95892
after_5_seconds/rss_kib=48.72/95812
after_median_seconds=48.80
after_max_rss_kib=95892

median_delta_seconds=+0.36
median_stop_threshold_seconds=2.42
median_gate=pass
max_rss_delta_kib=+208
max_rss_stop_threshold_kib=16384
rss_gate=pass
```

Procedural instrumentation remained outside canonical report/gate output. It
measured the current address-domain snapshot at 149,761 bytes and observed:

```text
family=lowerGep transactions=0 snapshots=0 safe_candidates=0 early_executed=0 transactions_with_early=0 max_early=0 demoted=0
family=lowerBytePointerGep transactions=113 snapshots=113 safe_candidates=78 early_executed=78 transactions_with_early=70 max_early=2 demoted=0
family=lowerI32ElementPointerGep transactions=340 snapshots=340 safe_candidates=203 early_executed=116 transactions_with_early=61 max_early=2 demoted=87
family=lowerReadOnlyTableGep transactions=7 snapshots=7 safe_candidates=1 early_executed=1 transactions_with_early=1 max_early=1 demoted=0
total transactions=460 snapshots=460 safe_candidates=282 early_executed=195 transactions_with_early=132 max_early=2 demoted=87
max_active_nesting=1
active_at_exit=0
close_underflow=0
snapshot_bytes=149761
copy_volume_bytes=68890060
copy_volume_mib=65.698681
snapshots_per_transaction=1
```

Thus every authority took exactly one address-domain snapshot, nesting stayed
constant, and the new prefix-closure metric recorded 87 safe-early candidates
demoted to ordinary. The metric log SHA-256 is
`cb52dd439da79082dcc1f1e7d9938a021ac4e21bfa8cabc827a966a571b50f6b`;
the snapshot measurement SHA-256 is
`a838a712fa6a21bf1a665d7d99d72ced2133312145e6dc3997c129aeb164a8e8`.

## Non-Tier-3 validation

The final source state passed the complete authorized validation:

```text
full_unit=1141/1141
full_unit_log_sha256=aaac3acdcd3db5d19d202751ae452dc6a49a81ca1bbcb98d7d6c01b0936f382d
abi_differential=60/60 cases; 30/30 real functions; result=pass
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1149/1149 tests
strengthened_tier2_log_sha256=4707963180994ad56a801e8da84049a2f241477b7a0cc470d1acbfc5dd4b0cd1
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

No Tier 3 was run. Stop here for B1B review before selecting or wiring another
semantic consumer family.
