# INBOX-95 — O2-3B3B branch-condition production migration

Status: delivered for review; B3C switch wiring is not included.

## Frozen source and scope

The accepted B3A parent is `91a829fd62b8db1bcd4ce7dfe30086d6dee75e6d`
(tree `7e62332091edcefe2c621768588dc0b0149f5a8c`). The working branch already
contained the Supervisor documentation-only descendant `5f17eca8`; no branch
movement or destructive worktree operation was used. `stash@{0}` was not
inspected, applied, or dropped.

Only `emitBranchCondition` is now a production consumer of the dormant B3A
`branch_condition` action. It owns one instruction-level
`ValueUseTransaction`: register, seal, prepare, materialize, execute, and
commit. The action-specific compatibility boundary remains authoritative:
wide-class spill storage is accepted for the semantic i1 request, while
wide-register and accumulator homes remain rejected. The frozen transaction,
action, and sequencing implementation has no diff from B3A.

The production proofs cover:

- the real CFG terminator consuming the committed test definition with its
  actual `jne` EFLAGS use;
- live RCX pressure with the exact preservation, spill reload, test, and
  conditional-branch ordering;
- failure before the test append restoring instructions, bindings, spill
  state, EFLAGS state, and semantic-record length exactly.

## Exact bypass ratchet

The sole `emitBranchCondition/resolveValue` occurrence was removed. The frozen
bypass inventory moved exactly from 233 to 232 occurrences; it now contains
85 function/gateway entries. No parent-owned helper or switch occurrence was
absorbed.

```text
bypass_inventory_sha256=86c9f49f4eca03860336fae2ae09dfdda3f2c35100931740dbafbcfa43da91b9
classification_sha256=11cadc785b1f2168d8deadb07e4d644d3ca0b5b16eb34340f41c22de3cad45c5
composition_sha256=1fbbdc2e390a8504d5fba370970d9904d2bd3eaa71e18981be15a4b36a59c679
branch_switch_ratchet_sha256=421778f159cd70a9f7c03008aff52c00c0926e82e66088b1c8194481095c5293
```

The source guard admits exactly the two action-tag fields in the enclosing
`emitBranchCondition` body and rejects an addition or relocation. The dormant
switch tags remain forbidden in production consumers.

## Blocking performance gate

Both sides used the frozen compiler-rt input SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`,
the Debug candidate, `LC_ALL=C`, CPU 0 via `taskset`, one warmup, and five
measured report-all runs. Every run took the expected report-all exit and
reproduced `49a19f04`.

```text
before_raw=tmp/inbox95_b3b_perf/before_samples.raw
before_raw_sha256=e2764685cc284981b12717f5440c5617f01215b7a688d32fcbad8d1f3d4ff8b5
before_warmup_seconds/rss_kib=48.88/95528
before_1_seconds/rss_kib=48.84/95768
before_2_seconds/rss_kib=48.85/95760
before_3_seconds/rss_kib=49.01/95772
before_4_seconds/rss_kib=48.90/95760
before_5_seconds/rss_kib=48.93/95752
before_median_seconds=48.90
before_max_rss_kib=95772

after_raw=tmp/inbox95_b3b_perf/after_samples.raw
after_raw_sha256=bd52cf9e451064a7f1a8eae84299e9eec15c51bfd367df5c60cdf243a07a1996
after_warmup_seconds/rss_kib=49.09/96148
after_1_seconds/rss_kib=49.33/96136
after_2_seconds/rss_kib=49.13/96140
after_3_seconds/rss_kib=49.12/96200
after_4_seconds/rss_kib=50.03/96104
after_5_seconds/rss_kib=50.39/96132
after_median_seconds=49.33
after_max_rss_kib=96200

median_delta_seconds=+0.43
wall_limit_seconds=+2.445
max_rss_delta_kib=+428
rss_limit_kib=+16384
performance_result=pass
```

Procedural debugger counters were collected outside canonical output:

```text
family=emitBranchCondition transactions=1158 snapshots=1158
safe_candidates=0 early_executed=0 transactions_with_early=0 max_early=0 demoted=0
eflags_definition_attempts=1158 committed_eflags_definitions=1158 rollbacks=0
max_active_nesting=1 active_at_exit=0 close_underflow=0
snapshot_bytes=149761
copy_volume_bytes=173423238
copy_volume_mib=165.389288
snapshots_per_transaction=1
metrics_log_sha256=f687413e59eed4e0607eb58d8a8704b29119af9fab965a2ad27db6195dd879a3
snapshot_size_log_sha256=a838a712fa6a21bf1a665d7d99d72ced2133312145e6dc3997c129aeb164a8e8
```

Thus every instruction authority took exactly one address-domain snapshot,
nesting stayed constant, and no early-plan sequencing was introduced.

## Frozen byte identities

The fresh final report is
`tmp/inbox95_b3b_perf/b3b_full_report.log`:

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

The collateral watches remain byte-identical:
`compiler_rt.exp.exp` and `compiler_rt.exp.expf` both still fail at
`no_emitter/composed-block-gep-readonly-table-global`. None of the twelve O2
frontier targets advanced.

## Non-Tier-3 validation

```text
full_unit=1169/1169
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=385e7d9dce05abced84d81c8fcf85261ec363751db4b39750f5f2ef77eaeb908
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1177/1177 tests
strengthened_tier2_log_sha256=9db64328f0ed6e1f3b4eb2c309413f6e713e61b51d375e863a2107ea8fc1bd7d
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

Stop here for B3B review. Ordinary non-PHI `lowerSwitch` remains on its
accepted path for the separately authorized B3C slice.
