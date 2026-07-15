# INBOX-66C acceptance-gate continuation

directive: INBOX-66C
status: acceptance criteria satisfied; INBOX-66 acceptance requested
date: 2026-07-15
validated_commit: bfb263d9a61f2cda82d39699e8ac7a489b470661

## Bounded correction

Commit `bfb263d9` changed exactly the two authorized strings in
`tools/run_distribution_linker_boundary.zig`: the expected help substring and
the success summary now include `selection-owner-manifest`. No production,
parser, selector, ABI harness, gate-order, or counter change is present.
`INBOX-66C` is acknowledged by id in that commit.

Focused validation:

```text
zig build distribution-linker-boundary --summary all
Build Summary: 2/2 steps succeeded
ok distribution linker boundary [local emit=ir/asm/obj/ir-writer/semantic-descriptor/selection-owner-manifest, executable handoff=zig cc, native proof=zig build-exe -fno-lld]
```

Tier 2 was not repeated, as directed. The previously completed strengthened
Tier 2 remains 28/28 steps, 1034/1034 tests, and ABI `abi-diff-v2` 60/60/30.

## Fresh serial preflight

The continuation's second fresh `df` observation was:

```text
filesystem_total_bytes=982240026624
filesystem_free_bytes=115192393728
serial_required_start_bytes=53531114292
serial_ready=true
```

The retention reporter ran only in report-only mode. It recorded `deleted=0`;
parallel-sharding readiness was not used and no cleanup or sharding was
authorized.

```text
retention_report=tmp/inbox66c_freshbundle_retention_preflight.tsv
retention_report_sha256=cc2195a7b1cf98c0a97ad9885a6e9a9d6eed29fb396a954be58bb78f49d84e07
```

## Fresh immutable bundle authority

The ignored serial wrapper generated and checked a run-unique bundle path
before starting. It failed closed if that path already existed, did not delete,
rename, overwrite, or reuse `tmp/inbox66_release_bundle`, and passed the same
path to the publisher and all three consumers.

```text
wrapper_path=tmp/inbox66c_serial_tier3_fresh.sh
wrapper_sha256=d50ee8c8309f19f9c9f3debc0a26b9816be37a7ce5593d5124552d80fec93c1b
bundle_path=tmp/inbox66c_release_bundle_20260715T144810Z-3750230
bundle_preexisting=false
execution=serial
sharding=false
```

The bundle publisher produced 100 rows atomically with identity
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.
Object inspection, native link, and native probe each reused that exact bundle
identity with `executions_cached=false`. `BundleAlreadyPublished` was not
weakened.

## Complete serial Tier 3

```text
log=tmp/inbox66c_serial_tier3_bfb263d9_fresh.log
log_sha256=61949b63b783b538accb4a564aaefca4a2c6c51abcdb2a663b7300c3eb82063e
clean_gate_end_records=17
subgates=17
local_fail=0
```

All 17 serial subgates passed. The corrected final boundary emitted the new
success string and `gate-end index=17 id=boundary-gates exit_status=0`.

The three separate compiler-core real-row summaries remained
`distribution-real-rows-v2`, one per ReleaseFast/ReleaseSafe/ReleaseSmall:

```text
candidate_rows=100
real_functions_lowered=100
real_objects_emitted=100
real_native_linked=100
real_executed=0
real_programs_ok=0
local_fail=0
```

The integrated executable remained 7/7. No compiler-rt ABI count was injected
into the compiler-core summary.

Headroom evidence:

```text
starting_free_bytes=115192250368
minimum_observed_free_bytes=115183722496
final_free_bytes=115183722496
observed_peak_bytes=8527872
reserve_bytes=49112001332
required_start_bytes=53531114292
```

## Frozen identities

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_detail=unsupported-return-type

accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be

owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
composed_block=40
composed_cfg=127
legacy_envelope=17
structural_fallback=101
unassigned=0
total=285
aggregate_live_ledger=167/17/101
```

INBOX-66's acceptance conditions are satisfied. Review and Supervisor
acceptance are requested. O1 was not started; O1, O2-O6, X1 implementation,
preopt sharding, and the queued tracked-serial-runner hardening slice remain
unauthorized and unstarted.
