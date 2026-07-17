# INBOX-122 O2-3I-B2b2 — current-home sign-bit production migration

## Frozen foundation and scope

```text
accepted_action_commit=c7ff1984a742015728fedb2fb7f94b8afcd705ee
accepted_action_tree=4e03c6f4957e69bb694d76b1f00c3202b0d941eb
working_head_with_supervisor_docs=932cfb89bc67483df6af503bc047b660a055f0d4
immutable_B_patch_sha256=8589d03422889b9ab360153525dd8e04bf3cc7337ef1e60b6d4f0dc246838bb7
transaction_or_action_model_change=none
ratchet_before=176
ratchet_after=174
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

This slice routes exactly the two audited sign-extraction forms through the
frozen `CurrentHomeSignBitAction`: plain `icmp slt i32 <named>, 0` and plain
`icmp slt i64 <named>, 0`. The six-stage dispatch is:

1. `classifyScratchCompare`;
2. the existing exact-EI structural check and setcc action;
3. the I13 current-home eq-zero action;
4. the remaining setcc EAX action;
5. `ValueUseTransaction.isCurrentHomeSignBitIcmp`;
6. one legacy `AccumulatorDefinitionTransaction` fallback.

The stage-five classifier is the accepted pure IR-semantic classifier. It
reads only predicate, operand type, lhs/rhs forms, and the literal zero. It
cannot observe selector state, source homes, function names, or family
identity. i128 stays on the legacy pair path.

Each admitted form owns one outer `ValueUseTransaction`, one outer snapshot,
and one subordinate accumulator session. The lhs is registered and sealed
before mutation. The frozen action runs the accepted live-accumulator
preamble, canonically re-resolves after preservation, performs the
width-derived current-home preservation, materializes into EAX/RAX, prepares
the subordinate session at the audited point, and emits logical
`shr eax, 31` or `shr rax, 63`. The shift records only an incidental EFLAGS
`.write`; it creates no definition/use relationship. Result identity
ownership, `.zeroExtending(1)` definition, finalization, and the sole outer
commit remain transaction-owned.

The consumer performs no home inspection or validation. Request-specific
errors map only after a caught failure and only when
`failedRequestIs(lhs_request)` is true:

```text
ValueUseUnresolvedSource -> composed-block-icmp-lhs
ValueUseCurrentHomeSignBitWidthUnsupported -> composed-block-icmp-lhs-width
ValueUseCurrentHomeSignBitLocationUnsupported -> composed-block-icmp-lhs-loc
```

Authority errors propagate unchanged.

## Focused production coverage and guard ratchet

Focused production tests prove:

- exact i32 argument-to-EAX then `shr eax, 31`;
- exact i64 spill-to-RAX then `shr rax, 63`;
- durable EAX result binding for both widths;
- exactly one incidental EFLAGS `.write` and no action-generated consumer;
- unresolved-source provenance with zero partial emission.

The accepted dormant suite continues to cover live-accumulator preservation,
canonical re-resolution, no-op resident homes, alias de-duplication, durable
cross-instruction identity, unsupported homes including `.spill128`, and
rollback at every action boundary.

The source guard enforces the full six-stage order, the one
transaction/session/action/commit lifecycle, the request-only mapper, no raw
resolution or consumer home inspection, and a function-scoped allowlist for
the action, mapper, and dispatch. Negative fixtures reject wiring in another
file, moving action markers to another function, and a consumer-side
`valueLoc` check.

```text
mechanical_occurrence_total=174
inbox81_inventory_sha256=281ef86923fbc72fd4254bfadc6586030bab00dd73aeeb528556622a0803a9b1
inbox84_classification_sha256=39db77d8a0fbe2ae0ceb032e5a210cddc674f8f437b7f5a8ecd7ded49c9e18b6
lowerIcmp_emitValueIntoEax_signbit=migrated_1
lowerIcmp_emitValueIntoRax_signbit=migrated_1
remaining_lowerIcmp_bypasses=materializePairValue_1,resolvePairValue_1
source_guard=30/30
```

The transaction/action implementation and its dormant tests are byte-for-byte
unchanged from `c7ff1984`.

## Immutable artifacts and counterbalanced performance

Artifact A was built from detached `c7ff1984`. Artifact B was built from the
same detached tree plus the final scoped production/test/guard/inventory
patch. Both artifacts were built before timing, copied read-only, and never
rebuilt between samples.

```text
artifact_A=tmp/inbox122_icmp_signbit_perf/artifacts/A/z_llvm
artifact_A_sha256=22c5172a66cebf3c3cbca7cc769bd4e758899ff1ff7de699036578867c1f2883
artifact_A_mode_size=0555/90647000
artifact_B=tmp/inbox122_icmp_signbit_perf/artifacts/B/z_llvm
artifact_B_sha256=d1fdabc0b8c566802c2d7e5c5f7461ce4edd528097890db177b15fd561fd0470
artifact_B_mode_size=0555/90669960
idle_preflight_sha256=cd9f1bbb68f05e4abf085ccddb0e5d8a6400e0a309949df09330cd9fdfb49ca7
machine_average_idle=96.05%
pinned_cpu0_average_idle=96.33%
competing_zig_or_zllvm_workload=none
```

Every warmup and timed sample used this exact command shape, with `ARTIFACT`,
`RAW`, and `LOG` selected by the mandated sequence:

```text
/usr/bin/time -f '%e %M' -o RAW taskset -c 0 env LC_ALL=C ARTIFACT --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> LOG
```

Exactly two warmups per artifact were discarded:

| Sample | Wall seconds | Max RSS KiB |
| --- | ---: | ---: |
| A warmup 1 | 48.78 | 94,724 |
| A warmup 2 | 48.95 | 94,716 |
| B warmup 1 | 48.81 | 95,060 |
| B warmup 2 | 48.79 | 95,056 |

All six pairs were retained in the required `AB, BA, AB, BA, AB, BA` order:

| Pair | Order | A seconds | A RSS KiB | B seconds | B RSS KiB | B/A |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | AB | 48.64 | 94,720 | 48.72 | 95,056 | 1.001644737 |
| 2 | BA | 48.73 | 94,716 | 48.72 | 95,052 | 0.999794788 |
| 3 | AB | 48.80 | 94,716 | 48.63 | 95,052 | 0.996516393 |
| 4 | BA | 48.66 | 94,728 | 48.70 | 95,068 | 1.000822030 |
| 5 | AB | 48.62 | 94,716 | 48.54 | 95,056 | 0.998354587 |
| 6 | BA | 48.91 | 94,712 | 48.74 | 95,064 | 0.996524228 |

```text
median_A_seconds=48.695
median_B_seconds=48.710
median_delta_seconds=+0.015
allowed_delta_seconds=max(2.43475,0.100)=2.43475
aggregate_median_gate=pass
paired_ratio_median=0.999075000
paired_ratio_limit=1.05
paired_ratio_gate=pass
A_max_rss_KiB=94728
B_max_rss_KiB=95068
rss_delta_KiB=340
rss_delta_MiB=0.332
rss_gate=pass
timed_raw_manifest_sha256=dd69f10dee3c0867602dbe84c39f11508205a24297f35315bc39330aee1b9bc9
warmup_raw_manifest_sha256=d85941c7389a9a44bd1d8a302e8029f3c742aa66ede9ea0a78c73e294a39c566
paired_ratios_sha256=4de28d09c202bb8609ae99bb815c9a6c413cff75339fb6f380ab0ac39ea4de8d
report_hash_manifest_sha256=2b0c7e73304b47d1c0e64d5eeea7460c050cb6cbba1d66b843f07f8af72d0184
```

Every warmup and timed report re-hashed to `49a19f04`. No outlier was
removed, no additional timed run was performed, and the selector's expected
aggregate-failure exit status was retained in every raw record.

## Dynamic transaction metrics

Exact command:

```text
gdb -q -batch -x tmp/inbox122_icmp_signbit_perf/icmp_signbit_metrics.gdb --args tmp/inbox122_icmp_signbit_perf/artifacts/B/z_llvm > tmp/inbox122_icmp_signbit_perf/icmp_signbit_metrics.log 2>&1
```

The procedural run measured the address-domain snapshot at 149,761 bytes:

| Width | Transactions | Snapshots | Sessions | Actions | Rollbacks | Early materializations | Copied bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| i32 | 40 | 40 | 40 | 40 | 0 | 0 | 5,990,440 |
| i64 | 22 | 22 | 22 | 22 | 0 | 0 | 3,294,742 |
| **Total** | **62** | **62** | **62** | **62** | **0** | **0** | **9,285,182** |

```text
subordinate_snapshot_copies=0
maximum_nesting=1
active_at_exit=0
metrics_log_sha256=12ce0ebb890c908b4c099a2ff87d53567b75aaddabe8ddc17762738c57674060
```

Every admitted instruction took exactly one outer snapshot and one
subordinate session. Focused tests own rollback coverage; the successful
frozen cohort correctly observed no rollback.

## Frozen identities and target frontier

Fresh report exact command (exit 1 is the frozen aggregate-failure status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox122_icmp_signbit_perf/validation/fresh_full_report.log
```

