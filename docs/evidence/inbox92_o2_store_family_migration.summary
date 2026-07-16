# INBOX-92 O2-3B2B store family production migration

Status: complete and validated; delivered for Supervisor/Reviewer review. The
branch/switch family is not authorized by this slice.

## Base and preserved work

The accepted narrow-view amendment is commit `9151ff82d6ef0935ee243a4dea1c4fce6d6c9ebf`,
tree `43c4201e30c19d34749f231a9656ffa8aceab1f1`. The working authorization
head was its documentation-only descendant
`183cb85b4ee295eaa71951ff410c8a32f2b59116`, tree
`d14ed8dd18c30efe6ad16759fca32bf06acab35d`; the only intervening path was
`docs/next_steps.md`, so the compiled B2A2 state was identical.

The preserved wiring carrier was verified before reuse and applied without
moving the branch or using a hard reset:

```text
patch=tmp/inbox92_store_perf/inbox92_store_wiring_hard_stop.patch
patch_sha256=6be43a125f2ab937365a02d54158b3c6a99181dc35892209c446d6140f26727b
git_apply_check=pass
stash_preserved=stash@{0}: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

## Complete store-family wiring

`lowerStore` remains the dispatcher. FP/XMM, unsupported-width, barrier, and
readonly-parameter paths are unchanged. The admitted integer/scalar leaves,
the parent-owned i64 path, and `lowerStoreStackPointer` each open exactly one
instruction-level `ValueUseTransaction`; the old `lowerStoreI64` helper no
longer opens or hides a nested authority.

Each selected leaf registers the pointer and value operands plus its closed
store action before mutation, then seals, prepares, materializes, executes the
action internally, and commits after the complete store succeeds. No
transaction/action/planner implementation changed from B2A2.

The stale consumer-side exact-class checks were removed. In particular, the
consumer registers `%236` as the semantic `i32/.gpr32` request and
`ValueUseTransaction.validateBindingCompatibility` alone admits the audited
low-32 view of its canonical `gpr64/64` spill binding. Store diagnostic helpers
are read-only classifications used to preserve accepted diagnostic wording;
they do not decide the value request's compatibility.

The production-path regression reproduces the exact accepted `%236` stream:

```text
reload_rsp_eax spill380
reload_arg64_rsp rcx, spill486
reload_arg64_rsp r8, spill450
add_r8_rcx
store_eax_stack_rcx4_disp32 0x1b94
```

The source binding remains `gpr64/64` in its original spill; no durable rebind,
metadata rewrite, or extension guarantee is introduced.

## Exact bypass ratchet

The frozen bypass inventory shrank by exactly the ten B2B occurrences frozen
by B2A:

```text
lowerStore             emitValueIntoEax=1 lowerStoreI64=1 materializeLocIntoLoc=1 resolveValue=2 total=5
lowerStoreI64          emitValueIntoRax=1 materializeLocIntoLoc=2 total=3
lowerStoreStackPointer resolveValue=2 total=2
ratchet_total=10
residual_occurrences=233
inventory_sha256=62888e477a39ce8de36f386051dff1049a06f321764da4c02a1211ff0272371b
```

The historical classification remains reconciled at 150 entries / 254
occurrences with category totals `22/111/33/49/39` for categories
`1/3/4/5/6`; the ten store rows now record their B2B migrated disposition.
Both store composition rows are `O2-3B2B-migrated`. The source guard also
freezes each promoted action to its exact enclosing function, rejecting an
addition or same-file relocation.

## Decisive byte identities

The fresh whole-cohort log and accepted-cohort projections are exact:

```text
full_report=tmp/inbox92_second_resume2_perf/b2b_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

None of the twelve O2 targets advanced. `compiler_rt.exp.exp` and
`compiler_rt.exp.expf` retain byte-identical
`UnsupportedCodegenControlFlow / no_emitter /
composed-block-gep-readonly-table-global` diagnostics.

## Blocking performance gate

The authoritative BEFORE series was captured first at the accepted B2A2
source state. AFTER used the same frozen input, Debug candidate, `taskset -c
0`, warmed-cache protocol, `LC_ALL=C`, and environment. The input SHA-256 is
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`.
Every run took the expected report-all exit and reproduced `49a19f04`.

```text
before_raw=tmp/inbox92_second_resume2_perf/before_samples.raw
before_raw_sha256=f0c552bb8497c7e1597713e0bf40f59ae8ae5e38d3dbee9289848ec6a0478d61
before_warmup_seconds/rss_kib=48.16/95468
before_1_seconds/rss_kib=48.36/95460
before_2_seconds/rss_kib=48.55/95476
before_3_seconds/rss_kib=48.48/95464
before_4_seconds/rss_kib=48.38/95456
before_5_seconds/rss_kib=48.24/95464
before_median_seconds=48.38
before_max_rss_kib=95476

after_raw=tmp/inbox92_second_resume2_perf/after_samples.raw
after_raw_sha256=4eab75928234a3d694d304804dfa8fc02239782a5ca7d1d88a7a6f435c7f0c8b
after_warmup_seconds/rss_kib=48.83/95532
after_1_seconds/rss_kib=48.97/95536
after_2_seconds/rss_kib=48.78/95536
after_3_seconds/rss_kib=48.98/95540
after_4_seconds/rss_kib=48.91/95532
after_5_seconds/rss_kib=48.47/95540
after_median_seconds=48.91
after_max_rss_kib=95540

median_delta_seconds=+0.53
wall_limit_seconds=+2.419
max_rss_delta_kib=+64
rss_limit_kib=+16384
performance_result=pass
```

Procedural debugger counters were collected outside canonical output:

```text
family=scalar transactions=269 snapshots=269 safe_candidates=10 early_executed=2 transactions_with_early=2 max_early=1 demoted=8
family=i64 transactions=4 snapshots=4 safe_candidates=4 early_executed=4 transactions_with_early=4 max_early=1 demoted=0
family=stack_pointer transactions=4 snapshots=4 safe_candidates=0 early_executed=0 transactions_with_early=0 max_early=0 demoted=0
total transactions=277 snapshots=277 safe_candidates=14 early_executed=6 transactions_with_early=6 max_early=1 demoted=8
max_active_nesting=1 active_at_exit=0 close_underflow=0
snapshot_bytes=149761
copy_volume_bytes=41483797
copy_volume_mib=39.562032
snapshots_per_transaction=1
```

The metric log SHA-256 is
`23b14c699d4c89661d2d35784fa29139e475860d0ab9c2a45ddfdeddf0c87ff5`;
the measured snapshot-size log SHA-256 is
`a838a712fa6a21bf1a665d7d99d72ced2133312145e6dc3997c129aeb164a8e8`.

## Non-Tier-3 validation

```text
full_unit=1157/1157
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=7f2358d3330b3f4f4574686fbbe0530dbd3540aebbee81679218d92f4de9151e
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1165/1165 tests
strengthened_tier2_log_sha256=9d3f63c3d6f4ffe9dea79c4c7728f81a479da966662b370fba2aed07ba84f891
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

Stop here for B2B review. No branch/switch action or production wiring is
included.
