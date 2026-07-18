# INBOX-145 O2 checkpoint slice 1 — scalar-action production split

Status: complete. The mechanical production move is commit
`747a884df80c7dcdcd9234c22b9da3a57ec672e3`, tree
`79af809215b983a2fc14fea06fc99afa6c97a608`. This follow-up changes only
this evidence summary. The direct-materialization ratchet remains 154.

## Frozen basis and scope

```text
working_baseline_commit=da0e94465f181f0406f65abe58927edb24b403f6
working_baseline_tree=db67e73d96f54b28240857bece2ce0ad4154f7ba
accepted_plan_commit=9c061714
production_commit=747a884df80c7dcd9234c22b9da3a57ec672e3
production_tree=79af809215b983a2fc14fea06fc99afa6c97a608
ratchet=154
semantic_change=none
tier3=not_run
stash_at_0=untouched
stash_at_0_oid=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

`scalar_arithmetic.zig` is now a direct-alias facade over
`scalar_cast.zig` and `scalar_immediate.zig`. It has exactly two imports
and the frozen 14 aliases: no function, branch, callback, cleanup, retry,
or mutation. `model.zig` and `core.zig` are byte-identical to the working
baseline; core retains its single import of the scalar facade and has no
direct import of either implementation leaf. Payload and dispatch
ownership therefore did not move.

```text
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_arithmetic.zig lines=17 bytes=1237 sha256=d43c06c654fee7216d153fb8f6bedd53d8487cdff3fa33cee98ed13ed7d6c766
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast.zig lines=414 bytes=17228 sha256=d72c17b3460cf007b74cb8826c40784cc531751badc1f47afac3f09464be0c32
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate.zig lines=1165 bytes=40929 sha256=6bfaef0e50819371e164a53b21f19c30780ed11c4784a15dfeefbda9f297c68c
```

Both implementation leaves remain below the preferred 1,500-line budget
and the 2,000-line hard stop.

## Mechanical provenance and frozen contracts

The move was generated and verified only with temporary Zig programs; no
Python program was used. The verifier read the frozen pre-move source,
located each top-level declaration, trimmed only declaration-separating
whitespace, and compared SHA-256 hashes of the complete old/new
declaration blocks, including signatures and bodies.

```text
baseline_source=tmp/inbox145_o2_checkpoint_slice1/provenance/scalar_arithmetic.baseline.zig
baseline_source_sha256=ff6d112ac285bef239f64873d77954e48e66594049a18867b6def17fb91e64f1
provenance=docs/evidence/inbox145_o2_checkpoint_slice1_provenance.tsv
provenance_rows=61_plus_header
provenance_exact=61/61
provenance_sha256=0ffd4fffe069a48ad008b95a3b799891daa9d9bafb8aa1986c3e3b4372fafeec
```

The physical manifest contains 21 cast and 40 immediate implementation
symbols because it also records the 14 public implementation targets
(8 cast, 6 immediate) behind the separately frozen facade budget. The
directive's internal ownership accounting is preserved as 17 cast
declarations (13 private implementation declarations plus the four
declared receiver aliases) and 34 immediate private declarations. The
four receiver aliases are the declared duplicated import/receiver rewrite;
they introduce no dependency or behavior.

The source guard now enforces:

- the exact 14-name facade source, not merely a count;
- exact 8-name cast-leaf and 6-name immediate-leaf public budgets;
- core importing the facade exactly once and neither leaf directly;
- no core, planning, sibling-action, or `Authority.planning` reverse edge;
- both implementation-leaf line ceilings;
- the pre-existing immediate-plan/lifetime/durable-key guards at the
  relocated source.

The focused negatives reject a branch in the facade, direct core-to-leaf
imports, reverse leaf imports, public-budget drift, and line-budget growth.
Full compilation plus the exact old/new block hashes prove reachable error
sets, initialization order, signatures, bodies, and action dispatch order
did not change.

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

The exact whole object and 285/285 per-function comparison include the
frozen `exp2` stream. The focused canary validator separately proves the
fma and `__multi3` object, instruction-stream, symbol/helper, and 35-case
execution contracts.

## Correctness gates

Each retained log is paired with its exact command.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=46/46
log_sha256=6efcc42be89eb6984a10ff09687c1156456291d46166c942b1fd776531a3119e
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1328/1328_tests
log_sha256=673869f938ed1c8cdb8e61902272a702896090bf5639357ca9270382eaceb353
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=60/60_cases,30/30_real_functions
log_sha256=4c41b930e711763404541e5977b3cd56fa46a7209aafbe7e4607e8387e304744
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_canaries,35_execution_cases
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
```

