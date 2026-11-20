# INBOX-118 O2-3I-B2a — current-home integer eq-zero production migration

## Result and frozen scope

```text
result=pass
accepted_code_commit=aa4305917ad4a2cd0496bf0a67ffe3f74683a5a8
accepted_code_tree=f62cd07329b42568f24399887aa96c74992e949f
working_head_with_supervisor_docs=1112c504cba2012e52543148b5f081d9ab547930
working_head_tree=1714ce1df8ee1b33220774797e0d6a1274816681
audit_row=I13_eq_zero_current_home
ratchet_before=187
ratchet_after=186
ratchet_delta=-1
next_slice=I-A2b_not_started
stash_at_0=untouched
```

The action, transaction API, and planning model are byte-identical to the
accepted `aa430591` tree. This slice wires only the complete I13 semantic
branch: generic integer `eq` with literal zero. It does not design or wire any
I-A2b form.

Dispatch preserves the reviewed precedence:

1. the pure fixed-scratch classifier;
2. `isExactEiNarrowIcmp(selector, icmp)`;
3. the pure semantic I13 predicate/type/RHS-form classifier;
4. the remaining legacy O1 path.

The I13 classifier reads no selector state, value home, function name, or
family identity. Every I13 form enters exactly one outer
`ValueUseTransaction`, including unsupported widths/homes and i128
`.spill128`. All non-I13 forms enter exactly one existing standalone
`AccumulatorDefinitionTransaction`. The authorities are mutually exclusive:
there is no nesting, fallback, or duplicate I13 lowering.

The I13 leaf registers and seals the lhs before mutation, opens one subordinate
accumulator session, prepares and materializes the request, executes the
closed current-home action, and performs the sole outer commit. The action
retains the accepted live-accumulator preamble, canonical re-resolution,
direct-home or spill-to-RCX test, EFLAGS preservation through accumulator
preparation, `sete`, durable result identity, `.zeroExtending(1)` definition,
and session finalization.

Request failures map only when `failedRequestIs(lhs_request)` succeeds:

```text
unresolved source -> composed-block-icmp-lhs
unsupported semantic/binding width -> composed-block-icmp-lhs-width
unsupported current home, including spill128 -> composed-block-icmp-lhs-loc
```

Authority-level failures propagate unchanged.

## Focused production proofs and guard

The production-path suite proves:

- direct argument/scratch and accumulator current-home tests;
- spill64 reload-to-RCX before `test` and `sete`;
- exact unresolved, unsupported-width, and unsupported-home diagnostics;
- i128 `.spill128` rejection before mutation;
- fixed-scratch i52 dispatch before I13;
- exact-EI narrow eq-zero dispatch before I13;
- the existing dormant action lifecycle and rollback boundaries.

The source guard freezes the exact four-stage dispatch order, the pure semantic
classifier, one outer transaction/session/action/commit shape, provenance-only
diagnostic mapping, and the absence of raw resolution or an independently
snapshotted O1 transaction in the I13 leaf. Negatives reject state-dependent
classification and production wiring outside the function-scoped icmp
allowlist.

The inventory removes only `lowerIcmp/resolveValue` occurrence 1:

```text
mechanical_occurrence_total=186
inbox81_inventory_sha256=708222884aaffc54577e264990c9069cf6edcd23f6c35fdcbf8463779a794acb
inbox84_classification_sha256=ffc4eb048472e635158b79326abccb4311e0207b07cb014d24e07e07af096afc
classification=O2-3I-B2a/migrated_current_home_eq_zero_test_action
source_guard=pass
git_diff_check=pass
```

## Immutable performance artifacts and protocol

Both artifacts were built before timing from detached worktrees. Artifact A
is the accepted `aa430591` tree. Artifact B is that exact tree plus the final
production/test/guard/inventory patch. The patch was regenerated from the B
worktree and matched byte-for-byte. Both artifacts were made read-only and
were not rebuilt between samples.

```text
artifact_A=tmp/inbox118_icmp_eq0_perf/artifacts/A/z_llvm
artifact_A_sha256=735e7818cedfea41ce15893a1a7cf8aea43bc1b56413bef847a2b0aeec831d52
artifact_A_mode_size=0555/90537233
artifact_B=tmp/inbox118_icmp_eq0_perf/artifacts/B/z_llvm
artifact_B_sha256=da3398a9f3a285ff6fd9fffd68916d314896f46224576ac8f7d055d3fe7c0ffd
artifact_B_mode_size=0555/90547223
immutable_B_patch_sha256=545acce7765b0decba700ac115097681b3d7167c9aef4f2757b3eafb8fd2f11c
rebuilt_B_patch_sha256=545acce7765b0decba700ac115097681b3d7167c9aef4f2757b3eafb8fd2f11c
```

The preflight found no competing Zig/z_llvm workload. The machine averaged
94.65% idle and pinned CPU 0 averaged 95.35% idle. Both artifacts used CPU 0,
`LC_ALL=C.UTF-8`, the same absolute input, Zig pin, environment, and
warmed-cache policy.

```text
idle_preflight=tmp/inbox118_icmp_eq0_perf/idle_preflight.txt
idle_preflight_sha256=5357e740ae9c756d3d31f4e9caff06dc63061dcad3a4a02d1338c6db0de89793
```

Exactly two warmups per artifact were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 50.66 | 95652 |
| B warmup 1 | 51.58 | 95220 |
| A warmup 2 | 50.41 | 95672 |
| B warmup 2 | 51.08 | 95188 |

