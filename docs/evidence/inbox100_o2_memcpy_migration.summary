# INBOX-100 — O2-3M-B lowerInlineMemcpy migration

Status: complete and validated; delivered for Supervisor/Reviewer review. The
memcpy family is complete. No later O2 family is authorized by this slice.

## Frozen source and preserved work

The accepted M-A2 model is commit
`2b9ec558` (tree `7b8df946e4c74325be2f043d32feb9a370ca3762`). The working branch also
contained the Supervisor documentation-only descendants `f30aaf30` and
`06a085be`; their only production-independent change from M-A2 is
`docs/next_steps.md`. The ValueUseTransaction action, planning, provenance, and
materialization implementation has no diff from M-A2.

The previously hard-stopped M-B wiring was preserved and reconciled without
moving the branch or using a reset:

```text
patch=tmp/inbox98_memcpy_perf/inbox98_mb_hard_stop.patch
patch_sha256=31f46fb9bd2973c85498078752d6a2c3b60d6ec285aabc04d583a6e127eda38a
stash_preserved=stash@{0}: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

## Complete memcpy consumer wiring

`lowerInlineMemcpy` still rejects every unsupported call form, signature,
tail-kind, volatility, and operand shape before opening a transaction. Each
admitted memcpy now opens one instruction-level `ValueUseTransaction`,
registers destination, source, and length semantic requests before mutation,
seals the complete plan, performs the existing authoritative caller-clobber
preservation exactly once, stages RDI then RSI then RDX, appends
`memcpy_rdi_rsi_rdx_rax` with its EFLAGS clobber, and commits only after the
complete call sequence.

The consumer performs no home/class admissibility precheck. Transaction errors
are caught first and then classified by the narrow M-A2 provenance API. The
mapper retains the locally registered destination/source/length handles and is
the sole production site containing exactly three `failedRequestIs` calls. It
does not inspect request identity, location, binding, or internal provenance.
Global errors still match no request.

Focused production tests prove independent unresolved destination, source, and
length failures. The source case produces exactly
`unsupported_value/composed-block-memcpy-src`. Additional tests cover the exact
RDI/RSI/RDX/call stream, accepted aliasing and operand forms, pre-transaction
diagnostics, copy-cycle rejection before mutation, and rollback after
preservation, each argument stage, and call append.

## Exact bypass and guard ratchet

The three frozen `lowerInlineMemcpy/emitValueIntoScratch` occurrences were
removed, moving the bypass inventory exactly from 231 to 228 occurrences. The
classification and composition records now mark only this complete consumer as
migrated; no parent helper was absorbed.

```text
bypass_inventory_sha256=a3cb560135662ded6f0a9abe004e9c4d2d5a5d43b4afc5c4bc666fdea0796abc
classification_sha256=777aa8fceb907cf6b72b10f6f7825da506e128be0f497053af64742ed41af602
composition_sha256=1f275768ea110afb91a8f03b21e84cbe19e2ecd7dbea46f9c7c57351b1be3110
memcpy_ratchet_sha256=0ac97af539858797fb73c9fb43eb6815fbf708bae4130558192678a98d69db34
```

The source guard admits the closed memcpy request/action forms only inside
`lowerInlineMemcpy`, requires all old direct materializers to be absent there,
and confines the three provenance queries to
`inlineMemcpyValueUseDiagnostic`. Addition, relocation, and query-surface
negatives pass.

## Blocking performance gate

The authoritative BEFORE binary was built in a detached worktree at exact
M-A2 commit `2b9ec558`. BEFORE and AFTER used the same frozen compiler-rt
input (SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`),
Debug candidate, `LC_ALL=C`, CPU 0 via `taskset`, one warmup, and five measured
report-all runs. Every retained run took the expected report-all exit and
reproduced `49a19f04`.

```text
before_raw=tmp/inbox100_memcpy_perf/before_samples.raw
before_raw_sha256=1b9884cfcaef86d1b18aa7237143819c0dff096bb34e300b0a6ea8af640b0c37
before_warmup_seconds/rss_kib=49.60/95816
before_1_seconds/rss_kib=49.19/95332
before_2_seconds/rss_kib=49.62/95844
before_3_seconds/rss_kib=49.23/95828
before_4_seconds/rss_kib=49.63/95824
before_5_seconds/rss_kib=49.39/95816
before_median_seconds=49.39
before_max_rss_kib=95844

after_raw=tmp/inbox100_memcpy_perf/after_samples.raw
after_raw_sha256=793c4ff88ec5e5da5afe11bed0b8a7796750411e4d0d6440c29f2fb230393a55
after_warmup_seconds/rss_kib=49.34/95956
after_1_seconds/rss_kib=49.49/95960
after_2_seconds/rss_kib=50.02/95960
after_3_seconds/rss_kib=49.74/95952
after_4_seconds/rss_kib=49.92/95964
after_5_seconds/rss_kib=49.42/95956
after_median_seconds=49.74
after_max_rss_kib=95964

median_delta_seconds=+0.35
wall_limit_seconds=+2.4695
max_rss_delta_kib=+120
rss_limit_kib=+16384
performance_result=pass
```

Procedural debugger counters were collected outside canonical output:

```text
family=lowerInlineMemcpy transactions=3 snapshots=3 commits=3 rollbacks=0
preservation_calls=3
destination_stages=3 source_stages=3 length_stages=3
safe_candidates=0 early_executed=0 transactions_with_early=0 max_early=0 demoted=0
eflags_record_attempts=3
max_active_nesting=1 active_at_exit=0 close_underflow=0
stage_sequence_errors=0
snapshot_bytes=149761
copy_volume_bytes=449283
copy_volume_mib=0.428470
snapshots_per_transaction=1
metrics_log_sha256=bfa7859a61e9f915e73f0b2e42fd042b550c327cba21864047bc16a1fca6cbfe
snapshot_size_log_sha256=52f5c8d4c680137bad1ebc24f872f828bcfd17697b28ff5a6233cfd472ef3e0d
```

Thus each admitted memcpy takes exactly one address-domain snapshot and one
caller-clobber-preservation pass, transaction nesting is constant at one, and
the semantic argument staging sequence has no ordering error.

## Frozen byte identities

The decisive fresh report is
`tmp/inbox100_memcpy_perf/decisive_report.log`:

```text
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

`compiler_rt.exp.exp` and `compiler_rt.exp.expf` remain byte-identical at
`no_emitter/composed-block-gep-readonly-table-global`. None of the twelve O2
frontier targets advanced.

## Non-Tier-3 validation

```text
full_unit=1189/1189
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log_sha256=4d74989c7e27857cd5757724dba27d49988c0c438a48126776c85c5a96946e5b
focused_codegen_canaries=2/2; execution_cases=35; local_fail=0
focused_canaries_log_sha256=7671352de65ca9f993fcd8be0e0038bbded33f2fb36be581ffcaa6fb9f15c133
integrated_exe=7/7; local_fail=0
integrated_exe_log_sha256=664002ce0d952c3d046c34bf4dd7c54939e1b596447ad955035598a61c2f2949
strengthened_tier2=28/28 steps; 1197/1197 tests
strengthened_tier2_log_sha256=5d7ed8ff3f1a403b4c71478d56392a8b3342f46b4e4cad3ea5826a7e208727f7
source_guard=ratcheted-current-tree-pass
tier3=not-run
```

Stop here for INBOX-100 review. The memcpy family is complete.
