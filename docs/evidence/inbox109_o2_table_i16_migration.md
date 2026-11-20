# INBOX-109 — O2-3L-B3 table-i16 semantic migration

Status: PASS; ready for Supervisor/Reviewer review.

Date: 2026-07-16

## Frozen source and scope

```text
accepted_code_parent=55efa5019dc0a7cc4d8cc60f0740143cc64a87f8
supervisor_docs_head_before_landing=59aed0ad1193e759a99d1a10b28c1aee18cefd0b
zig_version=0.16.0
candidate_patch=tmp/inbox109_table_i16_perf/inbox109_b3_candidate.patch
candidate_patch_sha256=f2cf2152e9fbd27fa87b67404e1138062c0c3a839199de7acdd6659a67f895f5
frozen_input=tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
frozen_input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
```

Only the `i16_128`, offset-zero, i16-result branch of
`lowerReadOnlyTableLoad` opens a `ValueUseTransaction`. Both register and
spill-backed table storage use the closed `load_readonly_table_i16` action.
The result remains the accepted `scratch32/R8` binding; no accumulator
session is opened.

Address-space and offset rejection remain before the transaction. The
spill-backed action stages RCX before its closed type validation. Error
mapping occurs only when `failedRequestIs(table_request)` is true; an
authority-level error is propagated unchanged.

The double/XMM branch remains direct and behaviorally unchanged under O3.
The legacy rejected i16-type tail also retains its accepted spill-before-type
diagnostic ordering. Focused production tests prove:

- register table -> `load_arg_ptr_disp8_u16_arg(base,R8,0)`;
- spill table -> `reload_arg64_rsp(rcx)` then the same R8 load;
- exact `scratch32/R8` result, unchanged accumulator domain and EFLAGS;
- rejected i16 type stages the spilled table pointer before the legacy type
  diagnostic; and
- the double spill path remains direct RCX staging plus the XMM0 load.

The transaction/action/planning model frozen at `2fc1096c` was not changed.
`stash@{0}` remains untouched.

## Structural guard and semantic ratchet

The source guard now requires the table-i16 branch to dispatch to the
transactional helper before the surviving direct materialization. It requires
exactly one table-i16 action, one transaction, one execution, and one commit
inside that helper; it forbids accumulator, scalar-load, pair-load, and alias
actions there. The direct materialization and XMM clobber remain confined to
the double/O3 dispatch body. A negative fixture moves the direct
materialization into the i16 branch and is rejected.

```text
textual_bypass_inventory_before=216
textual_bypass_inventory_after=216
textual_delta=0
semantic_transition=table-i16 direct load -> transaction-owned closed action
surviving_direct_owner=O3-FP-XMM plus legacy rejected-type diagnostic tail
source_guard=PASS
```

The classification, composition, load matrix, diagnostic-precedence, and
proposed-ratchet TSVs record that transition explicitly. The frozen textual
inventory is not falsely claimed to shrink.

## Immutable artifacts and idle preflight

Both artifacts were built completely before timing, copied read-only as mode
`0555`, and never rebuilt during warmups or timed samples.

```text
A_source=detached 55efa501
A_binary=tmp/inbox109_table_i16_perf/artifacts/A/z_llvm
A_binary_sha256=af65a6d9ac4c18ed0199a938e3c2391d3b3bb7e1ba8d8174347fdda0b3387860
B_source=detached 55efa501 + hash-pinned candidate patch
B_binary=tmp/inbox109_table_i16_perf/artifacts/B/z_llvm
B_binary_sha256=3937eefe766d1fad83018f12d4c0f318ad9e194c951038c40e2c7214a042c61a
rebuilds_between_samples=0
```

The retained three-second preflight observed 16 logical CPUs, aggregate
average idle 92.31%, and pinned CPU 0 average idle 95.65%. No competing
Zig, z_llvm, or GDB workload was active. Every run used CPU 0, `LC_ALL=C`,
the same absolute input, identical environment with the two selector
environment variables unset, and the same page/cache policy.

## Standing counterbalanced performance protocol

Exactly two discarded warmups ran per artifact in `A B A B` order:

```text
warmup_A1=49.11s/96468KiB
warmup_B1=49.08s/96276KiB
warmup_A2=48.76s/96464KiB
warmup_B2=49.12s/96284KiB
```

All four warmup reports hash to `49a19f04`. Exactly six retained pairs then
ran in the mandated `AB, BA, AB, BA, AB, BA` order. Every sample is retained;
there was no outlier removal, rebuild, or additional timing run.

```text
pair order A_wall_s A_maxrss_KiB B_wall_s B_maxrss_KiB B/A
1    AB    48.71    96476        49.02    96280        1.006364196
2    BA    49.79    96464        49.63    96280        0.996786503
3    AB    49.40    96468        49.73    96284        1.006680162
4    BA    49.33    96456        49.65    96288        1.006486925
5    AB    49.53    96468        49.71    96280        1.003634161
6    BA    50.45    96468        50.03    96280        0.991674926
```

Every retained report hashes to
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.

```text
median_A_s=49.465
median_B_s=49.680
ordinary_delta_s=0.215
ordinary_allowed_delta_s=max(49.465*0.05,0.100)=2.47325
ordinary_ratio=1.004346508
ordinary_median_gate=PASS

paired_ratio_median=1.004999178
paired_ratio_limit=1.05
paired_ratio_gate=PASS

A_maxrss_KiB=96476
B_maxrss_KiB=96288
maxrss_delta_KiB=-188
maxrss_limit_KiB=16384
maxrss_gate=PASS
```

The ordinary median and paired-ratio criteria both pass. The sequence is
interleaved and has no monotone warmup decay.

Retained procedural manifests:

```text
timed_report_manifest_sha256=f9a99c7676d93c4e0317d40912788a85e7c3e09d73d0db1fff5d982d2fdcb8dc
timed_raw_manifest_sha256=e359ff6bd82f2496fed080a71b5c4e61457e7bed7faca4752465229fd9d5f919
warmup_log_manifest_sha256=03f507816ffbfdb543b7b383345170d35d77fef804eaf2bb9f9a318ac77c9e1c
```

## Transaction and snapshot accounting

The frozen candidate was measured procedurally over the full cohort after
the performance batch:

```text
table_i16_rows=2
outer_transactions=2
outer_snapshots=2
table_i16_actions=2
accumulator_sessions=0
snapshot_bytes=149761
copy_bytes=299522
snapshots_per_transaction=1
maximum_nesting=1
metrics_log_sha256=e6263666a20c6088bb6f54e6aaac6dd2ebad5c023dedb6500a6e4e96cdf1978f
snapshot_nesting_gate=PASS
```

## Frozen identities and validation

```text
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
target_rows_advanced=0

exp_diagnostic=composed-block-gep-readonly-table-global
expf_diagnostic=composed-block-gep-readonly-table-global
exp_expf_A_B_sha256=7f8a30a544eaad98b1b333fc37d6da1088b1f1f5cd361f0b5eb6e4e08742ade6
exp_expf_byte_identical=PASS
```

```text
full_unit=1214/1214
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=baf466bea67e6036c2bb1eb0699c8d33814f141f9710fdeeeba767495c795d16

focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133

integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949

strengthened_tier2=28/28 steps; 1222/1222 tests
strengthened_tier2_log_sha256=69212d7c388d1599e5c48c89e10674f36146ccd28ce94d340cbf052063dc774f
```

No Tier 3 was run. INBOX-109 stops here for review; on acceptance the load
family is complete.
