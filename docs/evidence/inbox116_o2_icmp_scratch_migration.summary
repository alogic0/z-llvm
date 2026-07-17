# INBOX-116 O2-3I-B1 — fixed-scratch icmp production migration

## Result and frozen scope

```text
result=pass
accepted_code_commit=ffd716431686e836bb2249131c50c90f9ccfe479
accepted_code_tree=efa6afa230ceed26b0a370edd75ee85d35e55fd2
working_head_with_supervisor_docs=6d1f22513c09fd21a5ec7ebb4c76519cd379ead9
working_head_tree=699c1ff2ca111ce9ea44ba70c8660b8040a95277
ratchet_before=216
ratchet_after=187
ratchet_delta=-29
tier3=not-run
current_home_work=not-started
```

The production wiring is the preserved, previously reviewed patch applied
unchanged:

```text
preserved_patch=tmp/inbox114_icmp_scratch_perf/inbox114_preserved_wiring_only.patch
preserved_patch_sha256=78f75c9c2696885621a3e57ca363891fc5b7d739beaefb9efe19a41768c3a3b9
git_apply_check=pass
applied_icmp_diff=tmp/inbox116_icmp_scratch_perf/applied_wiring.patch
applied_icmp_diff_sha256=78f75c9c2696885621a3e57ca363891fc5b7d739beaefb9efe19a41768c3a3b9
immutable_B_patch=tmp/inbox116_icmp_scratch_perf/worktree_B.patch
immutable_B_patch_sha256=78f75c9c2696885621a3e57ca363891fc5b7d739beaefb9efe19a41768c3a3b9
stash_at_0=untouched
```

No transaction action, planning, state, or accumulator-session API was
changed. The pure pre-transaction classifier reads only the icmp predicate,
type width/kind, samesign bit, and RHS semantic form. It does not inspect
selector state, value homes, function identity, or family identity.

Fixed-scratch forms enter exactly one outer `ValueUseTransaction`, take one
outer snapshot, and use one subordinate accumulator session. All remaining
forms continue through exactly one standalone
`AccumulatorDefinitionTransaction`. The two authorities are mutually
exclusive: there is no nesting, fallback, or duplicate fixed-scratch lowering.

Named operands register in legacy source order. Request failures map only
when the matching lhs or rhs `failedRequestIs` query succeeds; authority
failures propagate unchanged. The accepted live-accumulator preservation
preamble executes before operand staging, refreshes canonical operand records,
and leaves the audited session-prepare point unchanged.

## Exact source-guard ratchet

The frozen bypass inventory removes only
`lowerIcmp/emitValueIntoScratch` times 29. The corresponding classification is
now the migrated `O2-3I-B1` fixed-scratch compare subgroup.

```text
inbox81_inventory_sha256=0df5eb738ae883dd7703bb2303d9c2c3d39ff133d854aca7ab5fa894cbabe829
inbox84_classification_sha256=7f9d2b149868540603ec06dcbfe37780fbe98c7103fb628ea53ffe907f74097d
mechanical_occurrence_total=187
source_guard=27/27
source_guard_log=tmp/inbox116_icmp_scratch_perf/validation/source_guard_pre_perf.log
source_guard_log_sha256=657477b8e920140bd704d02bf88c758c8f2144a6ecdae3360cb0aba6fef859ef
```

The guard freezes the pure classifier boundary, mutually exclusive authority
shape, exact transaction/session/action/commit counts, narrow provenance
mapper, and absence of nested accumulator transactions. Its negatives reject
state- or family-based classification and transaction use outside the
approved lowerer.

## Immutable performance artifacts and protocol

Both artifacts were built before timing from detached worktrees. Artifact A is
the accepted `ffd71643` tree. Artifact B is that exact tree plus the
hash-verified wiring patch. They were made read-only and were not rebuilt
between samples.

