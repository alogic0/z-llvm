# INBOX-166 — M64 production wiring

Status at the production commit: complete M64 wiring and every correctness
gate are complete. The required post-final-tree counterbalanced
performance evidence is appended by the follow-up immutable evidence
commit. No Tier 3 was run.

## Scope and ownership

The complete `mul i64 <named>, <named>` family now uses one
instruction-level `ValueUseTransaction` authority. `lowerMul64`:

1. begins one transaction;
2. registers lhs and rhs in source order from semantic identities and
   expected i64/GPR64 contracts;
3. attaches the frozen `ScalarMultiplyAction`;
4. seals before mutation;
5. prepares and materializes through canonical Q1;
6. executes the closed action; and
7. commits only after the durable result is complete.

Request errors map to the legacy lhs/rhs/destination diagnostics only
through the matching `failedRequestIs` handle. Authority errors
propagate unchanged. There is no consumer-side home inspection,
resolution, retry, attempt-then-fallback, function-name admission, or
partial-family legacy route.

The legacy `lowerMul64SpillLhsThroughRax` path is subsumed by the closed
action's internally derived M64-R plan. M64-D versus M64-R selection
remains canonical transaction/action state, never a consumer hint.

R03 `scalar_immediate_live_shared_source_preservation`, R04
`scalar_immediate_multi_alias_preservation`, pair/full-product,
fixed-register, remainder, and cycle owners remain unchanged and
pre-transaction.

## Frozen action, lifetime, and Q1 surface

The production consumer is the only capability change. These frozen
surfaces are byte-identical to the accepted dormant/re-isolated model:

```text
value_use/actions/scalar_multiply_divide.zig
  9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0
value_use/model.zig
  e48c949d0e04a24e7fae8c2e54ae48562b2c38c4a2fb403db8630307fd81bcd7
value_use/planning/lifetime_admission.zig
  fff2a6c791f22c47a6b7686fc784919cb35c0c0e6fad0ab0ebbd8e7b6b213f45
```

No action, model, lifetime, Q1, forward-plan, physical-home, pair, cycle,
or fixed-register authority changed.

The scoped pre-summary production patch is retained at
`tmp/inbox166_o2_m64_wiring/production.patch`, SHA-256
`12e93b37c9a9dc813ed0126d9085374a1686ec66557a78d6281b4bdfd2fd3d7a`.

## Scalar-local helper ownership

The legacy scalar-local wrappers removed with `lowerMul64` are:

```text
plannedScratch64RegForResult
scratch64RegForUseAvoiding
reusableScratch64RegForInPlace
spillScratch64SourceForInPlace
scratch64RegIsAvailableForUse
```

An exact search for declarations in `composed_selector_scalar.zig` and
for qualified `selector_scalar.<name>` consumers returns zero rows:

```text
path=tmp/inbox166_o2_m64_wiring/validation/scalar_local_helper_owners.log
bytes=0
sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The selector-state authorities with similar names remain in place and
retain their existing owners. No helper-collapse ratchet credit is
claimed.

## Structural guard

The source guard now requires the complete M64 lifecycle only inside
`lowerMul64`, including exact request count/order, action attachment,
seal/prepare/materialize/execute/commit counts, and the two-handle
diagnostic mapper. It rejects:

- M64 action use in another production file;
- a missing/reclassified action attachment;
- reintroduction of `lowerMul64SpillLhsThroughRax`;
- raw resolution or materialization in the migrated leaf; and
- reintroduction of the removed scalar-local wrappers.

Failure-provenance accounting now includes exactly the two M64 request
queries. The existing R03/R04 and other residual guards remain
unchanged.

## Ratchet

The frozen bypass TSV uses one function row containing four
`lowerMul64` occurrences and one function row containing the single
`lowerMul64SpillLhsThroughRax` occurrence. Those two aggregate TSV rows,
and exactly those five direct gateways, are removed:

```text
lowerMul64: emitValueIntoScratch×2 + resolveValue×2 = 4
lowerMul64SpillLhsThroughRax: resolveValue×1 = 1

ratchet_before=140
M64_direct_removals=5
helper_collapses=0
ratchet_after=135
```

The updated inventory has SHA-256
`3928114a0fcc55d5f18a367b29865925396c80c3a2589e02c87f4e0a73b23537`;
the source guard pins that exact identity.

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox166_o2_m64_wiring/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox166_o2_m64_wiring/validation/accepted.o 2> tmp/inbox166_o2_m64_wiring/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox166_o2_m64_wiring/validation/owner_manifest.tsv 2> tmp/inbox166_o2_m64_wiring/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox165_o2_m64_reisolation/results/baseline/accepted.o tmp/inbox166_o2_m64_wiring/validation/accepted.o > tmp/inbox166_o2_m64_wiring/validation/function_diff.tsv

command=rg 'composed-block-icmp-lhs-loc' tmp/inbox166_o2_m64_wiring/validation/fresh_full_report.log > tmp/inbox166_o2_m64_wiring/validation/frontier_rows.log
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
frontier_rows=6
frontier_rows_sha256=87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f
```

The exact whole object and 285/0/0 comparison prove byte identity for
the complete accepted cohort. The unchanged report proves that none of
the six `.spill128` frontier rows moved.

## Correctness gates