Accepted object exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox122_icmp_signbit_perf/validation/accepted.o 2> tmp/inbox122_icmp_signbit_perf/validation/accepted.stderr
```

Owner manifest exact command:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox122_icmp_signbit_perf/validation/owner_manifest.tsv 2> tmp/inbox122_icmp_signbit_perf/validation/owner_manifest.stderr
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

All six `.spill128` frontier rows remain byte-for-byte at
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-icmp-lhs-loc`:

```text
compiler_rt.floatuntidf.__floatuntidf
compiler_rt.floatuntisf.__floatuntisf
compiler_rt.floatuntihf.__floatuntihf
compiler_rt.floattidf.__floattidf
compiler_rt.floattisf.__floattisf
compiler_rt.floattihf.__floattihf
```

The target extract is
`tmp/inbox122_icmp_signbit_perf/validation/spill128_targets.txt`, SHA-256
`87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f`.
The exp/expf A/B extracts are identical, both SHA-256
`7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6`,
and retain `composed-block-gep-readonly-table-global`. No target advanced.

## Validation

Every gate log is paired with its exact command. No `distribution-all`
command was run.

Source guard:

```text
zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox122_icmp_signbit_perf/validation/source_guard.log 2>&1
result=30/30
log_sha256=9c136fc8fbcbbedc4e5723d2cb7b8a49a5b4a3e3e358f84debeb9b9e923d4ed7
```