### Standard integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all
result=7/7
log_sha256=cb1541032237fc55394ab3fd02285b62125044dfcdac27f5b76ee8cb50f64fcd
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all
result=29/29_steps,1336/1336_tests
log_sha256=150b3d8d148e9fbcd1e00c44501fa5ec59b383547d3f3420f150d311dc549dac
```

No `distribution-all` or other Tier 3 command was launched.

## Post-final-tree immutable counterbalanced performance

Artifact A was built and frozen read-only from the working baseline before
the split. Artifact B was built and frozen read-only only after production
commit `747a884d` made the source/guard/provenance tree final. Neither
artifact was rebuilt between samples.

```text
build_command=/home/oleg/bin/zig build
artifact_A=tmp/inbox145_o2_checkpoint_slice1/perf/artifacts/A/z_llvm
artifact_A_sha256=0c565640c50b959586d5bebe64b61fbcc4e6a3bcd6dcf39c854b906d3444c948
artifact_A_mode_size=0555/110719842
artifact_B=tmp/inbox145_o2_checkpoint_slice1/perf/artifacts/B/z_llvm
artifact_B_sha256=b057b24850169a7093cca340508d04dc310a2ea6ed2329b5b1f84f78bcdcea48
artifact_B_mode_size=0555/110723938
input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
idle_cpu0_average=94.20_percent
idle_preflight_sha256=53510848fd16a5976c84fdb9ebb8af40f95f28fb50451bf62ba5871e3285df8f
```

The Zig orchestrator used this exact command shape, substituting only the
immutable artifact and output paths:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> REPORT
```

Two warmups per artifact ran in `A B A B` order and were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 51.61 | 90,980 |
| B warmup 1 | 51.65 | 90,980 |
| A warmup 2 | 51.39 | 89,972 |
| B warmup 2 | 51.69 | 90,992 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 52.88 | 90,988 | 52.44 | 90,980 | 0.991679274 |
| 2 | BA | 50.86 | 90,948 | 51.87 | 90,988 | 1.019858435 |
| 3 | AB | 50.77 | 90,964 | 50.83 | 90,980 | 1.001181800 |
| 4 | BA | 50.27 | 90,960 | 51.07 | 90,984 | 1.015914064 |
| 5 | AB | 50.99 | 90,964 | 50.56 | 90,972 | 0.991566974 |
| 6 | BA | 50.14 | 90,952 | 50.47 | 90,976 | 1.006581572 |

```text
median_A_seconds=50.815
median_B_seconds=50.950
median_delta_seconds=0.135
allowed_delta_seconds=max(2.54075,0.100)=2.541
aggregate_median_gate=pass
paired_ratio_median=1.003881686
paired_ratio_gate=pass
A_max_rss_KiB=90988
B_max_rss_KiB=90988
rss_delta_KiB=0
rss_gate=pass
reports_exact=16/16
paired_metrics_sha256=bf1dafe389e52a8b8e724536c1c5ea6068561fa07ffe9a84630da7ada89f1269
raw_manifest_sha256=4ed8a5e2a1cb33c3c08ac3084a8d422ebd0c09ee76bdb7455d75c86910dfce77
report_manifest_sha256=a3a8785c024cd07cef288a84a375a0ebc696907a5d977085a231a11c5793bc1f
```

No sample was removed or added, no discretionary rerun occurred, and all
procedural orchestration and analysis programs used for the slice were Zig.
