# INBOX-143 — final narrowed immediate wiring

Status: complete; stopped for Supervisor/Reviewer review. Production and
immutable evidence are separate commits. No Tier 3 command was run.

## Frozen scope

```text
matrix_acceptance_commit=f37845a1
starting_head_with_supervisor_docs=14d3e52c15fcf4fdcfff1b96b0f8489c96aea680
starting_tree=94c93b35f12a2629d019c2c7e8f537fc60a070aa
production_commit=41bdecf9fd2019b644174057f3f18ec9296eae63
production_tree=2f4402a0c39431bb40a378b0ecec3571f667d9e3
production_patch_sha256=1c1b6bca9fbe0b9c320db90adf51ccb326ebaeaee37aa0d89e8cb87592791bde
action_model_behavior=frozen_at_de3cb6f9
stash_at_0=untouched
prior_carriers=untouched_evidence_only
```

The consumer patch was built afresh from the accepted scalar source
(`78452e32...`); no retired carrier was applied. It wires exactly R00-R02,
R05-R06, and L01-L03 through the existing closed immediate actions.
Every R03 form is routed before transaction creation to
`scalar_immediate_live_shared_source_preservation`. Every R04 form is
routed before transaction creation to
`scalar_immediate_multi_alias_preservation`. Neither residual owner can
open a `ValueUseTransaction`.

L00 remains the existing i128 pair-result path. All other i128 pair-result
forms and the exact-EI dispatch position are unchanged. No action, model,
planning, transaction, tool, or build file changed.

## Ratchet and structural ownership

```text
mechanical_bypass_total_before=166
mechanical_bypass_total_after=154
removed=12
lowerBinaryImmediateLhs=materializePairValue×1
scalar_immediate_live_shared_source_preservation=emitValueIntoScratch×1
tryLowerLshr64SpillThroughRax=removed_after_verified_last_owner
frozen_inventory_sha256=155f7be0d933df9516731265d4442c3ebbc1fb9ca4d5d6f3bacc2776aa936eb6
classification_sha256=f7281a2a47da5ecc1ecdef8b9d4b96727d82be056bab823a17c28a19ef2d8e7c
```

The classification TSV splits the original RHS scratch row: historical
occurrences 1-2 and 4-5 are migrated, while occurrence 3 is retained under
the new R03 owner. R04 is a zero-textual-count legacy residual. R00 and R05
are zero-count semantic ownership transitions.

The source guard enforces:

- R03 and R04 pure-IR classifier shapes and exact named residual owners;
- R03 then R04 dispatch before the action, with no attempt/fallback;
- the legacy R03 staging/session and R04 five-form session structures;
- L00 before the LHS action and the surviving i128 pair tails;
- no old R00 or R05 lowering anchor in the dispatch;
- the two one-request action lifecycles and provenance-only diagnostic
  mapping;
- absence of the retired spill-through-RAX helper.

Focused negative fixtures reject residual relocation into the transaction,
transaction use inside either residual, stateful classifiers, changed
dispatch order, and reintroduced R00/R05 legacy anchors.

## Frozen identities and streams

