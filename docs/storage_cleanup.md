# Automatic project storage cleanup

Run the collector to review completed private compiler caches and explicitly
released artifacts. Apply mode performs the review and verified removal in one
invocation, without interactive approval:

```sh
tools/clean-storage
tools/clean-storage --apply
```

The first command writes a JSON report with eligible paths, allocated file bytes
and reasons for keeping candidates. The second discovers and checks everything
again; it does not trust an old inventory. Both print the report location under
`local-state/retirements/automatic-storage-cleanup/`. Repeating apply is safe:
already removed paths are absent from the next discovery.

The shell entry point builds a reusable **ReleaseFast** native Zig helper in
`local-state/storage-cleanup/`. It uses the project's pinned Zig version,
`zigrep` for file discovery, the unchanged `zig-file-audit` library for guarded
metadata and hashing, and standard Linux tools (`lsof`, `ps`, `sha256sum`, `git`,
`gzip`, `flock`). Set `ZIG` or `ZIGREP` to explicit binary paths if needed. No
Python or Node runtime is used. `jqz` can inspect the resulting reports:

```sh
jqz '{mode,ready,skipped,removed,reclaimed_allocated_file_bytes}' REPORT.json
jqz '.actions | each | where(.status == "skipped") | {path,reason}' REPORT.json
```

## What is automatic

| Category | Required evidence |
| --- | --- |
| Completed private compiler caches | A passed isolated compiler `report.json`, every source hash, the compiler hash, successful build commands binding source/output paths, original logs, and the Zig toolchain hash. Cache arguments must name direct children of that report's run directory. |
| Superseded raw event streams | An explicit release record, an accepted successor, a complete semantic audit bound to the exact raw SHA-256, producer/reports/input hashes, the original compiler and complete build/source evidence, and the auditor sources. |
| Superseded executable/object files | An explicit release record, accepted successor, complete source/build/input/result evidence and matching bytes. Only the supported output names and ELF/archive formats qualify. |
| Obsolete logs | An explicit release record, accepted successor, complete build/source/input/result evidence, and retained diagnostics for a failed producer. |

The cache report adapter matches the isolated prototype build reports used by
the current compiler work. Other report formats, standalone canonical build
receipts and shared caches require another qualified adapter or explicit review.
The collector does not infer that a failed parent succeeded because a child
command passed. It does not infer diagnostic redundancy from version numbers,
equal sizes, elapsed time, or an old document reference.

Only owned paths below `local-state/validations/` can be removed. Sources, IR,
shared AIR, input directories, worktrees and artifact-store objects stay outside
the rules. Use the artifact store's collector for unreachable store objects.
Hardlink aliases, symlinks, special files, foreign owners, mounted subtrees,
frozen cache directories and changed metadata/content prevent admission.

The default policy adds a **24-hour idle period**, at most **64 candidates** and
**32 GiB of allocated file bytes per invocation**. These are additional limits;
age alone never makes a file eligible. Change the reviewed policy if the desired
idle period or batch size changes.

Current release integration is manual: production validation tools do not yet
emit `storage-release.json`, and the collector does not translate earlier audit
and retirement formats. The 24-hour default can also hold private caches that
pass the other checks. The [follow-up plan](plans/2026-11-13-storage-cleanup-followups.md)
records the measured coverage gaps and the changes needed to address them.

## Current work and retention pins

[storage_cleanup_policy.json](storage_cleanup_policy.json) records the five
current integrity manifests and known protected directories. Their complete
hash checks must pass. A missing or changed required control blocks apply.
The collector also discovers checksum manifests, artifact manifests and retained
paths in retirement records. Newly introduced references are checked before
each mutation. Relative checksum paths are resolved against possible ancestor
working directories, conservatively retaining overlapping candidates.
Bare digest fingerprints with no named target hold their entire containing run.
Other unknown checksum formats stop the collector for review.

The two explicitly retired historical seals are recorded by exact file hash in
`retired_manifests`. Their original files remain intact. A changed seal is not
silently treated as retired; a current manifest cannot also be retired. Other
historical references remain blocking until their specific retention contract
is reviewed and updated. This avoids both guessing that an old pin expired and
treating every historical reference as an eternal hold.

For queued work, create `local-state/storage-cleanup/holds.json` before admitting
the job. Paths are project-relative and can name a file or a whole run:

```json
{"schema":1,"paths":["local-state/validations/example/batch/current-run"]}
```

Wrap builds and readers in the shared lease:

```sh
tools/clean-storage exec -- zig build test-unit
```

The collector takes an exclusive lock on the same file and exits if a reader,
build or another collector holds it. It also checks commands, working directories,
mapped executables and open descriptors under each candidate run. Process checks
are point-in-time observations. The lease and queued-work holds close the
scheduling gap for cooperating jobs; a process that bypasses both can start
after a check. Use the lease for unattended operation alongside producers.

