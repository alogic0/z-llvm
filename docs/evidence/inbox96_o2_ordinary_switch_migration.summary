# INBOX-96 — O2-3B3C ordinary non-PHI switch migration

Status: delivered for review; no memcpy action or consumer wiring is included.

## Frozen source and scope

The accepted B3B parent is `cd7b6ee9d282cfb3cacffd61cf4196cf413d3a11`
(tree `39886418f62db2908ac2ea03fa969a87829f7336`). The working branch already
contained the Supervisor documentation-only descendants `8b83b22a` and
`f632a103`; their only diff from B3B is `docs/next_steps.md`. No branch movement
or destructive worktree operation was used, and `stash@{0}` was not inspected,
applied, or dropped.

Only the ordinary non-PHI branch of `lowerSwitch` now uses the frozen B3A
`switch_compare_chain` action. Every exact or rejected PHI-switch shape is
dispatched before the transaction begins. One instruction-level authority
copies the already validated semantic case/default identities into its fixed
descriptor, registers the condition, seals, performs the framed spill or
unframed PHI restoration, resolves the condition afterward, prepares,
materializes, executes the complete compare chain, and commits.

The transaction/action/sequencing implementation has no diff from B3B. The
consumer preserves the old phase-specific diagnostics:

- condition resolution/materialization failures remain
  `unsupported_value/stage2-switch-cond`;
- framed preservation failures remain
  `no_spill_envelope/stage2-cfg-boundary-spill`;
- missing PHI restoration state remains
  `unsupported_value/stage2-phi-dst`;
- unsupported PHI restoration moves remain
  `no_emitter/stage2-phi-restore-loc`.

## Production proofs and exact ratchet

Focused production tests prove:

- exact condition materialization, narrow mask, ordered `cmp`/`je` pairs, and
  final jump;
- committed instruction targets still reference retained transaction-owned
  copies after transaction teardown;
- no logical label is emitted and `edge_label_count` is unchanged;
- a failure after target copying and partial emission frees every speculative
  copy exactly once and restores instructions, bindings, PHI destinations,
  EFLAGS state/records, spill counters, edge counters, and owned-label length;
- framed spill and unframed PHI-restoration failures retain their diagnostics;
- the source guard requires PHI dispatch and the ordinary-boundary marker to
  precede transaction construction.

The sole `lowerSwitch/emitValueIntoEax` occurrence was removed. The bypass
inventory moved exactly from 232 to 231 occurrences; no exact-PHI helper was
absorbed.

```text
bypass_inventory_sha256=3bac06156864f8cc276f816bfa8ceb904f1d0766fa22d13a8cf0af15489f447d
classification_sha256=c50b66389c62e2e3bad820a00fa9741ca6b0fe5849f728e914b86f73bfba8574
composition_sha256=9471f70ee6f05094b056a41a670b6392e1d8a30d097fd09fb98b9daed194c508
branch_switch_ratchet_sha256=8c2061578e681a914739015e2ed6fe0b41c780b0fa2f01d0941e32be70b78c7e
```

## Blocking performance gate

Both sides used frozen compiler-rt input SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`,
the Debug candidate, `LC_ALL=C`, CPU 0 via `taskset`, one warmup, and five
measured report-all runs. Every retained run took the expected report-all exit
and reproduced `49a19f04`.

```text
before_raw=tmp/inbox96_b3c_perf/before_samples.raw
before_raw_sha256=14c88bf243e8cc4d81ef37078d67986f6cf34bd6a9bbe121eca817022760d0ed
before_warmup_seconds/rss_kib=49.79/96216
before_1_seconds/rss_kib=49.62/96220
before_2_seconds/rss_kib=49.55/96216
before_3_seconds/rss_kib=49.43/96228
before_4_seconds/rss_kib=49.30/96216
before_5_seconds/rss_kib=49.22/96216
before_median_seconds=49.43
before_max_rss_kib=96228

after_raw=tmp/inbox96_b3c_perf/after_samples.raw
after_raw_sha256=684216e8fbc3d200b9f480eac8c6d2833399ebd76f6404b5ed725be43b58ca8e
after_warmup_seconds/rss_kib=49.06/95956
after_1_seconds/rss_kib=49.46/94232
after_2_seconds/rss_kib=49.22/96044
after_3_seconds/rss_kib=49.21/96048
after_4_seconds/rss_kib=48.87/96052
after_5_seconds/rss_kib=48.83/96048
after_median_seconds=49.21
after_max_rss_kib=96052

median_delta_seconds=-0.22
wall_limit_seconds=+2.4715
max_rss_delta_kib=-176
rss_limit_kib=+16384
performance_result=pass
```

Procedural debugger counters were collected outside canonical output:

```text
family=lowerSwitch transactions=12 snapshots=12 commits=12 rollbacks=0
safe_candidates=0 early_executed=0 transactions_with_early=0 max_early=0 demoted=0
eflags_record_attempts=97 committed_eflags_records=97
owned_target_copies=60
max_active_nesting=1 active_at_exit=0 close_underflow=0
snapshot_bytes=149761
copy_volume_bytes=1797132
copy_volume_mib=1.713879
snapshots_per_transaction=1
metrics_log_sha256=70ffe03f1a37b045adb99202fc5f1699c8694be579934a22c7117237bcc3fea4
snapshot_size_log_sha256=a838a712fa6a21bf1a665d7d99d72ced2133312145e6dc3997c129aeb164a8e8
```

Thus every ordinary-switch authority took exactly one address-domain snapshot,
nesting stayed constant, and no early sequencing was introduced.

## Frozen byte identities

The final after-run report is `tmp/inbox96_b3c_perf/after_5.log`:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

`compiler_rt.exp.exp` and `compiler_rt.exp.expf` remain byte-identical at
`no_emitter/composed-block-gep-readonly-table-global`. None of the twelve O2
frontier targets advanced.

## Non-Tier-3 validation

```text
full_unit=1172/1172
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=78d0b133f25cac90a27934178d305d30a47021d7945ad41d1332dfc4585b12b5
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1180/1180 tests
strengthened_tier2_log_sha256=6616bd5c661c1963f452e6d6ac9a4869f9e01c3a3ada966759ffeb64f4f73b6c
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

Stop here for B3C review. The memcpy family remains dormant-first and is not
authorized by this slice.
