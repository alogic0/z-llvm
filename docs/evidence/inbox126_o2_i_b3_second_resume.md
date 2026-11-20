# INBOX-126 — O2-3I-B3 second-resume migration

Status: complete; stopped for review. This slice completes the ICMP group
at 44/44. No Tier 3 command was run.

## Frozen input and exact patch

```text
accepted_action_commit=605985f3daebbb48c2fc3f514e5bc40a56f895ec
accepted_action_tree=2dc2ca2019168dcb657c0bda08dcc89177ccce75
starting_head_with_supervisor_docs=8bae3852e9afb44ad53c6408758000b6ed128cfd
preserved_patch=tmp/inbox124_icmp_pair_perf/inbox124_i_b3_hard_stop.patch
preserved_patch_sha256=6c2b4fb2bdcd3c9af277b8e1f420da2ba1c253f967a26e44135b0bace36f542c
applied_production_diff_sha256=6c2b4fb2bdcd3c9af277b8e1f420da2ba1c253f967a26e44135b0bace36f542c
stash_at_0=untouched
```

The patch hash was checked before `git apply --check` and before applying
it. The resulting `composed_selector_icmp.zig` diff hashes to that same
value, proving byte-for-byte application. The amended transaction action,
classifier, planner, and sequencing implementation from `605985f3` was
not changed.

## Production composition

The existing six-stage dispatch is extended only after the current-home
sign-bit stage and before the legacy O1 tail:

1. `isI128EqMinIcmp` routes to `I128EqMinAction`;
2. `isI128SignBitIcmp` routes to `I128SignBitAction`;
3. every other form retains the single legacy O1 authority.

Each admitted form registers its read-only i128 request, seals one outer
`ValueUseTransaction`, opens one subordinate accumulator session, and
commits only after the closed action finishes. The consumer supplies no
pair home, pair choice, register, or sequencing hint. Its diagnostic
mapper uses the retained lhs request handle, maps the closed request/action
errors to the existing diagnostics, and returns authority errors
unchanged.

The structural source guard now enforces the two exact action functions,
the dispatch ordering, one outer transaction/session/commit lifecycle,
the request-scoped mapper, and the absence of raw pair resolution,
materialization, or home inspection in the consumers. Its negative
fixtures reject out-of-file wiring, function relocation, reversed
dispatch, and consumer home inspection.

## Ratchet and semantic ownership

```text
mechanical_bypass_total_before=174
mechanical_bypass_total_after=172
removed=lowerIcmp/materializePairValue×1,lowerIcmp/resolvePairValue×1
frozen_inventory_sha256=6e570be808d2aea9275809471f53846af7f54afdd908ab73e51218579ca8112d
classification_sha256=ebe3b9e93961d4298c0ed50cca7d4341f3949f1448394f988ce46913bdcd827e
classification_reconciliation=254_occurrences/91_functions/150_gateways
sign_bit_wrapper=semantic_ownership_migration_zero_textual_delta
source_guard=31/31
```

The classification TSV records both removed eq-min helper gateways under
O2-3I-B3 and explicitly records the sign-bit wrapper's semantic ownership
transition without inventing a textual occurrence.

## Immutable artifacts and counterbalanced performance

Artifact A was built from the accepted `605985f3` production tree before
wiring. Artifact B was built after the exact preserved production patch.
Both were copied read-only before timing and were never rebuilt between
samples.

```text
build_command=zig build
artifact_A=tmp/inbox126_o2_i_b3_perf/artifacts/A/z_llvm
artifact_A_sha256=10e4e374ab8dd7136dc3deef150c865337091c67a4d833a976e4699a71f8ffdd
artifact_A_mode_size=0555/90775538
artifact_B=tmp/inbox126_o2_i_b3_perf/artifacts/B/z_llvm
artifact_B_sha256=bfd68b3023fa727b28d9fe7d4eb6844c4b804a70b0c943bf8540f5eab61fe1aa
artifact_B_mode_size=0555/90778443
idle_preflight=tmp/inbox126_o2_i_b3_perf/idle_preflight.txt
idle_preflight_sha256=542b60d28b944cac386276b972f8902689e50f227fe202cd4157f4b56d3bb1d4
machine_average_idle=95.72%
pinned_cpu0_average_idle=95.68%
competing_zig_or_zllvm_workload=none
```

The guard/inventory ratchet was finalized after the timed runtime artifact
was frozen. A final rebuild has different non-allocated debug metadata,
but every allocated runtime section (`.rodata`, `.rodata.cst`,
`.rodata.str`, `.eh_frame`, `.eh_frame_hdr`, `.text`, `.tdata`, `.data`,
and `.data.rel.ro`) is byte-identical to the measured B artifact.
The retained section-pair manifest is
`tmp/inbox126_o2_i_b3_perf/artifacts/runtime_sections.sha256`, SHA-256
`ab607a8550f0cd856e640d0640d9161404c6517deb5635aaefa8d47be55e4a30`.
Thus the measured runtime is the final runtime; no additional timing run
was introduced.

