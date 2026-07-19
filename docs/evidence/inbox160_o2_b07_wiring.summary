# INBOX-160 — B07 production wiring

Status at the production commit: B07 wiring and every correctness gate are
complete. The required post-final-tree counterbalanced performance
evidence is appended by the follow-up immutable evidence commit. No Tier 3
was run.

## Scope and ownership

The complete B07 named/named scalar family now uses the existing shared
instruction-level `ValueUseTransaction` consumer. The consumer:

1. registers lhs then rhs from semantic identities and expected
   type/register class;
2. seals before mutation;
3. prepares and materializes both operands through the canonical Q1
   authority;
4. executes the closed `NamedScalarBinaryAction`; and
5. commits only after the accumulator result is finalized.

Request failures map to the legacy lhs/rhs diagnostics only through the
matching `failedRequestIs` handle. Authority errors propagate unchanged.
There is no consumer-side source resolution, home inspection, retry,
legacy fallback, or function-name admission.

The legacy `scalar_named_b07_rhs_admission` owner is removed completely.
The source guard now:

- requires the exact B07 transactional dispatch after B06;
- rejects a missing or reclassified B07 dispatch;
- rejects reintroduction of the B07 residual owner;
- rejects any transaction-to-legacy fallback edge; and
- continues to enforce the exact shared consumer lifecycle.

R03 `scalar_immediate_live_shared_source_preservation`, R04
`scalar_immediate_multi_alias_preservation`, pair-result paths, and every
prior exclusion remain dispatched before transaction creation and are
unchanged.

## Frozen action and Q1 surface

The complete action/Q1 surface remains byte-identical to accepted
`17bfa6d7`:

```text
value_use/actions/scalar_named.zig
  8ca8e37e93513f2e40c5dd08e0b389ff743ea07944d033b6ec18fcdbeafe48c1
value_use/model.zig
  eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649
value_use/planning/lifetime_admission.zig
  35bb4d9f12bd372063692aa9cb55333ce06b47b39d0964d13be7bd121e20b1b6
```

No action, model, admission, forward-plan, physical-home, pair, cycle, or
fixed-register capability changed. The scoped production patch is:

```text
path=tmp/inbox160_o2_b07_wiring/production.patch
sha256=49fde159cb72df810826fee4d71210fbb88c46cc1578f66e86015c040fe01833
```

## Ratchet

`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv`
removes exactly the single B07 row containing:

```text
resolveValue×4
emitValueIntoScratch×2
emitValueIntoScratchAndRelocate×1
emitBinaryLocIntoAccumulator×1
```

No other inventory row is removed and no helper-collapse credit is
claimed:

```text
ratchet_before=148
B07_direct_removals=8
helper_collapses=0
ratchet_after=140
```

The updated inventory SHA-256 is
`92f921c3ae0e87ec25f6ed64803d667789991831da134a466438474ee29eb755`,
and the source guard pins that exact identity.

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox160_o2_b07_wiring/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox160_o2_b07_wiring/validation/accepted.o 2> tmp/inbox160_o2_b07_wiring/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox160_o2_b07_wiring/validation/owner_manifest.tsv 2> tmp/inbox160_o2_b07_wiring/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox159_o2_b07_isolation/results/baseline/accepted.o tmp/inbox160_o2_b07_wiring/validation/accepted.o > tmp/inbox160_o2_b07_wiring/validation/function_diff.tsv

