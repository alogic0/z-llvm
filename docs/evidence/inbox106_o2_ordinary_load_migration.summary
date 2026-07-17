# INBOX-106 O2-3L-B1 Ordinary Integer Load Migration

Status: delivered for Supervisor/Reviewer review; STOP before the readonly-pointer
subfamily. Tier 3 was not run.

## Frozen scope and source identity

The accepted dormant L-A2 foundation is commit
`2fc1096cd74a9b02e7805d2cf49dbee274d49678`, tree
`05f446803afcdfaa0dc0f750f0ad3c0c13a4eb4e`. The working branch also retained
the Supervisor documentation descendants through `c1359700`; no rebase or reset
was used and `stash@{0}` remained untouched.

The implementation diff before this summary was added hashes to:

```text
implementation_diff_sha256=120d2771ae45eaa0475ce9ed02562863ba20b2670b88448df2d27f7ff6997077
```

The ValueUseTransaction action, planning, and closed load-error model remained
frozen at L-A2. No action or error variant changed in this slice.

## Production composition

`lowerLoad` still performs barrier, readonly-table, readonly-pointer, FP/XMM,
and unsupported-width dispatch before opening an O2 authority. The admitted
ordinary integer path now:

1. begins one outer `ValueUseTransaction` and registers one opaque
   `.load_address` request before mutation;
2. seals the canonical source/home plan;
3. opens one subordinate accumulator session only for genuine EAX/RAX results;
4. prepares/materializes and executes the closed scalar-load or stack-i128 alias
   action internally;
5. defines/finalizes the accumulator result when present and commits once.

The stack-i128 path uses the alias-only action and no accumulator session. The
consumer does not inspect a current home, retry resolution, or receive a prepared
location. `ordinaryLoadValueUseDiagnostic` first requires
`failedRequestIs(pointer_request)` and then exhaustively maps only the five closed
ordinary request failures needed by the legacy surface. Every unattributed or
other authority error is propagated unchanged.

Focused production coverage proves the four i16 legacy classes independently:

```text
stack scalar       -> composed-block-load-stack-width
stack array/ptr    -> composed-block-load-stack-array-width
GPR/spill pointer  -> composed-block-load-ptr-width
rejected home      -> composed-block-load-ptr
unresolved source  -> composed-block-unknown-load-ptr
```

Existing production tests also prove exact pointer-load alias displacement,
indexed dependency failure before emission, failure after result definition,
and complete rollback of instructions, bindings, spills, counters, accumulator
domain, EFLAGS, and address dependencies.

## Source-guard ratchet

The frozen resolution/materialization inventory moved exactly `221 -> 219`:
the ordinary `lowerLoad/resolveValue` and `lowerLoad/materializeLocIntoLoc`
occurrences are gone. The one surviving `lowerLoad/resolveValue` is the
pre-transaction readonly-table/O3 dispatch and is structurally guarded before
the transaction begin. The readonly-table/O3 occurrence remains classified as
a residual.

```text
bypass_inventory_sha256=5a0370e3dd922fd849d6c1e8dbc2da412be4e0251aed0598de1cd16e60088de7
production_before=221
production_after=219
classification_occurrences=254
classification_functions=91
classification_gateway_entries=150
classification_category_counts=1:22,2:0,3:110,4:34,5:49,6:39
```

The guard admits `.load_address`, `.load_scalar`, and
`.load_stack_i128_alias` only in `lowerLoad`, rejects relocation/addition and
readonly pair/table actions, permits the sole pre-transaction dispatch resolve,
and rejects a post-begin raw resolution. The former direct stack-i128
`bindValueLoc` residual and its function fingerprint were removed because the
transaction-owned alias action now owns that durable effect and rollback.

## Blocking performance gate

The authoritative baseline was recaptured before wiring in a detached worktree
at exact commit `2fc1096c`. Both sides used the same Debug candidate build,
frozen input (`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`),
`LC_ALL=C`, `taskset -c 0`, one warmup, and five measured runs.

```text
before_1_seconds/rss_kib=49.53/95436
before_2_seconds/rss_kib=49.89/96244
before_3_seconds/rss_kib=49.67/95872
before_4_seconds/rss_kib=49.44/96224
before_5_seconds/rss_kib=49.40/96216
before_median_seconds=49.53
before_max_rss_kib=96244

after_1_seconds/rss_kib=50.34/96084
after_2_seconds/rss_kib=50.90/96024
after_3_seconds/rss_kib=50.23/96020
after_4_seconds/rss_kib=49.97/96028
after_5_seconds/rss_kib=50.18/96020
after_median_seconds=50.23
after_max_rss_kib=96084

median_delta_seconds=0.70
median_delta_percent=1.4133
allowed_wall_delta_seconds=max(2.4765,0.1000)=2.4765
max_rss_delta_kib=-160
allowed_rss_delta_kib=16384
performance_gate=pass
```

Every before/after cohort log hashes to `49a19f04...`.

## Dynamic transaction metrics

GDB breakpoints outside canonical report/gate output measured current homes at
canonical load validation plus transaction lifecycle events. The current
address-domain snapshot size was measured independently as 149,761 bytes.

```text
form=stack_scalar transactions=29 snapshots=29 sessions=29 alias_only=0 rollbacks=0 copy_bytes=4343069
form=stack_i128_alias transactions=2 snapshots=2 sessions=0 alias_only=2 rollbacks=0 copy_bytes=299522
form=stack_i32_array transactions=3 snapshots=3 sessions=3 alias_only=0 rollbacks=0 copy_bytes=449283
form=stack_i32_pointer transactions=131 snapshots=131 sessions=131 alias_only=0 rollbacks=0 copy_bytes=19618691
form=gpr_pointer transactions=17 snapshots=17 sessions=14 alias_only=0 rollbacks=3 copy_bytes=2545937
form=spill_pointer transactions=112 snapshots=112 sessions=112 alias_only=0 rollbacks=0 copy_bytes=16773232
form=rejected_home transactions=0 snapshots=0 sessions=0 alias_only=0 rollbacks=0 copy_bytes=0
form=unresolved_or_immediate transactions=0 snapshots=0 sessions=0 alias_only=0 rollbacks=0 copy_bytes=0

total_transactions=294
total_outer_snapshots=294
total_subordinate_sessions=289
subordinate_snapshot_copies=0
alias_only_actions=2
rollbacks=3
snapshot_bytes=149761
copy_volume_bytes=44029734
copy_volume_mib=41.990026
snapshots_per_transaction=1
maximum_nesting=1
active_at_exit=0
close_underflow=0
metrics_log_sha256=07db794922e5803a6413c70b9f685cc605b34a9b9ddd59fa3c4f3fa5d93f1c3f
snapshot_size_log_sha256=5d1bc4ad0291dd8c557574dd5aa9e1df0fd8a417a7acd5f127d46de251c79c41
```

## Frozen identities and non-Tier-3 validation

```text
fresh_report=tmp/inbox106_ordinary_load_perf/fresh_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101

full_unit=1210/1210
abi_differential=60/60 cases; 30/30 real functions; result=pass
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1218/1218 tests
strengthened_tier2_log_sha256=e8ce7f1c819ca2ff0ff1dc5dc585cbf01e9e6a4816b4a40acaccf81c6c6dbb53
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

The full fresh report is byte-identical to the baseline, so
`compiler_rt.exp.exp` and `compiler_rt.exp.expf` retain exact
`no_emitter/composed-block-gep-readonly-table-global` diagnostics and none of
the twelve O2 frontier targets advanced.

STOP here for INBOX-106 review. The readonly-pointer load subfamily is not
started.
