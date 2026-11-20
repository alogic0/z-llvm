# INBOX-69 bounded real-rows parallel acceptance

directive: `INBOX-69`
status: durable recovered Tier-3 evidence; review requested
date: 2026-07-15

## Evidence provenance

This record is grounded in the exact output retained by the execution session,
not reconstructed from the acceptance commit message. The recovered raw stream
contains all 17 ordered `gate-start` records, all 17 corresponding `gate-end`
records, the required gate summaries, the final tracked-runner summary, and the
terminal `ok distribution all gates` line.

```text
tested_commit=a413e579c523d949bbfda84bf25df242aaa7cd01
tested_tree=1dd29cfda9def0731eaec87e0ed3e42a8e84b12a
command=zig build distribution-all -- --serial --real-rows-concurrency=3
target=x86_64-unknown-linux-gnu
zig_version=0.16.0
ziglang_pin=bdee02bc0c7f227c0f11bc9a449df673fe803540
process_exit_status=0
run_id=1e58725d67fa2caf155d921d34edf424
raw_log=tmp/inbox69_evidence_protected/tier3_run_1e58725d_a413e579.raw.log
raw_log_sha256=95014fff0902e59d7827521c85d7ef46449830c73d61c02a8f9a2e5b42bbd076
raw_log_bytes=510326
gate_start_records=17
gate_end_exit_status_0_records=17
terminal_success_records=1
```

The run began before the evidence-only commit-message amend, but the amend did
not change the tree: the executed tree and `a413e579` tree are both
`1dd29cfda9def0731eaec87e0ed3e42a8e84b12a`. The recovered raw log lives
outside the runner-owned scratch directory and is explicitly pinned in
`docs/evidence/tmp_retention_pins.tsv` through review.

## Tracked bounded-runner contract

This is the tracked **bounded** runner. It does not claim that every subgate is
serial. `--serial` now defaults to the explicitly accepted bounded deviation
`--real-rows-concurrency=3`: only the fixed ReleaseFast/ReleaseSafe/ReleaseSmall
group runs concurrently, while every other gate retains authoritative order.
`--real-rows-concurrency=1` is the genuinely-serial diagnostic mode, as recorded
in `docs/build_steps.md`.

The accepted preopt gate remains unsharded. The historical helper
`tools/run_distribution_zig_integrated_object_sharding.zig` remains present and
non-authoritative; it is still imported by the historical normalizer and is not
removed by INBOX-69.

## All 17 completion records

These are copied directly from the recovered raw stream, in manifest order.

| # | id | exit | duration_ms | cache |
| ---: | --- | --- | ---: | --- |
| 1 | selected-object-suite | 0 | 55809 | none |
| 2 | selected-object-inspection | 0 | 2613 | none |
| 3 | selected-native-link | 0 | 4009 | none |
| 4 | selected-native-probe | 0 | 4029 | none |
| 5 | zig-source-native-link | 0 | 27938 | none |
| 6 | integrated-object-postopt | 0 | 137845 | none |
| 7 | integrated-object-preopt | 0 | 560198 | none |
| 8 | integrated-object-ir-writer | 0 | 81270 | none |
| 9 | integrated-object-release | 0 | 93070 | none |
| 10 | real-rows-release-fast | 0 | 381740 | hit |
| 11 | real-rows-release-safe | 0 | 404261 | hit |
| 12 | real-rows-release-small | 0 | 339554 | hit |
| 13 | integrated-executable | 0 | 7068 | none |
| 14 | release-object-inspection | 0 | 425 | none |
| 15 | release-native-link | 0 | 1044 | none |
| 16 | release-native-probe | 0 | 974 | none |
| 17 | boundary-gates | 0 | 760 | none |

The exact gate-7 command in the recovered stream is the accepted unsharded
`tools/run_distribution_zig_integrated_object.zig --pipeline=preopt` command.

## Fixed real-row group

```text
schema_version=1
normalization_schema=1
concurrency=3
workers=3
modes=ReleaseFast,ReleaseSafe,ReleaseSmall
cache_status=hit,hit,hit
pin_manifest_sha256=447a25fd740c69aeb78bd4831d9fceb15d77090933c621ab28f902e25cd456fe
air_cache=read-only
pruning=suspended
execution_results_cached=false
wall_ms=520637
summed_child_ms=1125555
filesystem_total_bytes=982240026624
floor_bytes=98224002663
projected_peak_bytes=4834125664
required_start_bytes=103058128327
starting_free_bytes=146544300032
minimum_free_bytes=145790963712
final_free_bytes=146005495808
peak_disk_bytes=539168137
peak_aggregate_rss_bytes=5674168320
minimum_available_memory_bytes=11453317120
memory_floor_bytes=8589934592
load_start=2.35
load_end=2.82
local_fail=0
```