Every command below ran after the final production source change. Logs
are retained under `tmp/inbox166_o2_m64_wiring/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/source_guard.log
result=55/55 tests passed
log_sha256=56b813af5fee8ca3bd9737211608fad20cdeccd5a10ccb8fa8ea11c6a34950e5
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/full_unit.log
result=7/7 steps; 1365/1365 tests passed
log_sha256=6eacde41895eaca89097f86f065e111936433342378aabc9645ab257063b7ce5
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=3cb2f3b54a80a8e00e725ca9a1e8a093cbbcd46311903a7bbebcc10de9685b5a
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/focused_canaries.log
result=2/2 canaries; 35 execution cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=1bde3882401aa625fcc9975f3c0868ee04b729f5cb6e2df42b2522643562d791
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox166_o2_m64_wiring/validation/strengthened_tier2.log
result=29/29 steps; 1373/1373 tests; integrated-exe 7/7; ABI 60/60 + 30/30
log_sha256=474fcd8067633d8107726e75b9dab9ee687401102b10b1504ba4b93740f9a443
```

No `distribution-all` command and no Tier 3 command was run.

## Counterbalanced performance

The timed artifacts were frozen only after the complete production source,
guard, inventory, and initial evidence tree was committed:

```text
A_commit=842a8a224b3545f221a0a6f009f79f69b181bc87
A_tree=530f96bea82b42dca00eefec1047548810e6e517
B_commit=50acec11e5fc257a6add7e74646237f64ccbdd7d
B_tree=6975178c35e5a799db54010722b1aeb7b87023a6
```

Both binaries were built once in clean detached worktrees and then copied
to immutable mode `0555`. There were no rebuilds between samples:

```text
A_build_command=cd tmp/inbox166_o2_m64_wiring/perf/worktree_A && /home/oleg/bin/zig build 2>&1 | tee ../build_A.log
A_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
A_path=tmp/inbox166_o2_m64_wiring/perf/artifacts/A/z_llvm
A_mode_size=0555/104769314
A_sha256=50632dff809dff6d81f6363b1b0888686700013fb671bc1f504f00986fea8480

B_build_command=cd tmp/inbox166_o2_m64_wiring/perf/worktree_B && /home/oleg/bin/zig build 2>&1 | tee ../build_B.log
B_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
B_path=tmp/inbox166_o2_m64_wiring/perf/artifacts/B/z_llvm
B_mode_size=0555/104714189
B_sha256=0e1937c4c3006e11976d1f4fe3b6a4c8e0af7b76d2ed14dab4928d334ea361ea
```

The idle preflight was captured at `2026-07-18T22:14:30-05:00` with load
averages `1.15 / 1.02 / 1.29` and CPU 0 average idle of `96.32%`:

```text
path=tmp/inbox166_o2_m64_wiring/perf/idle_preflight.txt
sha256=0de391f095ef9c5243f56f80f62deb59466205b216f2f320f1c931cff1a17db3
```

Exactly two warmups per artifact were discarded, followed by the required
six pairs in `AB, BA, AB, BA, AB, BA` order. Every timed sample was
retained. There was no discretionary rerun.

Commands and Zig tool identities:

```text
command=/home/oleg/bin/zig run tmp/inbox166_o2_m64_wiring/run_counterbalanced.zig 2>&1 | tee tmp/inbox166_o2_m64_wiring/perf/run_counterbalanced.log
runner_sha256=9b5c97fbd990cb7233bd04bd70125b459da85cccb8ce469726be558ce5d858be
run_log_sha256=d142895d36a766f2de28ff939881c1ca0671ca8a7635c0f9224c7c14f74ff6ec

command=/home/oleg/bin/zig run tmp/inbox166_o2_m64_wiring/analyze_counterbalanced.zig 2>&1 | tee tmp/inbox166_o2_m64_wiring/perf/paired_metrics.tsv
analyzer_sha256=0db2760411f459a7afb14b4de64034a055c9b7cd3b35aa2ea0ce827b96611040
metrics_sha256=04fe50f4d674a604ce1f3badb9a29f88d0074985e5c1a9188dd4e9edc2c63c7f
```

All samples (`wall_seconds`, `maximum_rss_kib`):

```text
warmup1_A  48.72  88176
warmup1_B  48.45  89352
warmup2_A  48.94  89092
warmup2_B  48.53  89488

pair1_AB  A=48.90/89124  B=48.53/89352  B/A=0.992433538
pair2_BA  A=48.79/89096  B=48.62/89356  B/A=0.996515679
pair3_AB  A=48.81/89104  B=48.74/89360  B/A=0.998565868
pair4_BA  A=48.81/89104  B=48.60/89352  B/A=0.995697603
pair5_AB  A=48.72/89100  B=48.75/89352  B/A=1.000615764
pair6_BA  A=48.71/89096  B=48.49/89364  B/A=0.995483474
```

Blocking criteria:

```text
median_A_seconds=48.800
median_B_seconds=48.610
median_delta_seconds=-0.190
allowed_delta_seconds=max(48.800*0.05,0.100)=2.440
aggregate_median_gate=PASS

median_paired_ratio_B_over_A=0.996106641
paired_ratio_limit=1.05
paired_ratio_gate=PASS

maximum_rss_A_kib=89124
maximum_rss_B_kib=89364
maximum_rss_delta_kib=+240
maximum_rss_limit_kib=16384
rss_gate=PASS

exact_reports=16/16
overall=PASS
```

The complete raw and normalized report sets are pinned by sorted
manifests:

```text
raw_sample_manifest_files=16
raw_sample_manifest_sha256=c967d9da706bd48897a01505291d2713f97b5c18f8f4f2b76d896994f1f95d7e
report_manifest_files=16
report_manifest_sha256=4b7bfd4f25242dc636404558299723ff3c30a1930389243521df54418c92dd98
```

The counterbalanced performance gate passes both timing criteria and the
RSS criterion. No Tier 3 was run.