command=rg 'composed-block-icmp-lhs-loc' tmp/inbox160_o2_b07_wiring/validation/fresh_full_report.log > tmp/inbox160_o2_b07_wiring/validation/frontier_rows.log
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167 composed / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
frontier_rows=6
frontier_rows_sha256=87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f
six_B07_symbols_sha256=53512669d3702b826ce4c6678748479228132e8e02b62cdcc6104794ea7169ac
```

The exact whole object and `285/0/0` comparison prove byte identity for
all six restored B07 functions and every previously accepted function.
The unchanged report proves the six `.spill128` frontier rows remain at
`composed-block-icmp-lhs-loc`.

## Correctness gates

Every command below ran against the final production source state. Logs
are retained under `tmp/inbox160_o2_b07_wiring/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/source_guard.log
result=53/53 tests
log_sha256=9c553d8756d84d0f14fe3c65c35f4aa1dc3430c056bf497d77ca3adc32d69895
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/full_unit.log
result=7/7 steps; 1356/1356 tests
log_sha256=0effbd74afb8e7d34fa758d637917cdf1a6618a53e3c0f1de8b7f7a9f1c5dde9
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=69b668e6b3ba9662c124ecf7172eea522b34185bea7663518114b03967250ac4
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=1bde3882401aa625fcc9975f3c0868ee04b729f5cb6e2df42b2522643562d791
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox160_o2_b07_wiring/validation/strengthened_tier2.log
result=29/29 steps; 1364/1364 tests
log_sha256=f2716eda14ec7014fb7c628bdc3f0360dbc4b65dd7ec06026f53eafc8093bc00
```

No `distribution-all` command and no Tier 3 command was run.

## Counterbalanced performance

The timed artifacts were frozen only after the complete production source,
guard, and initial evidence tree was committed:

```text
A_commit=ee2ac4d7a56d811484cd6b9c6bb99ba1d4b936db
A_tree=3ed16e277bb25c27841e9e4a112d028d0ed37682
B_commit=19c4c3b86a0f604cb5e566b4a776c95843fdcce0
B_tree=a907dcf6498b1a15784db241b019887b48e2ed4a
```

Immutable artifacts:

```text
A_path=tmp/inbox160_o2_b07_wiring/perf/artifacts/A/z_llvm
A_mode=0555
A_size_bytes=106245858
A_sha256=a15fc820f2c4a9a4238c9e8665fb0227fdec58676556de2089e426dec8efdf2c
B_path=tmp/inbox160_o2_b07_wiring/perf/artifacts/B/z_llvm
B_mode=0555
B_size_bytes=106175288
B_sha256=e611b92ca44d023a6686c84559b512f641a8f78b4f9ef32ca55d1e5409107e84
```

The idle preflight was captured at `2026-07-18T19:05:49-05:00` with load
averages `0.71 / 1.23 / 1.18` and CPU 0 average idle of `98.66%`:

```text
path=tmp/inbox160_o2_b07_wiring/perf/idle_preflight.txt
sha256=f17f7dd050d389093413762e4d3ca2d9fccde9456b4795358b7d600c3167378e
```

The artifacts were not rebuilt between samples. Exactly two warmups per
artifact were discarded, followed by the required six pairs in
`AB, BA, AB, BA, AB, BA` order. Every timed sample was retained and there
was no discretionary rerun.

Commands and tool identities:

```text
command=/home/oleg/bin/zig run tmp/inbox160_o2_b07_wiring/run_counterbalanced.zig 2>&1 | tee tmp/inbox160_o2_b07_wiring/perf/run_counterbalanced.log
runner_sha256=83c4ef35f422f45b124c2d562073191bc22c5791280175200583c0b0db4729f7
run_log_sha256=d142895d36a766f2de28ff939881c1ca0671ca8a7635c0f9224c7c14f74ff6ec

command=/home/oleg/bin/zig run tmp/inbox160_o2_b07_wiring/analyze_counterbalanced.zig 2>&1 | tee tmp/inbox160_o2_b07_wiring/perf/paired_metrics.tsv
analyzer_sha256=24c06715e68b3624b63310130fb35008a76eb6ac7e8686e939a7f322ed0c80fd
metrics_sha256=56c67ca4e0b2b60a0370933eba1cb5b36fc0e3250a4ea017edbc166aa8b773bb
```

All samples (`wall_seconds`, `maximum_rss_kib`):

```text
warmup1_A  48.40  89124
warmup1_B  48.84  89324
warmup2_A  48.38  89052
warmup2_B  48.88  88880

pair1_AB  A=48.38/89124  B=48.60/88932  B/A=1.004547334
pair2_BA  A=48.31/89132  B=48.77/89252  B/A=1.009521838
pair3_AB  A=48.38/89128  B=49.00/89256  B/A=1.012815213
pair4_BA  A=48.62/89164  B=48.76/89252  B/A=1.002879473
pair5_AB  A=48.45/89128  B=48.84/89252  B/A=1.008049536
pair6_BA  A=48.51/89128  B=48.89/89264  B/A=1.007833436
```

Blocking criteria:

```text
median_A_seconds=48.415
median_B_seconds=48.805
median_delta_seconds=+0.390
allowed_delta_seconds=max(48.415*0.05,0.100)=2.421
aggregate_median_gate=PASS

median_paired_ratio_B_over_A=1.007941486
paired_ratio_limit=1.05
paired_ratio_gate=PASS

maximum_rss_A_kib=89164
maximum_rss_B_kib=89264
maximum_rss_delta_kib=+100
maximum_rss_limit_kib=16384
rss_gate=PASS

exact_reports=16/16
overall=PASS
```

The complete raw and normalized report sets are pinned by sorted
manifests:

```text
raw_sample_manifest_files=16
raw_sample_manifest_sha256=6c6456cf7a07bcc8d77620497f26d373a51c3658fcda961e6622988a8afe201a
report_manifest_files=16
report_manifest_sha256=1d010f255932b8dd08d1a63662e0dbce51b83c75e4ab8359f3992c4670e5785b
```

The counterbalanced performance gate passes both timing criteria and the
RSS criterion. No Tier 3 was run. INBOX-160 therefore closes with B07
fully wired, ratchet `140`, exact frozen identities, and no cohort
movement.
