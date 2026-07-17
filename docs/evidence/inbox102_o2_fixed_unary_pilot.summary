# INBOX-102 — O2-3C1 fixed-unary composition pilot

Status: complete and validated; delivered for Supervisor/Reviewer review. Stop
here. The memory-load group is not authorized by this slice.

## Frozen foundation and pre-wiring contract

The accepted composition foundation is commit
`0ef5a3247ff18c72f8e286eed82879697b5dbed5` (tree
`3b78865cbeefbdfea4d92aee7891a92a28860f6b`). The working branch also
contained Supervisor documentation-only descendants through `9e18447c`; their
only difference from C0 is `docs/next_steps.md`. The action, planning,
ValueUseTransaction, and accumulator-session model has no diff from C0.

Before production wiring, the exact seven-function contract was frozen in
`inbox102_o2_fixed_unary_contract.tsv`:

```text
contract_sha256=a6668dceff0362966b64e2f42ff02dfe8e5717cb43dbc2f30bee4fe785851b1a
functions=lowerAbsI32,lowerAbsI64,lowerCtlzI32,lowerCtlzI52,lowerCtlzI64,lowerCttzI32,lowerCttzI64
accepted_operand_destination=i32:EDI; i52/i64:RDI
accepted_order=register+seal; materialize fixed operand; prepare accumulator; emit; define+finalize; outer commit
displacement_policy=spill_live
eflags=clobber (lowerCtlzI52 then records add/write)
```

## One-owner composition

Each admitted lowering now opens exactly one outer `ValueUseTransaction`,
registers and seals its sole scalar source before mutation, materializes the
accepted RDI/EDI home, then opens and prepares the C0 snapshot-free subordinate
accumulator session. The existing unary instruction stream defines the result,
the subordinate session finalizes, and the sole outer transaction commits.
There is no independently snapshotted `AccumulatorDefinitionTransaction` in
any migrated function.

The ctlz/cttz staging failures preserve their legacy diagnostics. Abs staging
continues to propagate the same underlying failure. A focused combined-state
test executes the exact fixed-unary staging/definition sequence and forces
outer rollback both before and after subordinate finalization. Both checkpoints
restore instructions, bindings, spills, accumulator domain, EFLAGS and semantic
records, labels, dependencies, and counters exactly.

## Exact bypass and guard ratchet

The seven frozen `emitValueIntoScratch` occurrences were removed from the
bypass inventory, moving it exactly from 228 to 221. The classification and
composition records mark only these seven complete functions migrated.

```text
bypass_inventory_sha256=1cc1fbc62a1478008189b5e33a3ae33ae177a96ebf8d625cec537c6c0754315a
classification_sha256=ce6668c368f1c078aad66af021892dece814acacf77edc954538785f22c961bf
composition_sha256=d8d1e2513963d0f56e08f9abedf15bd60f93207f3ae85966283c302999776341
ratchet_sha256=5ce9a58a4a5acb47dea64665853e7708f758b75d403cda1fe4fb0e10dabcbd63
ratchet_before=228
ratchet_after=221
```

The source guard admits the subordinate composition APIs only in the exact
seven function bodies, requires one begin/prepare/define/finalize and one outer
begin/commit per body, rejects independent subordinate commit or a nested O1
transaction, and requires the direct staging bypass to be absent. Addition,
cross-function relocation, incomplete lifecycle, and outside-file negatives
pass.

## Blocking performance gate

The authoritative BEFORE binary was built in a detached worktree at exact C0
commit `0ef5a324`. BEFORE and AFTER used frozen compiler-rt input SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`,
the Debug candidate, `LC_ALL=C`, CPU 0 via `taskset`, one warmup, and five
measured report-all runs. Every retained run took the expected report-all exit
and reproduced `49a19f04`.

```text
before_raw=tmp/inbox102_fixed_unary_perf/before_samples.raw
before_raw_sha256=1cf3335e1fde2e62f2e3214a94f07f379bf46c281b07569e8688485f28923d7a
before_warmup_seconds/rss_kib=50.41/96020
before_1_seconds/rss_kib=49.84/96068
before_2_seconds/rss_kib=50.74/93764
before_3_seconds/rss_kib=51.56/95780
before_4_seconds/rss_kib=51.31/95792
before_5_seconds/rss_kib=51.43/95780
before_median_seconds=51.31
before_max_rss_kib=96068

after_raw=tmp/inbox102_fixed_unary_perf/after_samples.raw
after_raw_sha256=d197ac4ffad7b9cc9d681b0306e34ae7922df51a21f3b69a46dd8f05ca9f3ced
after_warmup_seconds/rss_kib=49.62/96064
after_1_seconds/rss_kib=50.10/96088
after_2_seconds/rss_kib=49.34/96092
after_3_seconds/rss_kib=49.10/96100
after_4_seconds/rss_kib=48.99/96092
after_5_seconds/rss_kib=49.00/96092
after_median_seconds=49.10
after_max_rss_kib=96100

median_delta_seconds=-2.21
wall_limit_seconds=+2.5655
max_rss_delta_kib=+32
rss_limit_kib=+16384
performance_result=pass
```

Procedural debugger counters were collected outside canonical output:

```text
lowerAbsI32=transactions:10 snapshots:10 sessions:10
lowerAbsI64=transactions:9 snapshots:9 sessions:9
lowerCtlzI32=transactions:40 snapshots:40 sessions:40
lowerCtlzI52=transactions:3 snapshots:3 sessions:3
lowerCtlzI64=transactions:18 snapshots:18 sessions:18
lowerCttzI32=transactions:4 snapshots:4 sessions:4
lowerCttzI64=transactions:6 snapshots:6 sessions:6
total=transactions:90 snapshots:90 sessions:90
subordinate_snapshot_copies=0
snapshots_per_transaction=1
maximum_nesting=1
active_at_exit=0
close_underflow=0
snapshot_bytes=149761
copy_volume_bytes=13478490
metrics_log_sha256=d7d2273c0dba74cc549ec69e850d131c8ae7ae2dcad358dd88255b5fe873b0d8
```

## Frozen identities

```text
fresh_final_report=tmp/inbox102_fixed_unary_perf/after_5.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

`compiler_rt.exp.exp` and `compiler_rt.exp.expf` remain exactly
`no_emitter/composed-block-gep-readonly-table-global`. None of the twelve O2
frontier targets advanced.

## Non-Tier-3 validation

```text
full_unit=1195/1195
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=a649f7e75de1c33e283df1cf7a6339fec755d3d87eae54acad12fd458e7242e2
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=ddfbbeded8bea63c0ad875c1dcf1b853b0079a8e6f97a1d7b13d4ef8159449b7
strengthened_tier2=28/28 steps; 1203/1203 tests
strengthened_tier2_log_sha256=112fb5743c86bc0bbc7e0d31a9b4c819ff1db244d0ec310e253637d1a4367c2f
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

Stop here for INBOX-102 review.
