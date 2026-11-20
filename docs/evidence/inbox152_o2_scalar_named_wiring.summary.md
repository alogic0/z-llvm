# INBOX-152 O2 scalar Slice 3 Stage 2 — B01 + I52B0 wiring

Status at the production commit: correctness gates complete; performance
evidence is appended by the required follow-up immutable evidence commit.
No Tier 3 was run.

## Scope and ownership

Only the two INBOX-151-approved complete families are wired through
`ValueUseTransaction`:

- B01: named i1 `and`/`or`;
- I52B0: the exact guarded i52 shift envelope.

The dormant action/model implementation is unchanged from accepted commit
`0661c8cd`:

```text
value_use/actions/scalar_named.zig
  6de4086bb1285db52ebac352acb743e49a6778b2407def137ab71d56b9464416
value_use/model.zig
  b81a0173dd7af97a346df71c030e6655d925891496f6bf7049e3e6cf8f13ab76
```

Every retained family is routed to a complete legacy owner before any O2
transaction is created:

| Family | Guard-enforced residual owner | Admission class |
|---|---|---|
| B03 | `scalar_named_b03_interval_admission` | interval admission |
| B04 | `scalar_named_b04_interval_admission` | interval admission |
| B05 | `scalar_named_b05_interval_admission` | interval admission |
| B06 | `scalar_named_b06_interval_admission` | interval admission |
| B07 | `scalar_named_b07_rhs_admission` | RHS admission |

There is no transactional attempt followed by legacy fallback. The guard
requires zero `ValueUseTransaction.begin` occurrences in `lowerBinary` and
in all five retained owners; it freezes each owner's accepted legacy
authority, bypass-operation inventory, and dispatch order. Negative fixtures
reject a missing/renamed owner and a transaction introduced into either an
interval owner or the distinct RHS owner.

R03 `scalar_immediate_live_shared_source_preservation`, R04
`scalar_immediate_multi_alias_preservation`, pair/i128 ownership, exact-EI
positioning, and all prior exclusions remain unchanged.

## Ratchet

`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` removes
exactly the two accepted gateways:

- B01 removes one `lowerBinary/emitValueIntoScratch`;
- I52B0 removes one `lowerI52Binary/emitValueIntoScratch`.

The retained operations are re-attributed, without count loss, to their
five exact residual owners. Inventory SHA-256 is
`135b0da652ff4de3df720555f77f022be6da657bd2b33beb0e1876f23181dc89`.
The exact operation total is 152:

```text
154 - B01(1) - I52B0(1) - helper_collapses(0) = 152
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox152_o2_scalar_named_wiring/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox152_o2_scalar_named_wiring/validation/accepted.o 2> tmp/inbox152_o2_scalar_named_wiring/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox152_o2_scalar_named_wiring/validation/owner_manifest.tsv 2> tmp/inbox152_o2_scalar_named_wiring/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox151_o2_family_isolation/results/baseline/accepted.o tmp/inbox152_o2_scalar_named_wiring/validation/accepted.o > tmp/inbox152_o2_scalar_named_wiring/validation/function_diff.tsv
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
```

The six `composed-block-icmp-lhs-loc` rows remain exact; their extracted
record has SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
Whole-object and 285/0/0 per-function identity prove the `exp2` stream is
unchanged. The focused validator independently proves the fma and
`__multi3` streams, symbols, helpers, and executable cases.

## Correctness gates

Every command below ran against the final production source state. Logs are
retained under `tmp/inbox152_o2_scalar_named_wiring/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/source_guard.log
result=50/50 passed
log_sha256=973bd4f8ee08f195dff21cc112d9191b5d5e57a17de52c87f96aaf093ed208c3
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/full_unit.log
result=7/7 steps; 1339/1339 tests
log_sha256=4e7329608e466c557aacbb7be75df7808edb2ba55738de9a922e944b3ad8e48c
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=11ded6f807f226f585e223ceb2242054102f34236331404001d29f2d992ab999
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 object/stream/symbol/helper checks exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/validation/strengthened_tier2.log
result=29/29 steps; 1347/1347 tests
log_sha256=099d7ab3f695bf4f64ad9d415f2581edfc88cd1364ca4e283d1e08153709588c
```

No `distribution-all` command and no Tier 3 command was run.

## Counterbalanced performance

The production tree was committed before either timed artifact was frozen.
Both artifacts were built in separate clean detached worktrees, copied to
the evidence directory, and set mode 0555 before the first warmup. Neither
artifact was rebuilt or modified during the batch.

