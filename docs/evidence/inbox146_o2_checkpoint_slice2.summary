# INBOX-146 O2 checkpoint slice 2 — production planning split

Status: complete. The mechanical production move is commit
`dacc2566828618f2c96f683a7838d3b47b8ca516`, tree
`9054a4304191b68c413b771df0a3137811bf1f4d`. This follow-up changes only
this evidence summary. The direct-materialization ratchet remains 154.

## Frozen basis and scope

```text
working_baseline_commit=2fd7b7ae0c097ca83b148d34e36234177f8fb331
working_baseline_tree=3dd33867fcb4f0c3f0a7a7f87555cc2f70701525
production_commit=dacc2566828618f2c96f683a7838d3b47b8ca516
production_tree=9054a4304191b68c413b771df0a3137811bf1f4d
ratchet=154
semantic_change=none
tier3=not_run
stash_at_0=untouched
stash_at_0_oid=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

The revised ownership graph is now:

```text
planning/model.zig -> passive PhysicalNode, Mapping, CopyVisitState
planning/compatibility.zig -> pure compatibility/classification validation
planning/lifetime_admission.zig -> Q1/Q2/Q3 and request admission
planning/semantic_ordering.zig -> semantic order and early materialization
planning/physical_mapping.zig -> physical graph and sole seal orchestrator
planning.zig -> exact reviewed 18-alias internal facade
core.zig -> planning.zig only
```

`Mapping` is technically public only for physical mapping and semantic
ordering. `CopyVisitState` is consumed only by the exact cycle-walker
owners. The three Q1/Q2/Q3 functions are re-exported only through the
facade and used only by the three exact `Implementation` aliases in
`core.zig`. No action leaf imports planning, no planning leaf imports an
action except the existing pure classifier import owned by physical
mapping, and lifetime/admission never imports physical mapping. The
durable spill-key implementation in `composed_selector_state.zig` is
byte-identical to the baseline.

```text
file=src/codegen/x86_64/generic_cfg/value_use/planning.zig lines=24 bytes=1631 sha256=2fbf02450c70d707da321b2f7ce271749ca338d0e4b254ea4d5aec8f5be99a9c
file=src/codegen/x86_64/generic_cfg/value_use/planning/model.zig lines=10 bytes=291 sha256=4fdbfdf82650965b0d0c4be2c29fe616c1c296bc26a0a071c808d1402a2f9ac9
file=src/codegen/x86_64/generic_cfg/value_use/planning/compatibility.zig lines=589 bytes=25564 sha256=767334f3e9e84f86ba8c64bb33629aa31fb9dc159c719f6b9a997ad2b297d40c
file=src/codegen/x86_64/generic_cfg/value_use/planning/lifetime_admission.zig lines=322 bytes=15384 sha256=f851f3117792f81a33d60f1de3a2321d3a52a794372b52f4b25ccb4a67d58720
file=src/codegen/x86_64/generic_cfg/value_use/planning/physical_mapping.zig lines=899 bytes=41396 sha256=0835d3a4faee7bea991ec14e36de7b438e37e5e81a92828ec312f7c8d20ae75e
file=src/codegen/x86_64/generic_cfg/value_use/planning/semantic_ordering.zig lines=509 bytes=20249 sha256=5514ad25a31a2da1444357b63ae93d334164b4094c74125fb7eaaeea03e4469d
file=src/codegen/x86_64/generic_cfg/value_use/core.zig sha256=613594a96d34b75df6277a05e727f0f98ee4795a05177bae3d30e6aeb1ca3fe8
file=src/codegen/x86_64/generic_cfg/composed_selector_state.zig sha256=6133798fd12668f41ebe4b8c7cfe73d1ed86f3824ffa624b65174538b7d0dd1f
```

Every implementation leaf is below the preferred 1,500-line budget and
the 2,000-line hard stop.

## Mechanical provenance and frozen contracts

The complete revised declaration/import/facade manifest was committed
before the mechanical move. Temporary Zig programs performed extraction,
assembly, and provenance comparison; no Python program was used.

```text
baseline_planning=tmp/inbox146_o2_checkpoint_slice2/provenance/planning.baseline.zig
baseline_planning_sha256=0dfd3a8f02842539a128bb6c0b05e699377346264d0160ab6874dcec671140ff
baseline_core=tmp/inbox146_o2_checkpoint_slice2/provenance/core.baseline.zig
baseline_core_sha256=8d4221bdde74f697d5c16f819c2458511f7663bb550da67fa747d964386cedf1
frozen_manifest=docs/evidence/inbox146_o2_planning_split_manifest.tsv
frozen_manifest_sha256=c2b7fa3c5bbf5cb6e1f5f24d8f4c976bc6ba4274cd344c593934cf3ac3becf02
provenance=docs/evidence/inbox146_o2_planning_move_provenance.tsv
provenance_rows=62_plus_header
provenance_exact=62/62
provenance_sha256=bc542c157f007650d69bcd32ab0170f8c9dcb39e2e10654eab317c2027b18efa
```

The verifier compares complete normalized declaration signatures and
bodies after only the reviewed visibility, module-qualification, and
receiver rewrites. It covers every moved planning declaration plus all
three Q1/Q2/Q3 bodies moved from `core.zig`. The source guard enforces the
exact 18-name facade, exact leaf public budgets and import graph, the
restricted Mapping and CopyVisitState consumers, the exact three core
aliases, the sole seal orchestrator, and leaf line ceilings. Focused
negative fixtures reject facade growth, a lifetime-to-physical reverse
edge, Mapping leakage, and a core leaf-import/alias bypass. Full
compilation and exact body provenance prove seal statement order,
signatures, and reachable error sets unchanged.

## Identity and stream proofs

The fresh report retained its expected selector exit status 1.

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
per_function_compare=285_equal,0_divergent,0_missing
per_function_compare_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
frontier_rows=composed-block-icmp-lhs-loc:6
```

