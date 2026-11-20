# INBOX-133 Step B — scalar-cast production wiring

Status: complete; stopped for Supervisor/Reviewer review. The production
commit is `3d829cd4`; this document is the required immutable performance
evidence follow-up. No Tier 3 command was run.

## Frozen input and patch integrity

```text
accepted_step_a_commit=83110e82d1cb973d5e299357351890f462959a0b
accepted_step_a_tree=c518780fc0959122c1dd37347903938cab1edabb
starting_head_with_supervisor_docs=5daf6d48fa2d260bf571419bdd3ba6879b56cdc2
production_commit=3d829cd4f353e2a86a28648a62296a290b681e95
production_tree=b7aa9514f46a58553eabfdaf0006b14607ca99f6
preserved_patch=tmp/inbox133_cast_wiring/inbox133_cast_wiring_hard_stop.patch
preserved_patch_sha256=a2f934be12e4f2d8850a06a88feff65d0c66edc23543a63c458c3b7744442281
git_apply_check=clean
patch_application=byte_for_byte_without_manual_reconciliation
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7_untouched
```

The preserved patch hash was rechecked before `git apply --check` and
before application. It applied without reconciliation. After that exact
application, the redundant migrated C01 legacy branch was removed as
required by the unchanged INBOX-133 contract: all structurally admitted
i128-to-scalar pair-low casts now return through
`PairLowScalarCastAction`, so the old `resolvePairValue` fallback was no
longer reachable and had to disappear for the honest ratchet.

The Step-A action/model implementation stayed frozen:

```text
value_use/actions/scalar_arithmetic.zig=ebc7ae435edca50a65d6922711b8bda48b8a26090db25bea506919b9e4ee1d46
value_use/model.zig=10268b88b3ed9beea32887e548cbbb911f337a8fd7b6a756e5e01635060e0f0a
value_use/core.zig=6d802e509acff778e620773d0e8548af972026af32061da6fbf5ab323d0194e5
action_or_model_amendment=none
```

## Production composition and ownership boundaries

`lowerCast` now dispatches the three reviewed closed forms:

1. the i52 gate routes admitted C52-0 through C52-3 forms to
   `AccumulatorScalarCastAction`;
2. the ordinary trunc/bitcast gate routes C01 to
   `PairLowScalarCastAction`;
3. after the existing C03 pair-result branch and the unchanged exact-EI
   structural decision, C04/C05 route to `AccumulatorScalarCastAction`;
4. after the exact C06 width check, C06 routes to
   `SignExtendScratchAction`.

Each migrated path opens exactly one outer `ValueUseTransaction`, registers
its semantic source before mutation, seals, prepares, materializes, executes
the closed action, and commits once. Only the accumulator action opens the
single subordinate accumulator session. Consumer error mapping is exhaustive
over the reviewed action/request variants and runs only when
`failedRequestIs(source_request)` is true; authority failures propagate
unchanged.

The exact-EI structural check remains after C03 and before the ordinary
accumulator classifier. C02 remains the legacy alias-only `resolveValue` plus
`bindValueLoc` path. C03 remains the legacy pair-result
`emitValueIntoScratch` plus pair binding path. Focused production tests pin
both residual owners, the C52-0 live-RAX spill/reload/mask stream, and the C06
durable scratch result.

The source guard now enforces the exact action/form/classifier occurrence
counts, dispatch order, one-transaction lifecycles, provenance-only mapper,
absence of consumer home classification, C02/C03 residual operations, zero
production owners of `accumulatorCastSource`, and the sole approved
subordinate-session site. Negative fixtures reject action markers outside the
scalar file and incomplete/reclassified scalar wiring.

## Honest ratchet

```text
mechanical_bypass_total_before=172
mechanical_bypass_total_after=166
removed_accumulatorCastSource_resolveValue=1
removed_lowerCast_resolvePairValue=1
removed_lowerCast_resolveValue=2
removed_lowerI52Cast_resolveValue=2
removed_total=6
remaining_lowerCast_resolveValue=1_C02_alias_only
remaining_lowerCast_emitValueIntoScratch=1_C03_pair_result
accumulatorCastSource_production_owner_count=0
inbox81_inventory_sha256=5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad
inbox84_classification_sha256=8459fd57ab120cd087fad67286ed288e53264f2095d698deb15c1a5fffbfe3c7
source_guard=37/37
```

The frozen inventory and classification TSV were updated only for those six
migrated occurrences. The guard's mention of the retired helper is a
zero-occurrence assertion, not a production owner.

## Frozen identities and protected frontier

