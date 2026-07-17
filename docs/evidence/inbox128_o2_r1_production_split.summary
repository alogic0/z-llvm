# INBOX-128 O2-R1 production split summary

Status: complete. The source/evidence/guard tree was frozen at commit
`80198d402f5ce0168b6b2db366d93e22c534e688`, tree
`376fe433fde1bc719bb8fa392734af6420006290`, before artifact construction.
The post-freeze counterbalanced gate passed, and this follow-up changes only
this tracked evidence summary.

Date: 2026-07-17

## Scope and baseline

The accepted R0 working baseline is commit
`4c0a69f730975fed988274c4f54e434676e94b1e`, tree
`ee795cbbf158e36da149be840e10deaa36cd3d3a`, with the monolith frozen at:

```text
file=src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig
lines=6698
bytes=290587
sha256=825abb19d5a24bfa2fc1ccc1c611a4ffc6c620c1d771ad3a026fa5bc866f52e1
```

R1 mechanically partitions that source into the accepted R0 layout. The
compatibility facade remains:

```text
const core = @import("value_use/core.zig");

pub const ValueUseTransaction = core.ValueUseTransaction;
```

There is no consumer migration, capability change, diagnostic change, or
frontier movement. The direct-materialization ratchet remains exactly 172.
`stash@{0}` remains untouched.

## Mechanical provenance and manifests

Exact reconstruction/provenance command:

```text
git show 4c0a69f730975fed988274c4f54e434676e94b1e:src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig > tmp/inbox128_r0_value_use_transaction.zig
INBOX128_R0_SOURCE=tmp/inbox128_r0_value_use_transaction.zig python3 tools/o2_r1_split_from_r0.py
zig fmt src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig src/codegen/x86_64/generic_cfg/value_use
```

```text
tool=tools/o2_r1_split_from_r0.py
tool_sha256=769212111623ed63c041f053c344b45de97cb9f994146f483d6cacf5feb4d868
provenance=docs/evidence/inbox128_o2_r1_symbol_provenance.tsv
provenance_rows=287_plus_header
provenance_sha256=cee0970e29141a9bb5974ab55c01995d0ed21122f39204bc0470e5aff3034df9
facade_manifest=docs/evidence/inbox128_o2_r1_facade_manifest.tsv
facade_manifest_entries=91
facade_manifest_sha256=c4584910259225efdb267821d63058a4cbe5b371f73ab4a9827988a1c530827e
tag_error_dispatch_manifest=docs/evidence/inbox128_o2_r1_tag_error_dispatch_manifest.tsv
tag_error_dispatch_manifest_sha256=4432b0cad4193aed358f5887939470f6afef7f83fde3ac1c3681205f35491ce1
```

The facade manifest is identical to R0: zero additions, removals, or
signature/error-surface changes. `PreparedAction` remains centralized in
`model.zig`; `core.zig` contains the sole exhaustive action dispatch.

## Leaf identities and budgets

```text
3      4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a  composed_selector_value_use_transaction.zig
1346   3dbfb5a0b85dd3901e74724d490b954f3fc26a43832a724254f2022d9e8e9534  value_use/model.zig
1055   febb6d5c30bdd0b4c2e400d349020feec923ce6712038c49cee456e5ea6a10f8  value_use/core.zig
1969   9a495f9a9c247ed1991c0f942566bfd85627b2d6cfeebbc2b94a40180ae2d0d5  value_use/planning.zig
1278   78f808f22449264bb4fcdb3abf487a62cbb370ce07e3bdf43dd375cf7d92e703  value_use/materialization.zig
258    12ef0e4d49c2f228f012dd9aa3f68ad2f03658a45cecf6be48e7b3412067c6dc  value_use/composition.zig
929    e1760a3513ff8c1f5e4c3cb9808f38e6bffccab6b4a759e044150e2aea7f4b51  value_use/actions/address_memory.zig
1408   5d5ed89c7fd49978eb03bdbb84045fb9a488a16c7c34662eb0f6149adb1f64c7  value_use/actions/control_compare.zig
215    d6b6fd404f8eacc462bf2f9da575cacd6877268ff0407346f8a33aec8aa18fe3  value_use/actions/calls.zig
```

No leaf exceeds 2,000 lines. The watched `control_compare.zig` leaf is 1,408
lines. Planning is 1,969 lines: above its R0 projection but below the explicit
2,000-line reviewed-exception threshold. Its extra lines are the frozen pure
compatibility classifiers moved out of model to satisfy the exact
technically-public name budget; no capability was added.

