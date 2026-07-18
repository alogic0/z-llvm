# INBOX-157 — B03+B04+B05+B06 scalar named wiring

Status at the production commit: production wiring and every correctness
gate are complete. Counterbalanced performance evidence is appended by the
required follow-up immutable evidence commit. No Tier 3 was run.

## Scope and ownership

Exactly the four INBOX-156-accepted complete families now use one
instruction-level `ValueUseTransaction`:

- B03: named narrow multiply;
- B04: named narrow shift;
- B05: named wide/exact-EI shift;
- B06: named wide exact-EI binary.

The shared consumer registers lhs then rhs, seals before mutation,
prepares/materializes both uses, executes the closed named-scalar action,
and commits only after the complete result is finalized. Request failures
are mapped only through the matching `failedRequestIs` handle; authority
errors propagate unchanged. There is no transactional attempt followed by
legacy fallback.

B07 remains routed before transaction creation through the exact owner
`scalar_named_b07_rhs_admission`. Its legacy resolution, accumulator
preservation, displacement, and result authorities are unchanged. R03
`scalar_immediate_live_shared_source_preservation`, R04
`scalar_immediate_multi_alias_preservation`, B07, and all prior
pair/result exclusions retain their helper ownership; helper-collapse
credit is zero.

The action, central model, and lifetime/forward-Q1 implementation remain
frozen at accepted commit `3534551d`:

```text
value_use/actions/scalar_named.zig
  6de4086bb1285db52ebac352acb743e49a6778b2407def137ab71d56b9464416
value_use/model.zig
  eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649
value_use/planning/lifetime_admission.zig
  35bb4d9f12bd372063692aa9cb55333ce06b47b39d0964d13be7bd121e20b1b6
```

The source guard admits the shared action consumer only at the four exact
semantic dispatch sites, rejects reintroduction of any B03–B06 residual,
rejects an attempt-then-fallback edge, and continues to require the exact
B07 owner and its zero-transaction legacy shape.

## Ratchet

`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv`
removes exactly:

```text
composed_selector_scalar.zig scalar_named_b03_interval_admission emitValueIntoScratch×1
composed_selector_scalar.zig scalar_named_b04_interval_admission emitValueIntoScratch×1
composed_selector_scalar.zig scalar_named_b05_interval_admission emitValueIntoScratch×1
composed_selector_scalar.zig scalar_named_b06_interval_admission emitValueIntoScratch×1
```

No other row is removed. The updated inventory SHA-256 is
`e588e8087a61f934fef863dc6ae1b2e3062d1ed118ba13ae5188114c3cda95b2`,
and the source guard pins that exact hash.

```text
152 - B03(1) - B04(1) - B05(1) - B06(1)
    - helper_collapses(0)
  = 148
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox157_o2_scalar_named_wiring2/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox157_o2_scalar_named_wiring2/validation/accepted.o 2> tmp/inbox157_o2_scalar_named_wiring2/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox157_o2_scalar_named_wiring2/validation/owner_manifest.tsv 2> tmp/inbox157_o2_scalar_named_wiring2/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox151_o2_family_isolation/results/baseline/accepted.o tmp/inbox157_o2_scalar_named_wiring2/validation/accepted.o > tmp/inbox157_o2_scalar_named_wiring2/validation/function_diff.tsv

command=rg 'composed-block-icmp-lhs-loc' tmp/inbox157_o2_scalar_named_wiring2/validation/fresh_full_report.log > tmp/inbox157_o2_scalar_named_wiring2/validation/frontier_rows.log
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
```

Whole-object and 285/0/0 per-function identity prove every accepted family
stream and `exp2` remain byte-identical. The focused canaries independently
prove the fma and `__multi3` object, stream, symbol, helper, and executable
contracts.

## Correctness gates

Every command below ran against the final production source state. Logs are
retained under `tmp/inbox157_o2_scalar_named_wiring2/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/source_guard.log
result=52/52 passed
log_sha256=afce097d11ff32508e741aee845e294343961217ea1b11461acb71d5acdac818
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/full_unit.log
result=7/7 steps; 1353/1353 tests
log_sha256=a41c0484b26d0a212acf53b171a0b93ca9efbb6a7c570f945bfc2904feedabf2
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=7da0e9467b31e7dc46a54faf02e2533aae216915f82e2678dbbb29dbbb691c14
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/validation/strengthened_tier2.log
result=29/29 steps; 1361/1361 tests
log_sha256=229a41c97b5f614ef4cb9963f64eae3dded973ba3c2066f68982c8d83abc0084
```

No `distribution-all` command and no Tier 3 command was run.

## Counterbalanced performance

The production source commit was frozen before either timed artifact was
built:

```text
production_commit=6b478652108ee431acb2ffdc216c7d383c0c0794
production_tree=3b582b7f313f86d9a8b665f9830069362696f3ef
```

The immutable comparison artifacts were built once in detached worktrees
and were not rebuilt between samples:

```text
A_commit=16222bf2c67a7918655b23e27e26fc691e3ca8c2
A_tree=0253350e3f9faa0e99ce8bc94d4305f5df713f65
A_build_command=cd tmp/inbox157_o2_scalar_named_wiring2/perf/worktree_A && /home/oleg/bin/zig build
A_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
A_artifact_sha256=51bc1759b814546760a200c16173ea4e1ada2f2c6ee22ab197d8dd4c01df9e58
A_artifact_mode=0555
A_artifact_bytes=106218082

B_commit=6b478652108ee431acb2ffdc216c7d383c0c0794
B_tree=3b582b7f313f86d9a8b665f9830069362696f3ef
B_build_command=cd tmp/inbox157_o2_scalar_named_wiring2/perf/worktree_B && /home/oleg/bin/zig build
B_build_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
B_artifact_sha256=0e33d931c45a98d7dcdce0281d0d9dbcfba4aaf729c96ba926cee0819c52052e
B_artifact_mode=0555
B_artifact_bytes=106246072
```

The idle preflight recorded load averages `1.12/1.20/1.14`; pinned CPU 0
was 92.00%, 98.00%, and 98.02% idle, averaging 96.01% idle. No selector or
Zig build was running. The complete process and CPU record is retained at
`tmp/inbox157_o2_scalar_named_wiring2/perf/idle_preflight.txt`,
SHA-256
`6ea675f50f4b67eb684c1f167d2c4456e1f8991c600434b8311f4a263f538864`.

The runner pinned every sample to CPU 0, used `LC_ALL=C`, the same frozen
compiler-rt input and selector arguments, and invoked the immutable
artifact through `/usr/bin/time -f "%e %M"`. Exactly two warmups per
artifact were discarded, followed by the sole retained sequence
`AB, BA, AB, BA, AB, BA`. No sample was removed and no discretionary
rerun occurred.

```text
command=/home/oleg/bin/zig run tmp/inbox157_o2_scalar_named_wiring2/run_counterbalanced.zig 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/perf/run_counterbalanced.log
runner_sha256=1a43a53cd88cafe2d7be37da66c7b151e03a3f65b96c7262275f2f8a8ea6656a
runner_log_sha256=d142895d36a766f2de28ff939881c1ca0671ca8a7635c0f9224c7c14f74ff6ec

command=/home/oleg/bin/zig run tmp/inbox157_o2_scalar_named_wiring2/analyze_counterbalanced.zig 2>&1 | tee tmp/inbox157_o2_scalar_named_wiring2/perf/paired_metrics.tsv
analyzer_sha256=47020ace269c4728f288ea354baeb548fd60285a628442c86b4c0d2d45e962af
metrics_sha256=2e709631ee9c42ab0f238c8463ed32fcba1c46355e8e2dee457a25d924b5f5df
```

All samples are retained below as `seconds / maximum RSS KiB`:

```text
warmup1_A  48.06 / 88820
warmup1_B  48.20 / 89120
warmup2_A  47.90 / 88816
warmup2_B  48.09 / 89128

pair  order  A seconds/RSS  B seconds/RSS  B/A
1     AB     47.94/88760    48.08/89136    1.002920317
2     BA     48.16/88060    48.11/89128    0.998961794
3     AB     48.07/88808    47.97/89128    0.997919700
4     BA     48.00/88820    47.96/89124    0.999166667
5     AB     47.94/88820    48.19/89124    1.005214852
6     BA     47.94/88816    47.98/89124    1.000834376
```

Gate result:

```text
median_A_seconds=47.970
median_B_seconds=48.030
median_delta_seconds=+0.060
allowed_delta_seconds=2.399
aggregate_median_pass=true
median_paired_ratio_B_over_A=1.000000521
paired_ratio_limit=1.05
paired_ratio_pass=true
A_max_rss_kib=88820
B_max_rss_kib=89136
rss_delta_kib=+316
rss_limit_kib=16384
rss_pass=true
reports_exact=16/16
overall=PASS
```

Every warmup and retained report independently hashes to
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
The complete raw and report manifests are retained:

```text
raw_manifest_sha256=101be89c20e19734c42511866db998bc520ba738dad3ab5631c91ae6afa871c1
report_manifest_sha256=5a844ad7198e95ffe79b08453cd7ae78c4743b6cf9006ddd1b445096d30e34f4
```

INBOX-157 therefore closes with ratchet 148, exact frozen correctness
identities, all mandatory non-Tier-3 gates green, and the blocking
counterbalanced performance gate green. No Tier 3 was run.