Fresh report exact command (exit status 1 is the accepted aggregate-failure
status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox133_cast_wiring/validation/fresh_full_report.log
```

Accepted object exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox133_cast_wiring/validation/accepted.o 2> tmp/inbox133_cast_wiring/validation/accepted.stderr
```

Owner manifest exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox133_cast_wiring/validation/owner_manifest.tsv 2> tmp/inbox133_cast_wiring/validation/owner_manifest.stderr
```

```text
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40_composed_cfg:127_legacy_envelope:17_structural_fallback:101
ledger=167/17/101
```

All six `.spill128` eq-zero rows remain byte-for-byte at
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-icmp-lhs-loc`. The retained extract is
`tmp/inbox133_cast_wiring/validation/frontier_rows.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`,
identical to the pre-wiring extract. The `exp`/`expf` collateral extract is
also exact, SHA-256
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`.
No target advanced.

## Non-Tier-3 validation

Every retained gate log is paired with its exact command.

Source guard:

```text
/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox133_cast_wiring/validation/source_guard.log 2>&1
result=37/37
log_sha256=d2e49b8e83706769628edb0d0a0951fa559fd35f66d1894f76e889d4994a9985
```

Full unit:

```text
/home/oleg/bin/zig build test --summary all > tmp/inbox133_cast_wiring/validation/full_unit.log 2>&1
result=1297/1297
log_sha256=e10bb7554dbe30671e60d47af5b2c7b8453c0c453dcfe53a7a8bbb40322ef7b3
```

ABI differential:

```text
/home/oleg/bin/zig build abi-differential --summary all > tmp/inbox133_cast_wiring/validation/abi_differential.log 2>&1
result=60/60_cases_30/30_real_functions
log_sha256=f459462c3d3c38ecccd9c6cd8cdba5dd5908f50d2b8a8d5e3f6db71cbe24da46
```

Focused fma and `__multi3` canaries:

```text
/home/oleg/bin/zig build focused-codegen-canaries --summary all > tmp/inbox133_cast_wiring/validation/focused_canaries.log 2>&1
result=2_canaries/35_execution_cases
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
```

Integrated executable:

```text
/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all > tmp/inbox133_cast_wiring/validation/integrated_exe.log 2>&1
result=7/7
log_sha256=cb1541032237fc55394ab3fd02285b62125044dfcdac27f5b76ee8cb50f64fcd
```

Strengthened Tier 2:

```text
/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox133_cast_wiring/validation/strengthened_tier2.log 2>&1
result=pass
log_sha256=88a88b6f0477e84ef6fc88aa34f47c02dbac04755087b1ef774deb9fc5cbd19c
```

No `distribution-all` command was launched. No authorized,
acceptance-grade, accidental, parallel, or serial Tier 3 was run.

## Immutable artifacts and counterbalanced performance

Artifact A was built from accepted Step A; artifact B was built from the
final production commit. The build command in each detached worktree was:

```text
/home/oleg/bin/zig build
```

Both binaries were copied read-only before timing and were never rebuilt
between samples:

```text
artifact_A_commit=83110e82d1cb973d5e299357351890f462959a0b
artifact_A=tmp/inbox133_cast_wiring/perf/artifacts/A/z_llvm
artifact_A_sha256=eddbdabc3cf38c4dc157e8c077a0c739cca83097d6fa9da48accfae44a746e97
artifact_A_mode_size=0555/90270386
artifact_B_commit=3d829cd4f353e2a86a28648a62296a290b681e95
artifact_B=tmp/inbox133_cast_wiring/perf/artifacts/B/z_llvm
artifact_B_sha256=6d2328d3b6fc1eb360ff2d4f0a63570a9923cff1c20d1bf0e4a1f78e83013d76
artifact_B_mode_size=0555/90084690
idle_preflight_sha256=873450bbd42018045fb22c1896f6aba632bcf2179ca16ab2d7cf196bd061f14c
machine_average_idle=96.93%
pinned_cpu0_average_idle=97.68%
competing_zig_or_zllvm_workload=none
```

Every warmup and timed sample used this exact command shape, substituting
only the immutable artifact and output names:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> REPORT
```

Exactly two warmups per artifact ran in `A B A B` order and were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 49.91 | 94,916 |
| B warmup 1 | 49.99 | 94,512 |
| A warmup 2 | 50.97 | 94,912 |
| B warmup 2 | 49.65 | 94,520 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 49.51 | 94,916 | 51.07 | 94,520 | 1.031508786 |
| 2 | BA | 51.32 | 94,912 | 51.12 | 94,520 | 0.996102884 |
| 3 | AB | 51.05 | 94,916 | 51.17 | 94,520 | 1.002350637 |
| 4 | BA | 51.42 | 94,912 | 51.15 | 94,520 | 0.994749125 |
| 5 | AB | 51.42 | 94,916 | 51.23 | 94,516 | 0.996304940 |
| 6 | BA | 51.27 | 94,912 | 51.37 | 94,516 | 1.001950458 |

The metrics were computed and the sixteen report identities were validated
with a Zig-only analyzer; no Python script was used.

```text
median_A_seconds=51.295
median_B_seconds=51.160
median_delta_seconds=-0.135
allowed_delta_seconds=max(2.564750,0.100)=2.564750
aggregate_median_gate=pass
paired_ratio_median=0.999127699
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=94916
B_max_rss_KiB=94520
rss_delta_KiB=-396
rss_gate=pass
retained_reports=16/16_at_49a19f04
paired_metrics_sha256=39d96652b889f5d6205d8fc6993e0ed80dddb5f9cd85313c7fc34957af263ca7
warmup_raw_manifest_sha256=b22bc8fa1670e8a7c2b4dd785a37de2067402f3d50bd7d0cf72a847cfdb78568
warmup_report_manifest_sha256=45546cd44fd9bdb97966f4515020da4bd06c87a171c7688ce41c0f246a08f742
timed_raw_manifest_sha256=e4c00532366bd09c58369d9817663ba7b611c8daa3fff386882e5c40075a2c42
timed_report_manifest_sha256=d47db028d7ceca9761b5b3549f42a12e1ba1089de71f9a6dd567d48d6f9413cb
```

No sample was removed, no additional timed sample was added, and no
discretionary rerun occurred. All three blocking performance criteria pass.
