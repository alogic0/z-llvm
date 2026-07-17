# INBOX-108 — O2-3L-B2 definitive re-measurement and conditional landing

Status: PASS; the exact preserved INBOX-107 wiring is eligible to land.

Date: 2026-07-16

## Frozen source and patch identity

```text
accepted_code_parent=79f69f192c4c3ae3ecdf142fd609578e369acd55
supervisor_docs_head_before_landing=693924784ffb81c57b5df7c69c18589c4c9f89a2
zig_version=0.16.0
preserved_patch=tmp/inbox107_readonly_load_perf/inbox107_l_b2_preserved.patch
preserved_patch_sha256=876f579798e271528fe28ecd5bd1427004a17874d4188d8a1d2af527f16046e0
reapplied_B_diff_sha256=876f579798e271528fe28ecd5bd1427004a17874d4188d8a1d2af527f16046e0
landing_worktree_diff_sha256_before_summary=876f579798e271528fe28ecd5bd1427004a17874d4188d8a1d2af527f16046e0
frozen_input=tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
frozen_input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
```

The preserved patch was materialized from the untouched INBOX-107 stop
state, hash-verified before use, checked against a clean detached
`79f69f19` worktree, and applied there without fuzz or edits. The active
landing diff was independently re-hashed to the same value. `stash@{0}`
remains untouched.

The frozen action, transaction, state, and pair-authority files have no
diff. This landing changes only the readonly-pointer consumer, its tests,
the function-scoped source guard, and the three exact inventory/evidence
files carried by the preserved patch.

## Original INBOX-107 stopped batch retained

The original sequential batch remains at
`tmp/inbox107_readonly_load_perf/`; its stop record is
`tmp/inbox107_readonly_load_perf/inbox107_l_b2_performance_hard_stop.md`.
It is not discarded or replaced.

```text
original_A_median_s=49.19
original_B_median_s=51.66
original_delta_s=2.47
original_allowed_delta_s=2.4595
original_B_sequence_s=53.16,53.36,51.66,49.58,49.40
original_result=hard-stop; visibly nonstationary monotone decay
```

INBOX-108 is the one Reviewer-authorized definitive re-measurement.

## Immutable artifacts and idle preflight

Both artifacts were completely built before any warmup or timed sample.
They were copied to read-only mode `0555`; neither was rebuilt or changed
during the protocol.

```text
A_source=detached 79f69f192c4c3ae3ecdf142fd609578e369acd55
A_binary=tmp/inbox108_readonly_load_remeasure/artifacts/A/z_llvm
A_binary_sha256=73c94bcc2b4610a3b6c19846081a20eff28a23d3dbd45f237221042f5ae65010
B_source=detached 79f69f19 + exact preserved patch
B_binary=tmp/inbox108_readonly_load_remeasure/artifacts/B/z_llvm
B_binary_sha256=da61914dfe593dd2fe248eab85a740c78becdbc90c7dd08d3cc03cd71c24ffc4
artifact_mode=0555
rebuilds_between_samples=0
```

The preflight observed 16 logical CPUs, aggregate idle `98.14%` over
three one-second samples, and pinned CPU 0 idle `98.33%`. No Zig,
z_llvm, or GDB workload was active. Every run used CPU 0, `LC_ALL=C`,
the same environment with `ZLLVM_CODEGEN_REPORT_ALL` and
`ZLLVM_GENERIC_CFG_SELECTOR` unset, the same absolute input, and the same
page/cache policy.

## Definitive protocol

Exactly two discarded warmups ran per artifact in `A B A B` order.
All four retained warmup logs hash to the frozen report identity
`49a19f04`.

Exactly six timed counterbalanced pairs then ran:

```text
AB, BA, AB, BA, AB, BA
timed_runs=12
outlier_removal=none
additional_reruns=none
warmup_log_manifest_sha256=74e4eb9f5f64ecb5d3cf7f055fb02b0c67806511784414b6465f4e4b3bc6593b
timed_raw_manifest_sha256=8b6ec9a4b123cd38017e01d46ea7b63efcead33218ffa8133c30dca5a0cb3b00
timed_report_manifest_sha256=73c386eea201a9c879d0073d936a06d045166d3a93b4921c6f8297366f5b56ed
```