```text
A_commit=eb1ad794fe243613b6dce4f4fff4d297e08088a7
A_tree=b8e5f979e93c809a1c3b564fbaa01b899944ba0a
A_artifact_sha256=15463ed61efbf480a79e0bc532c3f28cda842b2ea2001729761fb0d698da03dd
A_artifact_mode=0555
A_artifact_bytes=92805947

B_commit=e048ff5cb7818f0b1e99d6971b9542562ffcf086
B_tree=5c5bfa8cc202ec6403799b56df2e613275bdeb22
B_artifact_sha256=043d25e21480ebf56ff211b17d6a324a404111ecdd8993420d1a8018dca76335
B_artifact_mode=0555
B_artifact_bytes=107646818

build_command=/home/oleg/bin/zig build
A_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
B_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
```

The idle preflight captured the process list, load average, and three
one-second CPU-0 samples immediately before the batch. CPU 0 averaged
96.98% idle. Its retained record has SHA-256
`84bf994cffea69079d7cd5610cec40942c5d50295bdf15d4e330c50ac18ca25b`.

The measurement was orchestrated by a Zig script. Every invocation used:

```text
command=/usr/bin/time -f "%e %M" -o <raw> taskset -c 0 env LC_ALL=C <A-or-B>/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
runner_command=/home/oleg/bin/zig run tmp/inbox152_o2_scalar_named_wiring/run_counterbalanced.zig 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/perf/run_counterbalanced.log
analyzer_command=/home/oleg/bin/zig run tmp/inbox152_o2_scalar_named_wiring/analyze_counterbalanced.zig 2>&1 | tee tmp/inbox152_o2_scalar_named_wiring/perf/paired_metrics.tsv
runner_sha256=f93f036f4e8585827dbeaa047badbd2a9bb61ea0c3e7ae1c94a827c6c1c6a034
analyzer_sha256=728d1ac34e2d5988d1ce3a9475b8bff76fab69a326953744bfd157103c2381c5
runner_log_sha256=d142895d36a766f2de28ff939881c1ca0671ca8a7635c0f9224c7c14f74ff6ec
metrics_log_sha256=47e2055e64bb232b7e62522f99ee448ed9d894aeecd6590eb75de03331616411
```

Exactly two warmups per artifact were discarded:

| Warmup | Seconds | Peak RSS KiB |
|---|---:|---:|
| A1 | 47.65 | 91036 |
| B1 | 47.76 | 88092 |
| A2 | 47.66 | 91032 |
| B2 | 47.69 | 88260 |

All six timed pairs were retained in the prescribed
AB/BA/AB/BA/AB/BA order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
|---:|---|---:|---:|---:|---:|---:|
| 1 | AB | 47.76 | 91024 | 47.70 | 88348 | 0.998743719 |
| 2 | BA | 47.73 | 91036 | 47.71 | 88348 | 0.999580976 |
| 3 | AB | 47.83 | 91036 | 47.67 | 88336 | 0.996654819 |
| 4 | BA | 47.81 | 91032 | 47.62 | 88344 | 0.996025936 |
| 5 | AB | 47.68 | 91024 | 47.78 | 88332 | 1.002097315 |
| 6 | BA | 47.70 | 91024 | 47.73 | 88348 | 1.000628931 |

Acceptance calculation:

```text
median_A_seconds=47.745
median_B_seconds=47.705
median_delta_seconds=-0.040
allowed_delta_seconds=max(2.387, 0.100)=2.387
median_paired_ratio_B_over_A=0.999162347
A_max_rss_KiB=91036
B_max_rss_KiB=88348
rss_delta_KiB=-2688
wall_pass=true
paired_ratio_pass=true
rss_pass=true
report_hashes_exact=16/16
```

The gate passes both wall-time criteria and the RSS criterion. All four
warmup reports and all twelve timed reports are exactly
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
The retained raw-sample manifest contains 16 entries and has SHA-256
`af8a79fa5521269f3ad627b5f7610824924b0f2167876e30cbbdb15ee2ef1dec`;
the retained report manifest contains 16 entries and has SHA-256
`665d5d04635b21d606d6a9b7a9cf7bd667420c348b5f504ec0f35265a11d72c1`.

This was the sole measurement batch. No sample was removed, no artifact was
rebuilt between samples, and no discretionary rerun was performed.
