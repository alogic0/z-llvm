# INBOX-120 O2-3I-B2b1 — setcc-producing EAX compare migration

## Frozen foundation and scope

```text
accepted_action_commit=ba3967f6
accepted_action_tree=d8b92335e3d2570e82438448cb4cfe7994884c8d
working_head_with_supervisor_docs=e7b0ed6a752f4a1882eb25afe5c1a60578deaff2
working_head_tree=97f1dfede1dd121e4467facda402346006c0060d
immutable_B_patch_sha256=fac0ac255fc54a7edd9dfafd763369930896668cc0a67f42b3c8b297f4bc5550
transaction_or_action_model_change=none
ratchet_before=186
ratchet_after=176
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

The production wiring routes exactly the ten audited setcc-producing EAX
gateways through the frozen `SetccEaxCompareAction`: the existing exact-EI
structural family and the nine ordinary forms I12b, I18, I19, I20, I21,
I27a, I29, I30, and I33. The two sign-extraction forms remain on the O1
fallback for the separately reviewed I-A2b2 slice.

The dispatch order is:

1. `classifyScratchCompare`;
2. the existing `isExactEiNarrowIcmp(selector, icmp)` structural check,
   routing matches to `.exact_ei`;
3. `isCurrentHomeEqZeroIcmp`;
4. the pure semantic `isSetccEaxCompareIcmp` classifier, routing the other
   nine admitted forms to `.ordinary`;
5. one legacy `AccumulatorDefinitionTransaction` fallback.

`isSetccEaxCompareIcmp` observes only predicate, type/width, samesign, lhs/rhs
IR forms, and immediate value. It has no selector, value-home, function-name,
or family predicate. Exact-EI admission is not duplicated or broadened.
Near-miss samesign immediates remain on the legacy diagnostic path, retaining
the existing range-diagnostic timing.

Each admitted form owns one outer `ValueUseTransaction`, one outer snapshot,
and one subordinate accumulator session. The named lhs request is registered
and sealed before mutation. Only request-attributed failures map through
`failedRequestIs(lhs_request)` to the legacy lhs, width, or location
diagnostic; authority failures propagate unchanged. There is no raw source
resolution, prepared-location escape, fallback authority, or independent O1
transaction in the migrated paths.

## Focused production coverage and guard ratchet

The production tests cover the exact-EI route, all ordinary action streams
already exercised by the branch tests, unresolved-lhs provenance,
`.spill128` location provenance with exact rollback, and an unattributed
exact-EI predicate authority failure. Direct unit selectors now carry
explicit allocation-plan entries so the production transaction exercises
the same at-current liveness contract as a planned selector.

The source guard enforces the five-stage order, pure semantic ordinary
classifier, exact two action calls, one transaction/session/commit lifecycle,
request-only diagnostic mapper, and function-scoped production allowlist.
Negative fixtures reject wiring outside `composed_selector_icmp.zig` and
selector/home inspection in the ordinary classifier.

```text
mechanical_occurrence_total=176
inbox81_inventory_sha256=293163330d24a90904db1f9fb94474493ba4bf55c04fdad91682138d0c7209d0
inbox84_classification_sha256=ddd54d16b07296192b397f5db8175d72c63e01042d1509731325b09185fc5083
lowerExactEiNarrowIcmp_emitValueIntoEax=migrated_1
lowerIcmp_emitValueIntoEax=migrated_9,residual_sign_extraction_1
source_guard=29/29
```

## Immutable artifacts and counterbalanced performance

Artifact A was built from detached `ba3967f6`. Artifact B was built from the
same detached tree plus the final scoped production/test/guard/inventory
patch. Both were built before timing, copied read-only, and never rebuilt
between samples.

```text
artifact_A=tmp/inbox120_icmp_setcc_perf/artifacts/A/z_llvm
artifact_A_sha256=2bffe3fe1e6972ed404de79a885d849312947fceef2bbdf5a6c4193a2404b81f
artifact_A_mode_size=0555/90647486
artifact_B=tmp/inbox120_icmp_setcc_perf/artifacts/B/z_llvm
artifact_B_sha256=302e5c325a24ceaf74de1bfdd3c96434c01fd95d64ec021058bd6c04e0382ed2
artifact_B_mode_size=0555/90566026
idle_preflight_sha256=c4e9f5bca8112c5a69cc104bdd94f6cd256a2eec5abf1aeab391fc274c0904fc
machine_average_idle=93.21%
pinned_cpu0_average_idle=97.67%
competing_zig_or_zllvm_workload=none
```

Every sample used this exact command shape, with `ARTIFACT` and log names
fixed by the required sequence:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> LOG
```

Exactly two warmups per artifact were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 48.68 | 95,708 |
| B warmup 1 | 48.70 | 94,568 |
| A warmup 2 | 48.73 | 95,712 |
| B warmup 2 | 48.63 | 94,568 |