Every timed report log hashes to
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.

## All timed samples

```text
pair  order  A_wall_s  A_maxrss_KiB  B_wall_s  B_maxrss_KiB  B/A
1     AB     49.27     95260         49.49     96140         1.004465192
2     BA     49.38     95256         49.43     96132         1.001012556
3     AB     49.33     95256         49.50     96124         1.003446179
4     BA     49.57     95248         49.50     96136         0.998587856
5     AB     49.61     95252         49.44     96132         0.996573272
6     BA     49.35     95264         49.32     96120         0.999392097
```

The series is stationary at the protocol's resolution: A spans
`49.27..49.61 s`; B spans `49.32..49.50 s`; neither has the stopped
batch's multi-second monotone decay.

## Blocking performance decision

```text
median_A_s=49.365
median_B_s=49.465
ordinary_delta_s=0.100
ordinary_ratio=1.002025727
ordinary_allowed_delta_s=max(49.365*0.05,0.100)=2.46825
ordinary_median_gate=PASS

paired_ratio_median=1.000202326
paired_ratio_limit=1.05
paired_ratio_gate=PASS

A_maxrss_KiB=95264
B_maxrss_KiB=96140
maxrss_delta_KiB=876
maxrss_delta_MiB=0.855469
maxrss_limit_MiB=16
maxrss_gate=PASS
```

Both mandatory timing criteria pass. No threshold changed.

## Transaction/snapshot metrics

The retained procedural metrics log is
`tmp/inbox107_readonly_load_perf/readonly_load_metrics.log`, SHA-256
`cf8412adde2e254a119c9a86cd1f87539caa963c70077dac213702a3c8a4c017`.

```text
form       transactions  snapshots  subordinate_sessions  pair_actions  rollbacks  copy_bytes
i8         6             6          6                     0             0          898566
i16        2             2          2                     0             0          299522
i32        29            29         29                    0             0          4343069
i56        2             2          2                     0             0          299522
i64        6             6          6                     0             0          898566
i96_pair   6             6          0                     6             0          898566
i128_pair  6             6          0                     6             0          898566
total      57            57         45                    12            0          8536377
```

```text
snapshot_bytes=149761
snapshots_per_transaction=1
subordinate_snapshot_copies=0
maximum_nesting=1
active_at_exit=0
close_underflow=0
snapshot_nesting_gate=PASS
```

Focused production tests cover direct-pointer overlap relocation through
RDI, spill-backed pointer staging before the existing pair chooser, both
i96 and i128 pair bindings, the i96 EAX high-limb zero-extension, and the
exact i56 instruction/EFLAGS sequence. Existing focused rollback tests
cover pointer staging, preservation, partial loads, scalar definition,
pair result binding, and exact combined restore.

## Ratchet and frozen identities

```text
bypass_inventory_before=219
bypass_inventory_after=216
ratchet_delta=-3
removed_site=lowerReadOnlyPointerIntegerLoad/resolveValue x1
removed_site=lowerReadOnlyPointerIntegerLoad/materializeLocIntoLoc x2
bypass_inventory_sha256=c5cf3caa4f4edfc715d8e139d736b399a4fb0b70a82b82f17af182ec88aace3e
source_guard=PASS; exact function/action classification

report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
exp_diagnostic=composed-block-gep-readonly-table-global; byte-identical A/B
expf_diagnostic=composed-block-gep-readonly-table-global; byte-identical A/B
target_rows_advanced=0
```

## Remaining INBOX-107 gates

```text
full_unit=1211/1211
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=9347cfdbfb913704463a6695f4d82979a0663558822e8d9a17e985eca6905215

focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133

integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949

strengthened_tier2=28/28 steps; 1219/1219 tests
strengthened_tier2_log_sha256=1d7b6bd94cccdc8dad5ab8825b05ae74077043422cacba94c182130ba0a5238a
```

No Tier 3 was run. The readonly-pointer load family is conditionally
landed for Supervisor/Reviewer review; the table-i16 semantic slice remains
separate and is not started.
