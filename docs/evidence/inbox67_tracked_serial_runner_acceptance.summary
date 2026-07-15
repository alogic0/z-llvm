# INBOX-67 tracked serial-runner acceptance

directive: INBOX-67
status: acceptance criteria satisfied; review requested
date: 2026-07-15
validated_commit: b1b1d2fbf79dec2da0e3825df06355a44e6f7bd3

## Delivered authority

`tools/run_distribution_all_gates.zig` now provides the supported tracked
serial path:

```text
zig build distribution-all -- --serial
```

It uses the same single 17-entry inventory as the unchanged default parallel
mode. Serial scratch and bundle paths are created exclusively with a random
run identity, an explicitly supplied path is refused if it exists, cleanup is
limited to the path owned by the run, and `BundleAlreadyPublished` remains
fail-closed. `tools/distribution_headroom_policy.zig` is the shared
machine-readable authority consumed by both the runner and the report-only
retention inventory.

The former untracked wrapper
`tmp/inbox66c_serial_tier3_fresh.sh` remains present as historical evidence but
is obsolete and is not an execution authority.

## Focused and bounded validation

`zig test tools/run_distribution_all_gates.zig` passed 14/14 tests. These
include a fake bounded 17-subgate orchestration proof, exact order and start/end
record counts, repeated unique invocations, pre-existing-path refusal without
mutation, partial-publication cleanup limited to run-owned scratch, immutable
bundle republish refusal, consumer identity mismatch, and first-sample
minimum-free arithmetic. No fixture invoked a real distribution gate.

The tracked inventory was compared with the accepted INBOX-66C gate-start
contract after replacing only the bundle path with the common
`<runner-owned-bundle>` token:

```text
accepted_records=17
tracked_records=17
accepted_inventory_sha256=12bfb209d158fd4f7089ab4693a3b049b9644e3b05f2a444febc548c7199bca6
tracked_inventory_sha256=12bfb209d158fd4f7089ab4693a3b049b9644e3b05f2a444febc548c7199bca6
```

## Fresh real preflight

The fresh `df` observation and report-only retention inventory recorded:

```text
filesystem_total_bytes=982240026624
filesystem_free_bytes=115098984448
serial_reserve_bytes=49112001332
serial_projected_peak_bytes=4419112960
serial_required_start_bytes=53531114292
serial_ready=true
retention_deleted=0
retention_report=tmp/inbox67_retention_preflight.tsv
retention_report_sha256=778f67b23adf3d5e2d0f04638c9b0fc2bdb5000c62096b112e8074289000e6d8
```

Parallel sharding remained unauthorized and was not run.

## Tracked serial Tier 3

```text
command=zig build distribution-all -- --serial
log=tmp/inbox67_serial_tier3_b1b1d2fb.log
log_sha256=3f80b4277a3394f6a645921e72d44573e61da51f24a857dfdc1ab27a2fa6b6c5
run_id=9d3795e0f467cef50fb57d53cd0ec24d
scratch_path=tmp/distribution_all_serial_9d3795e0f467cef50fb57d53cd0ec24d
bundle_path=tmp/distribution_all_serial_9d3795e0f467cef50fb57d53cd0ec24d/release_source_object_bundle
target=x86_64-unknown-linux-gnu
mode=serial
gate_start_records=17
gate_end_exit_status_0_records=17
local_fail=0
```

All start and end pairs, in authoritative order:

| # | id | end | duration_ms | cache |
| ---: | --- | --- | ---: | --- |
| 1 | selected-object-suite | exit_status=0 | 54339 | none |
| 2 | selected-object-inspection | exit_status=0 | 2344 | none |
| 3 | selected-native-link | exit_status=0 | 3810 | none |
| 4 | selected-native-probe | exit_status=0 | 3693 | none |
| 5 | zig-source-native-link | exit_status=0 | 27018 | none |
| 6 | integrated-object-postopt | exit_status=0 | 131967 | none |
| 7 | integrated-object-preopt | exit_status=0 | 561516 | none |
| 8 | integrated-object-ir-writer | exit_status=0 | 85849 | none |
| 9 | integrated-object-release | exit_status=0 | 99123 | none |
| 10 | real-rows-release-fast | exit_status=0 | 360192 | hit |
| 11 | real-rows-release-safe | exit_status=0 | 374281 | hit |
| 12 | real-rows-release-small | exit_status=0 | 308797 | hit |
| 13 | integrated-executable | exit_status=0 | 7035 | none |
| 14 | release-object-inspection | exit_status=0 | 426 | none |
| 15 | release-native-link | exit_status=0 | 1087 | none |
| 16 | release-native-probe | exit_status=0 | 1003 | none |
| 17 | boundary-gates | exit_status=0 | 715 | none |

The canonical child-summary stream is byte-identical to the accepted INBOX-66C
stream after excluding only runner/path/headroom metadata:

```text
accepted_canonical_child_summary_sha256=8cdbfcd06ddb218adfbf07960d837203f5032556e30740894353e77af82efdcb
tracked_canonical_child_summary_sha256=8cdbfcd06ddb218adfbf07960d837203f5032556e30740894353e77af82efdcb
```

The three real-row modes remain `100/100/100`, with `real_executed=0` and
`real_programs_ok=0`; the integrated executable remains 7/7.

## Bundle and headroom evidence

The source-owned bundle was published exactly once and the same identity was
observed at object inspection, native link, and native probe. All consumers
reported `executions_cached=false`:

```text
bundle_produced=1
bundle_consumers=3
bundle_identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa
executions_cached=false
scratch_removed_after_run=true
```

Durable headroom output used a real first sample, not a maximum-value sentinel:

```text
starting_free_bytes=115084627968
minimum_observed_free_bytes=115084623872
final_free_bytes=151434801152
observed_peak_bytes=4096
reserve_bytes=49112001332
required_start_bytes=53531114292
```

## Frozen identities

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi/unsupported-return-type
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_counts=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101,unassigned:0,total:285
live_ledger=167/17/101
```

INBOX-67 stops here and requests review. O1 and all later implementation work
remain unstarted and unauthorized.