The exact object and 285/285 per-function comparison include the frozen
`exp2` stream. The focused validator separately proved the fma and
`__multi3` object, instruction-stream, symbol/helper, and 35-case
execution contracts.

## Correctness gates

Each retained log is paired with its exact command.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=47/47
log_sha256=2aa27eab17e13f7745d1b538823fa8c7084c9a446e06461859d9950a0a43e8b8
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1329/1329_tests
log_sha256=e69402d7c8fc127980c044df24161eba61dde0be6d425dd4d2558e91132e6f12
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=60/60_cases,30/30_real_functions
log_sha256=d8a10ce112d540b08518ba6696171ec19bdadb1ef0dfc88dc8add52c1fe78369
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_canaries,35_execution_cases
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Standard integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all
result=7/7
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all
result=29/29_steps,1337/1337_tests
log_sha256=3f098d5c63602bb576813fd9504e9b9bafa218f43120c1a55d985d70d141e969
```

No `distribution-all` or other Tier 3 command was launched.

## Post-final-tree immutable counterbalanced performance

Artifact A was built and frozen read-only from the exact working baseline.
Artifact B was built and frozen read-only only after production commit
`dacc2566` made the complete source/guard/provenance tree final. Neither
artifact was rebuilt between samples.

```text
build_command=/home/oleg/bin/zig build
artifact_A=tmp/inbox146_o2_checkpoint_slice2/perf/artifacts/A/z_llvm
artifact_A_sha256=b057b24850169a7093cca340508d04dc310a2ea6ed2329b5b1f84f78bcdcea48
artifact_A_mode_size=0555/110723938
artifact_B=tmp/inbox146_o2_checkpoint_slice2/perf/artifacts/B/z_llvm
artifact_B_sha256=161b3e1c6b68d2df6e7720742b940d06bd95d7f3deafcf8cc4ec61306d23c91b
artifact_B_mode_size=0555/110723938
input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
idle_cpu0_average=93.90_percent
idle_preflight_sha256=d5b51282dbb71e9f7bccde196bf61b8783cfb50875c89495d34118d1895fee78
```

The Zig orchestrator used this exact command shape, substituting only the
immutable artifact and output paths:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> REPORT
```

Two warmups per artifact ran in `A B A B` order and were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 49.22 | 90,520 |
| B warmup 1 | 48.85 | 90,976 |
| A warmup 2 | 49.27 | 90,980 |
| B warmup 2 | 49.11 | 90,908 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 48.95 | 89,680 | 49.04 | 90,880 | 1.001838611 |
| 2 | BA | 48.83 | 89,916 | 49.11 | 90,924 | 1.005734180 |
| 3 | AB | 49.03 | 90,392 | 49.15 | 90,924 | 1.002447481 |
| 4 | BA | 48.56 | 90,392 | 48.57 | 89,812 | 1.000205931 |
| 5 | AB | 48.61 | 90,380 | 49.24 | 90,908 | 1.012960296 |
| 6 | BA | 48.67 | 90,400 | 49.26 | 90,916 | 1.012122457 |

```text
median_A_seconds=48.750
median_B_seconds=49.130
median_delta_seconds=0.380
allowed_delta_seconds=max(2.4375,0.100)=2.438
aggregate_median_gate=pass
paired_ratio_median=1.004090830
paired_ratio_gate=pass
A_max_rss_KiB=90400
B_max_rss_KiB=90924
rss_delta_KiB=524
rss_gate=pass
reports_exact=16/16
paired_metrics_sha256=a2efc71c73036834bb4868623ddf056805c4e6d7c0f0a7c1ba395b57a3d4aa01
raw_manifest_sha256=211a1121a8d8c55555129f18e55c1d42ab4ce4618e4564147793b04148a9815b
report_manifest_sha256=ee5d8f82dfb3af1d00863de2c30bf403f6bfe8edf6829f4c4c5945eebb028182
```

No sample was removed or added, no discretionary rerun occurred, and all
procedural extraction, move verification, orchestration, and analysis
programs used for the slice were Zig.