All six pairs were retained in the required `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 48.70 | 95,712 | 48.66 | 94,564 | 0.999178645 |
| 2 | BA | 48.72 | 95,712 | 48.70 | 94,576 | 0.999589491 |
| 3 | AB | 48.72 | 95,728 | 48.66 | 94,572 | 0.998768473 |
| 4 | BA | 48.65 | 95,712 | 48.88 | 94,564 | 1.004727646 |
| 5 | AB | 48.70 | 95,720 | 48.97 | 94,564 | 1.005544148 |
| 6 | BA | 48.79 | 95,724 | 48.76 | 94,572 | 0.999385120 |

```text
median_A_seconds=48.71
median_B_seconds=48.73
median_delta_seconds=+0.02
allowed_delta_seconds=max(2.4355,0.100)=2.4355
aggregate_median_gate=pass
paired_ratio_median=0.999487
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=95728
B_max_rss_KiB=94576
rss_delta_KiB=-1152
rss_gate=pass
timed_raw_manifest_sha256=af7167e902de0766876137a17c32ec0b0dfc037daa870a6836cbb15b399471dd
warmup_raw_manifest_sha256=4e1724cddfeb0c963c94afba8767aeb2f4c697649d343e166fad5cbd61964536
paired_ratios_sha256=05645e69802c25eab41d67b897b5cb883998bf6d97e84c75de7d14c7d22f992d
report_hash_manifest_sha256=454e7e3f14dce4e202c5b5f879788b948d9e20b3d9b940734e8f3500540b913a
```

Every warmup and timed report re-hashed to `49a19f04`. No outlier was
removed and no additional run was performed.

## Dynamic transaction metrics

The metrics command was:

```text
gdb -q -batch -x tmp/inbox120_icmp_setcc_perf/icmp_setcc_metrics.gdb tmp/inbox120_icmp_setcc_perf/artifacts/B/z_llvm > tmp/inbox120_icmp_setcc_perf/icmp_setcc_metrics.log 2>&1
```

The procedural breakpoint run measured the address-domain snapshot as
149,761 bytes. It observed 277 successful migrated instructions:

```text
transactions=277
outer_snapshots=277
subordinate_sessions=277
actions=277
rollbacks_observed=0
subordinate_snapshot_copies=0
snapshot_bytes=149761
copy_bytes=41483797
maximum_nesting=1
active_at_exit=0
metrics_log_sha256=3104a3288551b14c990cacd8471b08b1419491f3924ce0e50b8bc539ad571c4f
```

Every transaction took exactly one outer snapshot and one subordinate
session; no subordinate snapshot was taken. Focused rollback tests cover the
failure paths, while the successful frozen cohort correctly recorded zero
rollbacks.

## Frozen identities and target frontier

Fresh report exact command (exit 1 is the frozen aggregate-failure status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox120_icmp_setcc_perf/validation/fresh_full_report.log
```

Accepted object exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox120_icmp_setcc_perf/validation/accepted.o 2> tmp/inbox120_icmp_setcc_perf/validation/accepted.stderr
```

Owner manifest exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox120_icmp_setcc_perf/validation/owner_manifest.tsv 2> tmp/inbox120_icmp_setcc_perf/validation/owner_manifest.stderr
```

```text
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

All six `.spill128` rows remain byte-for-byte at
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-icmp-lhs-loc`. The `exp`/`expf` A/B extracts are identical
(both SHA-256
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`)
and retain `composed-block-gep-readonly-table-global`. No target advanced.

## Validation

Every gate log below is paired with its exact command. No
`distribution-all` command was run.

Source guard:

```text
zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox120_icmp_setcc_perf/validation/source_guard.log 2>&1
result=29/29
log_sha256=36570f67b107524ee79f033539a3ec0853439776881540a69d360467d202f3b6
```

Full unit:

```text
zig build test --summary all > tmp/inbox120_icmp_setcc_perf/validation/full_unit.log 2>&1
result=1250/1250
log_sha256=e9895124aad8a7a51752c11a7b14275615e9a28ae454c284242875d6c62c51c4
```

ABI differential:

```text
zig build abi-differential --summary all > tmp/inbox120_icmp_setcc_perf/validation/abi_differential.log 2>&1
result=60/60 cases; 30/30 real functions; pass
log_sha256=a7657f153262612a17de5beb6fb9f5065f89cf9b562ddffe65532534edc79871
```

Focused fma/__multi3 canaries:

```text
zig build focused-codegen-canaries --summary all > tmp/inbox120_icmp_setcc_perf/validation/focused_canaries.log 2>&1
result=2/2 canaries; 35/35 execution cases; local_fail=0
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
```

Integrated executable gate:

```text
zig build distribution-zig-integrated-exe --summary all > tmp/inbox120_icmp_setcc_perf/validation/integrated_exe.log 2>&1
result=7/7
log_sha256=ddfbbeded8bea63c0ad875c1dcf1b853b0079a8e6f97a1d7b13d4ef8159449b7
```

Strengthened Tier 2:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox120_icmp_setcc_perf/validation/strengthened_tier2.log 2>&1
result=29/29 steps; 1258/1258 tests; pass
log_sha256=c8fa30c1a598a6ec4b5f224a435c5a09cbddbc714e8adbddb48139dddcc3a6f0
```

INBOX-120 stops here. The sign-extraction I-A2b2 design and the scheduled
post-icmp O2-R refactoring sequence are not started.