All six counterbalanced pairs were retained in the required
AB/BA/AB/BA/AB/BA order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 50.57 | 95712 | 50.76 | 95304 | 1.003757168 |
| 2 | BA | 50.11 | 95656 | 50.77 | 95320 | 1.013171024 |
| 3 | AB | 50.22 | 95656 | 49.52 | 95308 | 0.986061330 |
| 4 | BA | 49.38 | 95664 | 49.77 | 95304 | 1.007897934 |
| 5 | AB | 49.70 | 95652 | 49.52 | 95304 | 0.996378270 |
| 6 | BA | 49.01 | 95652 | 49.46 | 95308 | 1.009181800 |

```text
median_A_seconds=49.905
median_B_seconds=49.645
median_delta_seconds=-0.260
allowed_delta_seconds=max(2.49525,0.100)=2.49525
aggregate_median_gate=pass
paired_ratio_median=1.005827551
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=95712
B_max_rss_KiB=95320
rss_delta_KiB=-392
rss_gate=pass
timed_raw_manifest_sha256=f1ea28b24a38240c9cea2bf541596fb3cc612512e0aea5baa5b94827bf7be92f
warmup_raw_manifest_sha256=569b25ed0564609d7dd206889c92feb772fb920ed3724b2446433a1bd3dedc92
report_hash_manifest_sha256=fe3149b8ab34c9d50bf37a573bcffbd355f222255d910017b1373874ce4d148d
```

Every warmup and timed report re-hashed to `49a19f04`. No outlier was removed
and no discretionary rerun was performed.

## Dynamic transaction metrics

The procedural measurement used the immutable B artifact and the full frozen
input. The measured address-domain snapshot is 149,761 bytes. Successful
admitted forms have one transaction, snapshot, session, and action. The nine
i128 forms fail closed at seal with no session/action; these include the six
unchanged target rows.

| Semantic width | Transactions | Snapshots | Sessions | Actions | Rollbacks | Copied bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| i4 | 1 | 1 | 1 | 1 | 0 | 149,761 |
| i16 | 22 | 22 | 22 | 22 | 0 | 3,294,742 |
| i32 | 111 | 111 | 111 | 111 | 0 | 16,623,471 |
| i64 | 144 | 144 | 144 | 144 | 0 | 21,565,584 |
| i128 rejected | 9 | 9 | 0 | 0 | 9 | 1,347,849 |
| **total** | **287** | **287** | **278** | **278** | **9** | **42,981,407** |

```text
subordinate_snapshot_copies=0
maximum_nesting=1
active_at_exit=0
metric_log=tmp/inbox118_icmp_eq0_perf/icmp_eq0_metrics.log
metric_log_sha256=59c93b148e3f16d81fb8522d6c73dcec55fd020348ea341b89c81d2e0efea52c
```

## Frozen identities and target frontier

```text
fresh_report=tmp/inbox118_icmp_eq0_perf/validation/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object=tmp/inbox118_icmp_eq0_perf/validation/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox118_icmp_eq0_perf/validation/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

All six O2 `.spill128` targets remain at
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
`tmp/inbox118_icmp_eq0_perf/validation/spill128_targets.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
No O2 target advanced.

The A and B `exp`/`expf` collateral extracts are byte-identical, both SHA-256
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`.
Both retain the exact `composed-block-gep-readonly-table-global` diagnostics.

## Validation and Tier-3 deviation

```text
full_unit=1238/1238
full_unit_log=tmp/inbox118_icmp_eq0_perf/validation/full_unit.log
full_unit_log_sha256=857350c5de2fcb4ed35eea9f772b1a4fb7d7e6f760afda94fd8f2e525b17a3bb

abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox118_icmp_eq0_perf/validation/abi_differential.log
abi_log_sha256=8787fbbdbb826a1f190869c2cee38ec672135ddd8368fdffb41697ee46182d96

focused_codegen_canaries=2 canaries; 35 execution cases; local_fail=0
canary_log=tmp/inbox118_icmp_eq0_perf/validation/focused_canaries.log
canary_log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6

integrated_exe=7/7
integrated_log=tmp/inbox118_icmp_eq0_perf/validation/integrated_exe.log
integrated_log_sha256=f8c34c34a40b819df8ae2be09bac5760e018b05cf211a3db261acb848632fd1d

strengthened_tier2=29/29 steps; 1246/1246 tests
tier2_log=tmp/inbox118_icmp_eq0_perf/validation/strengthened_tier2.log
tier2_log_sha256=678e9e80b4113bddb8885d00785c979f3f2bed8604d5598523e83fa3c385a521
```

During final validation, `zig build distribution-all --summary all` was
mistakenly launched under the false assumption that it was strengthened
Tier 2. It is the parallel Tier-3 gate, which INBOX-118 does not authorize and
which is not the serial acceptance protocol reserved for O2-7B. The active
process was allowed to finish cleanly to avoid corrupting gate-owned state;
its log was renamed to
`tmp/inbox118_icmp_eq0_perf/validation/unauthorized_distribution_all_parallel.log`.
That run and its output are explicitly excluded from every INBOX-118
acceptance claim, identity, and evidence hash above. It was replaced by the
exact strengthened Tier-2 batch required by the Supervisor correction:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump
compare-codegen-readelf distribution-object distribution-executable
distribution-debug-object distribution-debug-executable
distribution-releasesafe-object distribution-zig-integrated-exe
abi-differential --summary all
```

No acceptance-grade Tier 3 was run or claimed. Future Tier 3 remains reserved
for O2-7B and must use the serial protocol. INBOX-118 stops here before I-A2b.
