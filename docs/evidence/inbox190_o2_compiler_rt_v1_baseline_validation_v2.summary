# INBOX-190 — compiler-rt v1 baseline-validation v2 execution

Status: **FAIL-CLOSED during canonical source preflight; no build,
repetition, canonical identity, or coverage phase was entered; production
remains dormant and the ratchet remains 131**.

## Authorized basis

INBOX-190 started from the exact clean tracked operating-document
authorization:

```text
operating_head=a4c9d020ec869d808cb12213c1229c159f9bd374
accepted_parent=2f1a880e096a95b9cea0fdd3b2f3294ae0f61465
contract_path=docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md
contract_sha256=499213db2540e94994c625a194b3f03fe316e442db331019687100300025a4c6
```

Immediately before the sole invocation, the tracked worktree and index
were empty, `--untracked-files=no` was empty, all v1 evidence records and
required v1 absences matched, the complete v2 root and both external v2
record prefixes were absent, capacity exceeded the frozen minimum, the
bundle and immutable input identities and modes matched, the combined
patch passed its read-only apply check, the pinned tool and source
identities matched, the production surface was identical to `43de59b0`,
and the watcher and stash identities matched.

The contract's single authorization token was replaced in memory only:

```text
token=__BASELINE_VALIDATION_V2_AUTHORIZED_HEAD__
replacement=a4c9d020ec869d808cb12213c1229c159f9bd374
token_occurrences_replaced=1
token_substituted_launcher_plus_driver_sha256=fa87620599a147327db58e4ec6a1246858fccac89221f0fe5422a6512e95dc0c
canonical_stdin_driver_sha256=30b4a934d2996eed4fea8039e279104f2d527e95526b5eddf81b8c34b9ee7fc8
generated_driver_path=NONE
```

The accepted driver was supplied exactly once to:

```text
/bin/bash --noprofile --norc -s -- a4c9d020ec869d808cb12213c1229c159f9bd374
```

The frozen sanitized environment was used. The launcher and all commands
reached by this attempt were invoked once only; no retry or alternative
was attempted.

## Preflight and driver records

The external v2 preflight completed successfully and proved the v2 root
absent before creating it:

```text
preflight_start_utc=2026-07-19T23:50:05Z
preflight_end_utc=2026-07-19T23:50:05Z
preflight_status=0
preflight_stdout_tail=preflight=pass; root_absent=1
preflight_stderr_bytes=0
```

The driver-record setup also completed:

```text
driver_start_utc=2026-07-19T23:50:05Z
driver_end_utc=2026-07-19T23:50:05Z
driver_status=0
driver_stdout_bytes=0
driver_stderr_bytes=0
```

The principal retained record hashes are:

| Retained path | SHA-256 |
|---|---|
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.command.txt` | `a27b2dfc823b0fff653d7c57ba73912d3810f7ace6d7f76694567b9df3825815` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.environment.txt` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.stdout.raw` | `1caf5c5b235793cfcc8bd0dd407a1d30f7e5a56caffde066096cf9879653c0d6` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.status` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.records.tsv` | `db603583b4c885bae86d562e96bb4ecca69a48127daeb9f9cfb23749034b1d4f` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.command.txt` | `b8b27dd1842a960698de8b9fc2f66fb29cf863aa8cfb3faa283e1cfe8ed4ca40` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.status` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.records.tsv` | `a00bc09f13770adbb46e3843301d2848e854c8ac533ac34200e6bcb9cf35d16b` |

All successfully finalized external records and their manifests are mode
`0444`. They were retained without normalization.

## Exact canonical stop

The canonical root was created and the one authorized detached-worktree
producer succeeded:

```text
worktree_add_start_utc=2026-07-19T23:50:05Z
worktree_add_end_utc=2026-07-19T23:50:05Z
worktree_add_status=0
detached_source_path=tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/source
detached_source_head=43de59b06ca3a687368bfaf0595c5759c8ab3a57
detached_source_porcelain=EMPTY
```

