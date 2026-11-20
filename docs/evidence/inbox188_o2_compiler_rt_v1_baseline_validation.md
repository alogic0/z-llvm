# INBOX-188 — compiler-rt v1 baseline-validation execution

Status: **FAIL-CLOSED during the sole canonical preflight attempt; coverage
not entered; validation identities not produced; ratchet unchanged at
131**.

## Authorized basis

INBOX-188 started from clean tracked operating-document commit
`d0c1d262f3b0afceb402327eff63f7e4445df950`, immediately above accepted
INBOX-187C commit `8411478a4d19504071f99d92506158732fc8e933`.
The accepted contract was:

```text
path=docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md
sha256=b8f8e266facd8c53600b15d4cbd31002bd39be87ea3159c8eadc06946b2a5387
```

Before the contracted attempt, the main tracked worktree was clean, the
future validation root and both external record prefixes were absent, the
accepted bundle/input/infrastructure identities matched, the combined
patch passed read-only `git apply --check`, and available capacity was
97,811,271,680 bytes against the 17,179,869,184-byte minimum.

## Sole canonical attempt and exact stop

Sections 5–6 were supplied once to the contract’s exact canonical shell:

```text
working_directory=/home/oleg/prog/z_llvm
environment=/usr/bin/env -i
HOME=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1
TMPDIR=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1
PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin
LC_ALL=C
LANG=C
TZ=UTC
SOURCE_DATE_EPOCH=0
shell=/bin/bash --noprofile --norc
attempts=1
```

The exact child command is retained at
`tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.command.txt`.
It returned status `1` during the first preflight assertion:

```bash
test -z "$(/usr/bin/git -C "$repo" status --porcelain)"
```

The sanitized contract environment does not inherit the user-global Git
exclude configuration. A read-only post-stop inspection using that same
environment returned:

```text
status_bytes_without_command_substitution_newline=11
status_line=?? .claude/
```

Thus the exact contract saw a nonempty main-worktree porcelain result and
failed before checking the adopted input. This is retained as a
preexisting-state stop. No ignore, repository, index, global configuration,
or `.claude/` byte was changed.

The contract’s preflight status and semantic channels are:

```text
preflight_status=1
preflight_stdout_bytes=0
preflight_stderr_bytes=0
preflight_start_utc=2026-07-19T23:12:58Z
preflight_end_utc=2026-07-19T23:12:58Z
```

Because `test "$preflight_status" -eq 0` failed, the contract correctly
stopped before its record-finalization chmod and records-manifest step.
Those retained files therefore remain exactly at the modes produced at the
stop; they were not normalized afterward.

## Retained preflight evidence

| Retained path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.command.txt` | 7,590 | `0644` | `6e0b79fe54a666343a35159c76ee9a535d0725fa33d7c7a6cd722beb3b3b6500` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.environment.txt` | 272 | `0644` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.cwd.txt` | 23 | `0644` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.start.utc` | 21 | `0644` | `8c706bdca3eb50fa2ce3c51d1d6ad236323995ca6e48f351c9d029af7bafea8d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.end.utc` | 21 | `0644` | `8c706bdca3eb50fa2ce3c51d1d6ad236323995ca6e48f351c9d029af7bafea8d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.stdout.raw` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.stderr.raw` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.status` | 2 | `0644` | `4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865` |

`baseline_validation_v1.preflight.records.tsv` is absent because its
producer is after the failed status check. The retained evidence was not
deleted, rewritten, chmodded, copied, or repaired.

## Skipped phases and retained-state disposition

The failure occurred before `$ROOT` creation. Consequently:

```text
future_root=ABSENT
external_driver_record_files=0
canonical_detached_worktree=NOT_CREATED
canonical_artifact=NOT_BUILT
canonical_repetitions=0
canonical_accepted_ll=NOT_PRODUCED
candidate_o2_calls_crt_v1_r131_identities=NOT_DEFINED
coverage_directories=NOT_CREATED
coverage_detached_worktree=NOT_CREATED
coverage_patch_application=NOT_RUN
coverage_guard=NOT_RUN
coverage_artifact=NOT_BUILT
observation_off=NOT_RUN
observation_on=NOT_RUN
coverage_channels=NOT_PRODUCED
coverage_counters=NOT_AVAILABLE
section_10_restoration=NOT_ENTERED
```

No restoration was needed or improvised: neither detached worktree nor any
patched source was created. The main-tree code/build/tool surfaces remained
unchanged.

## Frozen-surface post-stop recheck

```text
contract_sha256=b8f8e266facd8c53600b15d4cbd31002bd39be87ea3159c8eadc06946b2a5387
bundle_manifest_sha256=0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
adopted_input_sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_sha256=500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
source_surface_diff_from_43de59b0=empty
ratchet=131
```

No protocol identity was adopted. Historical identities and other retained
inputs were not substituted. No project gate, performance run, identity
consumer edit, source change, production wiring, recount, cleanup,
retention report, deletion, repair, retry, or credit occurred.

## Disposition

```text
contract_attempts=1
canonical=FAIL_CLOSED_AT_FIRST_PREFLIGHT_ASSERTION
coverage=SKIPPED
validation=NOT_COMPLETE
protocol=NOT_ADOPTED
production=UNCHANGED_DORMANT
ratchet=131
retained_state=PRESERVED
next=STOP_FOR_WATCHER_REVIEWER_ACCEPTANCE
```