Every warmup and timed sample used this exact command shape, substituting
only the immutable artifact and output paths:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> LOG
```

Exactly two warmups per artifact ran in `A B A B` order and were
discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 49.05 | 94,508 |
| B warmup 1 | 48.83 | 94,624 |
| A warmup 2 | 49.15 | 94,508 |
| B warmup 2 | 48.83 | 94,624 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 49.27 | 94,504 | 48.93 | 93,340 | 0.993099249 |
| 2 | BA | 49.24 | 94,396 | 48.66 | 93,972 | 0.988220959 |
| 3 | AB | 49.18 | 94,500 | 48.71 | 93,852 | 0.990443270 |
| 4 | BA | 49.03 | 94,504 | 48.79 | 93,852 | 0.995105038 |
| 5 | AB | 49.12 | 94,496 | 48.79 | 93,920 | 0.993281759 |
| 6 | BA | 49.17 | 94,324 | 48.82 | 93,916 | 0.992881839 |

```text
median_A_seconds=49.175
median_B_seconds=48.790
median_delta_seconds=-0.385
allowed_delta_seconds=max(2.45875,0.100)=2.45875
aggregate_median_gate=pass
paired_ratio_median=0.992990544
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=94504
B_max_rss_KiB=93972
rss_delta_KiB=-532
rss_gate=pass
warmup_raw_manifest_sha256=adbf880328138f32d41ee23439d4249b9dea16fe61c725bf7a20e0de992a6dff
warmup_report_manifest_sha256=eaa06bee3fcf248581df81dd2117605cda3ffbd0572a0f137f7275d17b095b5f
timed_raw_manifest_sha256=c9b63cbbfd702e793a9fc3e41683f85c0549bd09a2ddafceece5d56941b4e65f
timed_report_manifest_sha256=c74c91ecdd5ba4db438edc33c387a7a3d6b06394da8ffcdd6d3bb03e1da12398
paired_metrics_sha256=96caa35f29520d7250f32631f24f3ffcba1576473acd13ff15995a6b58c10286
```

Every one of the four warmup and twelve timed reports re-hashed to
`49a19f04`. No outlier was removed, no timed sample was added, and no
discretionary rerun occurred.

## Frozen identities and frontier

Fresh report exact command (exit 1 is the accepted aggregate-failure
status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox126_o2_i_b3_perf/validation/fresh_full_report.log
```

Accepted object exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox126_o2_i_b3_perf/validation/accepted.o 2> tmp/inbox126_o2_i_b3_perf/validation/accepted.stderr
```

Owner manifest exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox126_o2_i_b3_perf/validation/owner_manifest.tsv 2> tmp/inbox126_o2_i_b3_perf/validation/owner_manifest.stderr
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

All six `.spill128` eq-zero target rows remain at
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-icmp-lhs-loc`. Their retained extract is
`tmp/inbox126_o2_i_b3_perf/validation/spill128_targets.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
The A/B `exp` and `expf` collateral extracts are identical, both SHA-256
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`.
No target advanced.

## Non-Tier-3 validation

Every retained gate log is paired below with its exact command.

Source guard:

```text
zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox126_o2_i_b3_perf/validation/source_guard.log 2>&1
result=31/31
log_sha256=0414948eda860b8364998bae012d15f7021a5685d1c508b9ee0774027e319649
```

Full unit:

```text
zig build test --summary all > tmp/inbox126_o2_i_b3_perf/validation/full_unit.log 2>&1
result=1273/1273
log_sha256=b1f2c5b67775b77b18aee26270728f36b55f6c6ab8a37619eac18c18360a660e
```

ABI differential:

```text
zig build abi-differential --summary all > tmp/inbox126_o2_i_b3_perf/validation/abi_differential.log 2>&1
result=60/60+30/30
log_sha256=707ec645fa9e190db36edb37d67da769cbb7eaa0656e808d291095a635793ab9
```

Focused canaries:

```text
zig build focused-codegen-canaries --summary all > tmp/inbox126_o2_i_b3_perf/validation/focused_canaries.log 2>&1
result=2_canaries/35_execution_cases
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
```

Integrated executable:

```text
zig build distribution-zig-integrated-exe --summary all > tmp/inbox126_o2_i_b3_perf/validation/integrated_exe.log 2>&1
result=7/7
log_sha256=ddfbbeded8bea63c0ad875c1dcf1b853b0079a8e6f97a1d7b13d4ef8159449b7
```

Strengthened Tier 2:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox126_o2_i_b3_perf/validation/strengthened_tier2.log 2>&1
result=29/29_steps,1281/1281_tests
log_sha256=b3faa3fbf485e32a226066087427b4706e4f49d75e32a5553dc95adac2e8ec13
```

No `distribution-all` command was launched. No authorized,
acceptance-grade, accidental, or parallel Tier 3 was run in this slice.