Full unit:

```text
zig build test --summary all > tmp/inbox122_icmp_signbit_perf/validation/full_unit.log 2>&1
result=1261/1261
log_sha256=ada47649b56ea141db137ec66c5e49e42dfafb081db33d779d9c6d34be639082
```

ABI differential:

```text
zig build abi-differential --summary all > tmp/inbox122_icmp_signbit_perf/validation/abi_differential.log 2>&1
result=60/60 cases; 30/30 real functions; pass
log_sha256=04b0ca6451e25e3e7ac933e6a0478db4d2c8d7137cd489bea510626478967f07
```

Focused fma/__multi3 canaries:

```text
zig build focused-codegen-canaries --summary all > tmp/inbox122_icmp_signbit_perf/validation/focused_canaries.log 2>&1
result=2/2 canaries; 35/35 execution cases; local_fail=0
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
```

Integrated executable gate:

```text
zig build distribution-zig-integrated-exe --summary all > tmp/inbox122_icmp_signbit_perf/validation/integrated_exe.log 2>&1
result=7/7
log_sha256=ddfbbeded8bea63c0ad875c1dcf1b853b0079a8e6f97a1d7b13d4ef8159449b7
```

Strengthened Tier 2:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox122_icmp_signbit_perf/validation/strengthened_tier2.log 2>&1
result=29/29 steps; 1269/1269 tests; pass
log_sha256=e6800b8947e435bd4a4887f14c6c2c80c67157c2e3f59a98bc90294faaefba31
```

INBOX-122 ran no authorized or acceptance-grade Tier 3. O2-3I-B2b2 stops
here for Supervisor and Reviewer review before the i128 pair-wrapper subgroup.