## Releasing traces, binaries and logs

The owner of a completed run writes `storage-release.json` inside that run when
an accepted successor makes selected outputs obsolete. This is an explicit
lifecycle declaration, not a conclusion the collector guesses from filenames.
Every digest below must be the actual SHA-256; the placeholders are deliberately
invalid so copying this example cannot delete anything.

```json
{
  "schema":"zllvm-storage-release-v1",
  "state":"superseded",
  "run_root":"local-state/validations/example/batch/old-run",
  "reason":"Accepted successor replaces this completed experiment",
  "producer":{"path":"local-state/validations/example/batch/old-run/producer.json","sha256":"<sha256>"},
  "successor":{"path":"local-state/validations/example/batch/new-run/report.json","sha256":"<sha256>"},
  "retained":[
    {"path":"local-state/validations/example/batch/source/main.zig","sha256":"<sha256>","role":"source"},
    {"path":"local-state/validations/example/batch/old-run/input.ll","sha256":"<sha256>","role":"input"},
    {"path":"local-state/validations/example/batch/build/report.json","sha256":"<sha256>","role":"build"},
    {"path":"local-state/validations/example/batch/old-run/producer.json","sha256":"<sha256>","role":"result"},
    {"path":"local-state/validations/example/batch/old-run/failure-summary.json","sha256":"<sha256>","role":"diagnostic"}
  ],
  "artifacts":[
    {"path":"local-state/validations/example/batch/old-run/result.o","sha256":"<sha256>","kind":"build_output"}
  ]
}
```

The producer must have a terminal status; the successor must report `passed`.
Required retained roles are `source`, `input`, `build` and `result`, plus
`diagnostic` for a producer not recorded as passed. A `build` row must be a
supported isolated build report: the collector verifies its entire source map,
compiler and successful command binding. Role labels alone are insufficient.
All retained evidence wins over deletion candidates, including across records.

For `raw_trace`, the artifact name must be `profile.events.jsonl`, with an `audit`
path and retained `audit` and `compiler` roles. The audit must use
`zllvm-native-event-audit-v1`, validate the entire closed stream and bind its raw
hash, producer, backend/top reports and input. Retain those bound files with
their exact hashes. The top report's compiler must match the preserved build.
Incomplete or interrupted traces stay retained. The auditor's core and driver
sources are also checked and kept. This automation consumes a qualified audit;
it does not manufacture one or claim a failed compilation passed.

Release records can use `state:"held"` until all evidence is ready. Update the
policy's current manifests and explicit holds as checkpoints advance. Do not
remove a hold merely to get a desired disk-saving number.

## Mutation and evidence

The tool verifies each candidate again, records a durable pending action, moves
it without replacing an existing destination, verifies it after the move and
then removes only inventoried paths. A complete cache root is retired together;
it never removes just objects while leaving stale cache manifests. Source/input
evidence is rechecked afterward and original parent permissions are restored.
Recorded Git source revisions are pinned under
`refs/retirements/storage-cleanup/` when applying.

Each invocation keeps its policy/control hashes, candidate decisions, source
references and actual released allocation. Cache snapshots preserve file hashes
and identities; completed snapshots are losslessly gzip-compressed with a
decompression/hash comparison. No duplicate archive of the original run is
created. The small helper binary/cache is reused across invocations.

Reported savings count allocated **regular-file** bytes on final-link removal.
Directory blocks are excluded; existing hardlinks are rejected, and filesystem
reflinks/shared extents are not measured. Free-space movement also includes
concurrent builders and is not used to claim reclaimed bytes.

If interrupted after mutation starts, `local-state/storage-cleanup/pending.json`
blocks further collection. It identifies the action, original path, quarantine
and saved snapshot. Before the first unlink, ordinary failures restore the
original name. After partial removal, the incomplete cache stays quarantined for
review; the collector never restores a partial generation as a usable cache or
blindly repeats an interrupted action. Keep that record until the original and
quarantine state has been reconciled.

## Verification and unattended use

```sh
zig build test-storage-cleanup
zig build test-storage-cleanup -Doptimize=ReleaseFast
```

Tests use isolated directories, including real file descriptors, aliases,
symlinks, changed files, manifest/hold checks, source mismatches, accepted and
failed release records, incomplete trace audits and directory permissions.
Guarded reads bind parsed controls to their exact bytes and identity, including
when a report is atomically replaced. Previous numbered retirement records pin
their retained evidence in later runs. CLI
checks exercise the shared lease, an interrupted operation and empty apply.
They do not remove project artifacts.

For unattended execution, call `tools/clean-storage --apply` from the existing
job runner after completed builds, with producers using the lease and holds
above. A missing dependency, invalid policy, changed evidence or interrupted
operation produces a nonzero exit and a report. This change installs no timer
or background process.