Its retained status is mode `0444`; the command and records-manifest
hashes are:

```text
worktree_add_command_sha256=8218cfa2d77f6a2df537d90d16b35fd25c6fb680768801a317997596476a7ce0
worktree_add_status_sha256=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
worktree_add_records_sha256=11ccd4472fee45d4bd1021218f9fe6eed4d20460ec9f9ba3af6de391a6112754
```

The immediately following `source-preflight` command returned status `1`:

```text
source_preflight_start_utc=2026-07-19T23:50:05Z
source_preflight_end_utc=2026-07-19T23:50:05Z
source_preflight_status=1
source_preflight_stdout_bytes=0
source_preflight_stderr_bytes=0
```

The exact first assertion in that retained command is:

```bash
test "$(/usr/bin/git -C "$source_root" rev-parse HEAD)" = 43de59b0
```

`git rev-parse HEAD` for the retained detached source is
`43de59b06ca3a687368bfaf0595c5759c8ab3a57`. Therefore the command
compared the full 40-character result with the eight-character literal
`43de59b0`; the strings are unequal and the first assertion failed. The
later clean-status assertion and the two output-producing `rev-parse`
commands were not reached. This exactly accounts for the empty stdout and
stderr channels.

The retained failing records are:

| Retained path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.command.txt` | 424 | `0644` | `1bcdc0771c77407bc6e793ecd76d2925c90e62f694aa58e1243e68824c68f44d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.environment.txt` | 272 | `0644` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.stdout` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.stderr` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/source-preflight.status` | 2 | `0644` | `4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865` |

The failed command stopped before its record-finalization chmod and
records-manifest producer. The `0644` modes and absent
`source-preflight.records.tsv` are the exact retained stop state; they
were not repaired or normalized.

## Skipped phases and retained-state disposition

The stop occurred before the canonical artifact build:

```text
canonical_artifact=NOT_BUILT
canonical_repetitions=0
canonical_accepted_ll=ABSENT
candidate_o2_calls_crt_v1_r131_identities=NOT_DEFINED
candidate_counters=NOT_AVAILABLE
coverage_root=ABSENT
coverage_worktree=NOT_CREATED
coverage_patch_application=NOT_RUN
coverage_guard=NOT_RUN
coverage_artifact=NOT_BUILT
observation_off=NOT_RUN
observation_on=NOT_RUN
coverage_channels=NOT_PRODUCED
section_10_restoration=NOT_ENTERED
section_11_read_only_retention=NOT_ENTERED
```

The v2 root, external preflight/driver records, canonical directory
skeleton, and detached source are retained exactly in place. The detached
worktree was not removed, repaired, normalized, or repurposed. Complete
canonical success did not occur, so the coverage root was neither created
nor entered. No restoration was improvised after the failure.

## Frozen-surface post-stop recheck

```text
main_operating_head=a4c9d020ec869d808cb12213c1229c159f9bd374
main_tracked_diff_before_summary=empty
contract_sha256=499213db2540e94994c625a194b3f03fe316e442db331019687100300025a4c6
bundle_manifest_sha256=0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
adopted_input_sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_sha256=500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
production_surface_diff_from_43de59b0=empty
exhausted_v1_evidence=unchanged
ratchet=131
```

No candidate identity was adopted. No identity consumer, main source,
production consumer, bypass inventory, pin, retention policy, watcher,
stash, or frozen input was changed. No project correctness gate,
production wiring, recount, performance run, retention reporter, cleanup,
deletion, substitution, repair, retry, or credit occurred.

## Disposition

```text
contract_attempts=1
canonical=FAIL_CLOSED_AT_SOURCE_PREFLIGHT
coverage=SKIPPED
validation=NOT_COMPLETE
protocol=NOT_ADOPTED
production=UNCHANGED_DORMANT
ratchet=131
retained_state=PRESERVED
next=STOP_FOR_WATCHER_REVIEWER_ACCEPTANCE
```