Each buffered mode summary was validated before replay. All three retained
`candidate_rows=100`, `real_functions_lowered=100`,
`real_objects_emitted=100`, `real_native_linked=100`, `real_executed=0`,
`real_programs_ok=0`, no first failure, and `local_fail=0`, in
Fast/Safe/Small order.

## Bundle identity

The raw stream records one atomic producer and three uncached consumers with
the same identity:

```text
bundle_path=tmp/distribution_all_serial_1e58725d67fa2caf155d921d34edf424/release_source_object_bundle
producer_rows=100
producer_atomic_publication=true
bundle_identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa
bundle_produced=1
bundle_consumers=3
consumer_object_inspection_identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa
consumer_native_link_identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa
consumer_native_probe_identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa
consumer_executions_cached=false
local_fail=0
```

## Authoritative full-run wall and threshold

```text
full_run_wall_ms=1497915
full_run_starting_free_bytes=146566893568
full_run_minimum_observed_free_bytes=146543841280
full_run_final_free_bytes=146543841280
full_run_observed_peak_bytes=23052288
full_run_local_fail=0

baseline_authority=INBOX-67 accepted tracked Tier-3 run, cross-commit comparison
baseline_validated_commit=b1b1d2fbf79dec2da0e3825df06355a44e6f7bd3
baseline_tree=b699c4666ce01d12ae7384aaa62e0a888fe8c3be
baseline_log_sha256=3f80b4277a3394f6a645921e72d44573e61da51f24a857dfdc1ab27a2fa6b6c5
baseline_wall_ms=2023200
acceptance_ceiling_ms=1820900
absolute_saving_ms=525285
reduction_percent=25.9630782918
ceiling_margin_ms=322985
threshold_met=true
```

The baseline is deliberately labeled cross-commit, matching the INBOX-69
binding specification. The percentage uses full-run wall, never summed child
duration.

## Focused c1/c3/race-repeat equivalence

The three focused streams were recovered from the same execution-session
transcript and retained beside the final raw log. Raw hashes preserve their
volatile measurements:

| run | raw bytes | raw SHA-256 | wall_ms | summed_child_ms |
| --- | ---: | --- | ---: | ---: |
| c1 | 4681 | `1cad73e95dfc563fbcebfd5ef238dc425a82ef466f8a0701ea05ecbe72556a2f` | 1177742 | 1060271 |
| c3 | 4680 | `f5c834eb107f6c5395bc2b7822f76b142f96a030cb8eae241a498e822b20497c` | 508675 | 1099419 |
| c3 repeat | 4680 | `06e07e2023716f19827c515102af2b5ee30e7a2bfc35de901cf6291ea0d92dc7` | 515160 | 1114265 |

The tracked derivation tool is
`tools/normalize_real_rows_parallel_output.zig`; its frozen authority is
`docs/evidence/real_rows_parallel_normalization_v1.md`, schema version 1. Each
persisted normalized stream is 2469 bytes and hashes to:

```text
focused_c1_normalized_sha256=576470e2ec17ae6714f6ebc5e41f42229c790a9289b5287a06d78eb8f9711f4a
focused_c3_normalized_sha256=576470e2ec17ae6714f6ebc5e41f42229c790a9289b5287a06d78eb8f9711f4a
focused_c3_repeat_normalized_sha256=576470e2ec17ae6714f6ebc5e41f42229c790a9289b5287a06d78eb8f9711f4a
c1_equals_c3=true
c3_equals_c3_repeat=true
```

Normalization removes only the volatile fields authorized by schema v1. Mode
identity/order, cache keys and status, descriptor sizes, candidate identity,
counters, diagnostics, and failure state remain exact.

## Frozen identities

The final Tier-3 boundary gate exited zero on the unchanged tested tree. The
hash baselines below come from the accepted tracked identity authority in
`docs/evidence/inbox67_tracked_serial_runner_acceptance.md`; the recovered
runner stream does not reprint these hashes, so this provenance is explicit.

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi/unsupported-return-type
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_counts=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101,unassigned:0,total:285
live_ledger=167/17/101
```

INBOX-69 stops here for final review. No O1, broader parallelism, or historical
preopt-tool removal is included.