The source guard enforces every exact per-leaf technically-public name set.
Action leaves cannot import planning or access `Authority.planning`; shared
physical-node classification data lives in the model and planning exposes
only its frozen forwarding names. Production consumers remain facade-only.

## Transaction(comptime Impl) proofs

- Exactly one production instantiation exists:
  `model.Transaction(Implementation)` in `core.zig`.
- The facade exposes no `Impl`.
- No function pointers, vtables, or runtime callbacks are present.
- No production or test source uses `@typeName` for this authority.
- All 36 extracted transaction methods are guarded as direct forwarding
  shells: one return, no branch, cleanup, error translation, mutation, or
  retry.
- The R0 and R1 transaction layouts are identical:
  `@sizeOf=194688`, `@alignOf=16`, with all 28 field offsets frozen in the
  full-unit test.
- Reflection tests prove every public callable method retains a finite
  reachable error set; none widened to `anyerror`.
- The exact sorted facade and PreparedAction/UseForm/error/dispatch manifests
  match R0.
- The import graph is acyclic. Planning imports only the frozen pure compare
  classifier set. Action leaves have no reverse planning dependency.

## Optimized allocated-section inspection

Both artifacts were built with the exact command `zig build
-Doptimize=ReleaseFast` from R0 and the final pre-commit R1 source,
respectively. The retained inspection is
`tmp/inbox128_o2_r1/artifacts/optimized_allocated_sections.txt`, SHA-256
`1f6dacf40adc7a17b53b64e53e57a3be1c1fc882756eea59aeae43e8563e0ed8`.

```text
artifact_A_sha256=a9bd992941e69d689798cf5d808d4de7829ba25adbdca7686d2f61acdce02cbf
artifact_B_sha256=fa03e845610b58a901d6096c7947f3b41f5b43e3efbfc71c1b8e041412fee76e
section                 A_bytes  B_bytes  status
.rodata                  772004   772772  changed
.eh_frame_hdr             25316    25300  changed
.eh_frame                149968   149992  changed
.text                   4907267  4910995  changed
.got                           8        8  byte-identical
.data                      19176    19176  changed
```

The allocated-section movement is recorded, not hidden: the approved generic
type and moved function identities change optimized symbol ordering and
unwind/string placement. The behavior-facing gates below remain exact, and
the required counterbalanced runtime gate adjudicates the runtime effect.

## Exact behavior identities

Exact commands:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox128_o2_r1/validation/fresh_full_report_final.log
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox128_o2_r1/validation/accepted_final.o 2> tmp/inbox128_o2_r1/validation/accepted_final.stderr
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox128_o2_r1/validation/owner_manifest_final.tsv 2> tmp/inbox128_o2_r1/validation/owner_manifest_final.stderr
```

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
```

## Non-performance validation

Every log below records exactly the command shown. No Tier 3 command was run.

```text
command=zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox128_o2_r1/validation/source_guard_final.log 2>&1
result=34/34
log_sha256=0c0a058bb28dfb96fd2991abd3b5dfe299bb20b0436aa8cfca0cd9d0cdbf987e

command=zig build test --summary all > tmp/inbox128_o2_r1/validation/full_unit_final2.log 2>&1
result=1278/1278
log_sha256=d0b4e771e65d87690697bdbc9a6de6896190f218fe2670e6d54fba9736370621

command=zig build abi-differential --summary all > tmp/inbox128_o2_r1/validation/abi_differential_final.log 2>&1
result=60/60+30/30
log_sha256=9a8949619993bf17a50f6fef97053ae7952746b1735aceace205124d911a91c2

command=zig build focused-codegen-canaries --summary all > tmp/inbox128_o2_r1/validation/focused_canaries_final.log 2>&1
result=2_canaries/35_cases
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8

command=zig build distribution-zig-integrated-exe --summary all > tmp/inbox128_o2_r1/validation/integrated_exe_final.log 2>&1
result=7/7
log_sha256=3360567d9272f0aa4e70b292d825f19ff237472b609c074e8814addef8b0736e

command=zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox128_o2_r1/validation/strengthened_tier2_final.log 2>&1
result=29/29_steps,1286/1286_tests
log_sha256=1358935fa69b459d24269d99b566b9db2a858beef43f182ff9e2fb205abbdf8b
```

Tier 3 was not invoked.

## Counterbalanced performance

The final production/evidence/guard source commit was frozen before artifact
construction, as required:

```text
A_source_commit=4c0a69f730975fed988274c4f54e434676e94b1e
A_source_tree=ee795cbbf158e36da149be840e10deaa36cd3d3a
B_source_commit=80198d402f5ce0168b6b2db366d93e22c534e688
B_source_tree=376fe433fde1bc719bb8fa392734af6420006290
build_command=zig build
artifact_A=tmp/inbox128_o2_r1/perf/artifacts/A/z_llvm
artifact_A_sha256=c607d9410925e6ae93d9b651c37caa8c2954219675d88e2697d58b755778cc92
artifact_A_mode_size=0555/90778443
artifact_B=tmp/inbox128_o2_r1/perf/artifacts/B/z_llvm
artifact_B_sha256=87e541cf38ac0ab88bc437e518b2885216ff0ec505e97dff36a4fae265945462
artifact_B_mode_size=0555/91157392
```

Both artifacts were copied read-only before timing and were never rebuilt or
modified between samples. Their post-measurement hashes match the hashes
above.

The preflight used the exact command `mpstat -P 0 1 5`; its retained log is
`tmp/inbox128_o2_r1/perf/idle_preflight.log`, SHA-256
`9e2c0566dd3a2a37463c8d868ef4040c69e631b26f0f9d4d33d229ebc621ccbb`.
Pinned CPU 0 averaged 96.19% idle. The retained process snapshot is
`tmp/inbox128_o2_r1/perf/idle_processes.log`, SHA-256
`c91d39b21a1c4895abd99e93b1cfa25d08a2e661959f27ed2e05c2dea157fcdb`;
there was no competing Zig or z_llvm workload.

Every warmup and timed sample used this exact command shape, substituting only
the immutable artifact and output paths:

```text
/usr/bin/time -f '%e\t%M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 /home/oleg/prog/z_llvm/tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> LOG
```

The cohort command intentionally exits with status 1 because the frozen report
contains 158 accepted failures. The initial harness incorrectly combined that
known status with `set -e`, so it stopped after completing the first discarded
A warmup. No timed sample had run. The first warmup was retained, not rerun;
the continuation accepted exactly status 1, then ran the remaining B/A/B
warmups and all twelve timed samples. Thus there are exactly two warmups per
artifact, exactly six timed pairs, no discarded timed sample, and no
discretionary rerun. Neither artifact nor the command being timed changed.

The exact expanded command inventory is
`tmp/inbox128_o2_r1/perf/commands.tsv` (16 entries), SHA-256
`0ceb1adbfda0a856cbb7b1177344acd9df2564dda0d3484d0b9daba07ac483fa`.
The raw timing/report manifest is
`tmp/inbox128_o2_r1/perf/raw_samples.sha256` (32 entries), SHA-256
`d6a513a972b1863f0183a13ca82d9d1b16ce28835c03c29fd537d32d7196fbfa`.
All 16 report logs independently hash to the frozen report identity
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.

Exactly two warmups per artifact ran in `A B A B` order and were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 49.12 | 94,624 |
| B warmup 1 | 48.82 | 95,192 |
| A warmup 2 | 49.05 | 94,628 |
| B warmup 2 | 49.01 | 95,200 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 49.05 | 94,636 | 49.02 | 95,188 | 0.999388379 |
| 2 | BA | 49.12 | 94,628 | 48.92 | 95,204 | 0.995928339 |
| 3 | AB | 49.21 | 94,620 | 48.81 | 95,188 | 0.991871571 |
| 4 | BA | 49.12 | 94,624 | 48.82 | 95,200 | 0.993892508 |
| 5 | AB | 49.18 | 94,632 | 48.85 | 95,196 | 0.993289955 |
| 6 | BA | 49.24 | 94,624 | 48.78 | 95,188 | 0.990658002 |

```text
median_A_seconds=49.150
median_B_seconds=48.835
median_delta_seconds=-0.315
allowed_delta_seconds=max(2.45750,0.100)=2.45750
aggregate_median_gate=pass
paired_ratio_median=0.993591232
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=94636
B_max_rss_KiB=95204
rss_delta_KiB=568
rss_limit_KiB=16384
rss_gate=pass
```

The series is stationary: A spans 49.05–49.24 seconds and B spans
48.78–49.02 seconds without monotone drift. No outlier was removed. The
aggregate median, paired-ratio, and maximum-RSS gates all pass.

No source, tool, test, build, facade, or guard file changed after the frozen B
commit. Tier 3 was not invoked.