Fresh report command (exit 1 is the accepted aggregate-failure status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox143_o2_final_narrowed_wiring/validation/fresh_full_report.log
```

Accepted object command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox143_o2_final_narrowed_wiring/validation/accepted.o 2> tmp/inbox143_o2_final_narrowed_wiring/validation/accepted.stderr
```

Owner manifest command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox143_o2_final_narrowed_wiring/validation/owner_manifest.tsv 2> tmp/inbox143_o2_final_narrowed_wiring/validation/owner_manifest.stderr
```

Per-function identity command:

```text
/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox142_family_isolation/results/baseline/accepted.o tmp/inbox143_o2_final_narrowed_wiring/validation/accepted.o > tmp/inbox143_o2_final_narrowed_wiring/validation/function_diff.tsv
```

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
per_function_comparison=285_compared/0_divergent/0_missing
per_function_manifest_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
spill128_frontier_rows=6
spill128_frontier_manifest_sha256=8bb7e9f794f1e0b8b42fb64e9a4300c8689c28cc38047cd795008d305949a0ec
```

The exact whole object plus the 285-symbol comparison proves the exp2
symbol stream is unchanged. The focused validator independently proves
the fma and `__multi3` object, stream, symbol, helper, and executable
contracts:

```text
__multi3=object_ok/stream_ok/symbol_ok/execution_6
fma=object_ok/stream_ok/symbol_ok/helpers_ok/execution_29/no_host_libc_substitution
focused_canary_log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

## Correctness gates

Every log below has its exact command recorded here.

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=45/45
log=tmp/inbox143_o2_final_narrowed_wiring/validation/source_guard.log
sha256=f950f582ab15baa3804f17f0a2ed5a705f066c57e1df02353350f5894de85b3d

command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1327/1327_tests
log=tmp/inbox143_o2_final_narrowed_wiring/validation/full_unit.log
sha256=22903b1336c574b610b5668453b9cb4b06a09715ad938e657e4243ab5dc96a1c

command=/home/oleg/bin/zig build abi-differential --summary all
result=60/60_cases,30/30_real_functions
log=tmp/inbox143_o2_final_narrowed_wiring/validation/abi_differential.log
sha256=43a2fb42c2c7df4f2aaf5fe67457cdcde646ca01b1a17df9468371984be8d178

command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_canaries,35/35_execution_cases
log=tmp/inbox143_o2_final_narrowed_wiring/validation/focused_canaries.log
sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6

command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all
result=7/7
log=tmp/inbox143_o2_final_narrowed_wiring/validation/integrated_exe.log
sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92

command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all
result=29/29_steps,1335/1335_tests
log=tmp/inbox143_o2_final_narrowed_wiring/validation/strengthened_tier2.log
sha256=ef7d105ff958c992704d02af291d4240d5072a1311d95d40e078d5f5caa9d0ba
```

No `distribution-all` or other Tier 3 command was launched.

## Immutable counterbalanced performance

Artifact A was built and frozen read-only before the production edit.
Artifact B was built from the final production commit and frozen read-only
before timing. Neither was rebuilt between samples.

```text
build_command=/home/oleg/bin/zig build
artifact_A=tmp/inbox143_o2_final_narrowed_wiring/perf/artifacts/A/z_llvm
artifact_A_sha256=9dbeef33ede1dcc52f492205b321cb1c74e13b6130826939550b5ba0454e6edb
artifact_A_mode_size=0555/110936141
artifact_B=tmp/inbox143_o2_final_narrowed_wiring/perf/artifacts/B/z_llvm
artifact_B_sha256=0c565640c50b959586d5bebe64b61fbcc4e6a3bcd6dcf39c854b906d3444c948
artifact_B_mode_size=0555/110719842
input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
idle_preflight=98.68_percent_all/98.66_percent_cpu0/no_competing_zig_or_zllvm
idle_preflight_sha256=fba299431068d6e357b76651250745cb961c3cf532e50f89ccf6d85c85773b05
```

The Zig orchestration script ran each sample with this exact command shape,
substituting only the immutable artifact and output paths:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> REPORT
```

Two warmups per artifact ran in `A B A B` order and were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 48.83 | 94,912 |
| B warmup 1 | 47.80 | 90,988 |
| A warmup 2 | 48.95 | 94,900 |
| B warmup 2 | 47.86 | 90,988 |

All six required pairs were retained in `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 49.31 | 94,916 | 47.94 | 90,984 | 0.972216589 |
| 2 | BA | 49.41 | 94,908 | 48.00 | 90,992 | 0.971463267 |
| 3 | AB | 49.67 | 94,904 | 49.41 | 90,988 | 0.994765452 |
| 4 | BA | 50.66 | 94,908 | 49.57 | 90,980 | 0.978484011 |
| 5 | AB | 50.08 | 94,900 | 49.42 | 90,992 | 0.986821086 |
| 6 | BA | 50.17 | 94,912 | 49.53 | 90,968 | 0.987243373 |

```text
median_A_seconds=49.875
median_B_seconds=49.415
median_delta_seconds=-0.460
allowed_delta_seconds=max(2.49375,0.100)=2.49375
aggregate_median_gate=pass
paired_ratio_median=0.982652549
paired_ratio_gate=pass
A_max_rss_KiB=94916
B_max_rss_KiB=90992
rss_delta_KiB=-3924
rss_gate=pass
reports_exact=16/16
paired_metrics_sha256=27e0ca46a4f5f72c8b973657b52b87f101f65633e5e370f0c393bec058055f08
raw_manifest_sha256=c746d5daea09d11bb2ec02409485af9bf2f618b0e00875fa05bc6b98b39e1e4d
report_manifest_sha256=5ac0e08807b6d7f523fb57f3cdbf56a5c8d953397831ea1822b2cec03b9345e5
```

No sample was removed, no timed sample was added, and no discretionary
rerun occurred. All procedural analyzers and rewrite/orchestration helpers
used for this slice are Zig sources.