```text
artifact_A=tmp/inbox116_icmp_scratch_perf/artifacts/A/z_llvm
artifact_A_sha256=9e1135b94ab12e9357f8f575aa222e63865fe7b6a392b745469e876eea6fcea5
artifact_A_mode_size=0555/90678893
artifact_B=tmp/inbox116_icmp_scratch_perf/artifacts/B/z_llvm
artifact_B_sha256=bf0c294d611fceab81bb7dc8378fe9dff501ac9f5054362718dd89ac83fc0f45
artifact_B_mode_size=0555/90475699
```

The preflight found no competing Zig/z_llvm workload. Sixteen CPUs averaged
94.13% idle and pinned CPU 0 averaged 94.39% idle. Both artifacts used CPU 0,
`LC_ALL=C`, the same absolute input, the same Zig pin and environment, and
the same warmed-cache policy.

```text
idle_preflight=tmp/inbox116_icmp_scratch_perf/idle_preflight.txt
idle_preflight_sha256=8e1b5882814ff30dd61acfd6168eda763ca891e66c6f446f90fc11e5c3f77aed
```

Exactly two warmups per artifact were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 50.16 | 96160 |
| B warmup 1 | 49.97 | 95472 |
| A warmup 2 | 50.20 | 96520 |
| B warmup 2 | 49.94 | 95456 |

All six counterbalanced pairs were retained, in the required
AB/BA/AB/BA/AB/BA order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 51.46 | 96512 | 51.34 | 95464 | 0.997668092 |
| 2 | BA | 51.28 | 96516 | 51.48 | 95460 | 1.003900156 |
| 3 | AB | 52.10 | 96432 | 51.86 | 95456 | 0.995393474 |
| 4 | BA | 52.18 | 96528 | 51.82 | 95472 | 0.993100805 |
| 5 | AB | 52.06 | 96520 | 51.97 | 95468 | 0.998271226 |
| 6 | BA | 51.46 | 96512 | 51.45 | 95452 | 0.999805674 |

```text
median_A_seconds=51.760
median_B_seconds=51.650
median_delta_seconds=-0.110
allowed_delta_seconds=max(2.588,0.100)=2.588
aggregate_median_gate=pass
paired_ratio_median=0.997969659
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=96528
B_max_rss_KiB=95472
rss_delta_KiB=-1056
rss_gate=pass
timed_raw_manifest_sha256=e8b2bb213b7a2b15829c768d8c9828a77f3e8f17e18e56a5eab4561fda6ec44c
warmup_raw_manifest_sha256=82c14af07c2326acb0670ecafd45aeb6dcabaac0928bf86e5f3496b9a73c367b
report_hash_manifest_sha256=c5c93dcd0a1d8e0e72653656e6eddf742317290459ca38967c9360614ca12040
```

Every warmup and timed report re-hashed to `49a19f04`. No outlier was removed
and no discretionary rerun was performed.

## Dynamic transaction metrics

The procedural measurement used the immutable B artifact and the full frozen
input. The measured snapshot size is 149,761 bytes. Every form has equal
transaction, outer-snapshot, subordinate-session, and action counts; every
form has zero subordinate snapshots and zero observed rollback on this
successful cohort:

| Semantic form | Count | Copied bytes |
| --- | ---: | ---: |
| eq plain i32 named | 18 | 2,695,698 |
| eq plain i52 immediate | 3 | 449,283 |
| eq plain i64 immediate | 41 | 6,140,201 |
| eq plain i64 named | 66 | 9,884,226 |
| eq plain pointer named | 6 | 898,566 |
| eq plain pointer null | 4 | 599,044 |
| ne plain i16 immediate | 6 | 898,566 |
| ne plain i16 named | 4 | 599,044 |
| ne plain i32 immediate | 19 | 2,845,459 |
| ne plain i32 named | 7 | 1,048,327 |
| ne plain i64 immediate | 26 | 3,893,786 |
| ne plain i64 named | 4 | 599,044 |
| sgt plain i16 named | 2 | 299,522 |
| sgt plain i32 named | 6 | 898,566 |
| sgt plain i64 immediate | 17 | 2,545,937 |
| sgt plain i64 named | 2 | 299,522 |
| slt plain i16 immediate | 9 | 1,347,849 |
| slt plain i16 named | 2 | 299,522 |
| slt plain i32 named | 2 | 299,522 |
| slt plain i64 immediate | 2 | 299,522 |
| slt plain i64 named | 2 | 299,522 |
| ugt plain i32 immediate | 20 | 2,995,220 |
| ugt plain i32 named | 11 | 1,647,371 |
| ugt plain i64 immediate | 12 | 1,797,132 |
| ugt plain i64 named | 16 | 2,396,176 |
| ugt samesign i16 immediate | 14 | 2,096,654 |
| ugt samesign i32 immediate | 58 | 8,686,138 |
| ugt samesign i32 named | 2 | 299,522 |
| ugt samesign i64 immediate | 36 | 5,391,396 |
| ugt samesign i64 named | 2 | 299,522 |
| ult plain i16 immediate | 6 | 898,566 |
| ult plain i32 named | 2 | 299,522 |
| ult plain i64 immediate | 53 | 7,937,333 |
| ult plain i64 named | 2 | 299,522 |
| ult samesign i16 immediate | 13 | 1,946,893 |
| ult samesign i64 immediate | 27 | 4,043,547 |
| **total** | **522** | **78,175,242** |

```text
transactions=522
outer_snapshots=522
subordinate_sessions=522
actions=522
rollbacks_observed=0
subordinate_snapshot_copies=0
maximum_nesting=1
active_at_exit=0
snapshot_bytes=149761
metric_log=tmp/inbox116_icmp_scratch_perf/icmp_metrics.log
metric_log_sha256=77a8f8c1bc28a73989365a56f60080b5d91ad6d87b47558dc06c3c38a5674ee8
```

Focused rollback tests cover the required failure boundaries; the dynamic
rollback counter is correctly zero for the successful frozen cohort.

## Frozen identities and target frontier

```text
fresh_report=tmp/inbox116_icmp_scratch_perf/validation/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object=tmp/inbox116_icmp_scratch_perf/validation/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox116_icmp_scratch_perf/validation/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

All six O2 `.spill128` targets remain at the exact unchanged frontier
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

The target extraction is
`tmp/inbox116_icmp_scratch_perf/validation/spill128_targets.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
No O2 target advanced.

The A and B `exp`/`expf` collateral extracts are byte-identical, both SHA-256
`1484a0ac139d8a7a78fbda2cc1c8e90521bbd563250aa5c34e7fac08db60cad1`.
Both retain the exact `composed-block-gep-readonly-table-global` diagnostics.

## Validation

```text
full_unit=1229/1229
full_unit_log=tmp/inbox116_icmp_scratch_perf/validation/full_unit.log
full_unit_log_sha256=06459c33b13c0bfb37045cec66903515742b6323200c106768b0fcf221222e0d

abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox116_icmp_scratch_perf/validation/abi_differential.log
abi_log_sha256=a894de07ee8e6d18af68bf0e66a68b9360fc340e4e6dafaf0cce5f74e80309de

focused_codegen_canaries=2/2 canaries; 35/35 execution cases; local_fail=0
canary_log=tmp/inbox116_icmp_scratch_perf/validation/focused_canaries.log
canary_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133

integrated_exe=7/7
integrated_log=tmp/inbox116_icmp_scratch_perf/validation/integrated_exe.log
integrated_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949

strengthened_tier2=29/29 steps; 1237/1237 tests
tier2_log=tmp/inbox116_icmp_scratch_perf/validation/strengthened_tier2.log
tier2_log_sha256=0b9e8510c65d1c28f6e91c5ada4f3d9180637da547390b8b7f53a510072157e7
```

No Tier 3 was run. INBOX-116 stops at this review checkpoint before any
current-home icmp action design or production wiring.
