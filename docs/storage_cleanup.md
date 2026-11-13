# Automatic project storage cleanup

Run the collector to review completed private compiler caches and explicitly
released artifacts. Ordinary old compiler/test binaries and objects are temporary;
their deletion does not require reconstructing source or build configuration.
Current uses, adopted baselines, queued holds and investigations requiring the
exact executable remain protected. Apply mode performs the review and removal in one
invocation, without interactive approval:

```sh
tools/clean-storage
tools/clean-storage --apply
tools/clean-storage --minimal --apply
tools/clean-storage inventory
```

The first command writes a JSON report with eligible paths, allocated file bytes
and reasons for keeping candidates. The second discovers and checks everything
again; it does not trust an old inventory. Both print the report location under
`local-state/retirements/automatic-storage-cleanup/`. Repeating apply is safe:
already removed paths are absent from the next discovery.

The project policy now uses minimal retention by default. Use `--minimal --apply`
to request that mode explicitly even with a custom policy. It removes the optional
waiting period and raises the candidate
limit to 1,024, while retaining the policy's byte limit and the applicable
artifact-hash, pin, active-consumer and mutation checks. The project uses
`cache_evidence:"closed_producer"`: a completed private cache needs its closed
producer and exact command ownership, without reconstructing old sources or
keeping its compiler. Custom policies can use `cache_evidence:"replay"` for the
earlier stronger reproduction contract. This is a minimum under verified rules, not a claim that every
remaining byte is necessary: unsupported evidence formats remain visible for
investigation.

For ongoing maintenance, run jobs through:

```sh
tools/clean-storage maintain -- YOUR_BUILD_COMMAND ARGUMENTS
```

This holds the shared storage lease while the job runs, releases it, and runs a
fresh minimal apply afterward, including when the job fails. Failed jobs keep
their original exit status and diagnostics. If the job succeeds but cleanup
fails or is busy, the wrapper returns the cleanup error. Background descendants
that still hold the lease prevent collection. Queued jobs still need holds.
This command is the integration point for the job runner; no timer is installed.

When a successful producer also closes an obsolete run, it can write a release
request and publish it as part of the same maintenance workflow:

```sh
tools/clean-storage maintain --release-request REQUEST.json -- YOUR_JOB ARGUMENTS
tools/clean-storage release-build --build OLD_BUILD.json \
  --reason 'Completed temporary compiler is no longer used'
```

`maintain` publishes the request only when the job exits successfully. A failed
job retains its original exit code and does not publish its request. Publication
failure prevents that invocation's collection and returns an error. The shared
lease covers the producer; the collector takes the exclusive lease afterward.
Current baselines remain pinned until their consumers advance. The owner
identifies which completed builds are disposable; age alone is insufficient.

Without `--successor`, `release-build` uses `state:"disposable"`: only closed
producer evidence, exact output bytes, current consumers and pins are required.
It neither reads nor archives the build's sources or toolchain. Existing producer
receipts and deletion hashes remain as small accounting records. Supplying
`--successor FILE` explicitly selects the optional stronger `superseded` contract
with complete rebuild evidence and a passed successor. `release --request FILE` accepts
the full release format below for objects, logs and traces as well. Publishing
never removes the payload or overwrites an existing release.

The shell entry point builds a reusable **ReleaseFast** native Zig helper in
`local-state/storage-cleanup/`. It uses the project's pinned Zig version,
`zigrep` for file discovery, the unchanged `zig-file-audit` library for guarded
metadata and hashing, and standard Linux tools (`lsof`, `ps`, `sha256sum`, `git`,
`gzip`, `flock`). Set `ZIG` or `ZIGREP` to explicit binary paths if needed. No
Python or Node runtime is used. `jqz` can inspect the resulting reports:

```sh
jqz '{mode,retention,ready,skipped,removed,reclaimed_allocated_file_bytes,held_allocated_file_bytes}' REPORT.json
jqz '.actions | each | where(.status == "skipped") | {path,reason}' REPORT.json
```

## What is automatic

| Category | Required evidence |
| --- | --- |
| Completed private compiler caches | A passed isolated compiler `report.json` and completed commands whose cache arguments name direct children of that run. The default project policy does not require source/configuration reconstruction; `cache_evidence:"replay"` optionally adds it. |
| Released private test caches | An explicit disposable release bound to a terminal `run_checked` receipt, its working directory and exact cache arguments. The producer log remains hash-bound outside the cache, including for failed/canceled tests. |
| Released raw event streams | An explicit owner release, a complete semantic audit bound to the exact raw SHA-256, producer/reports/input hashes, the original compiler or its verified guarded retirement, complete build/source evidence, and the auditor sources. An audited failure retains its original outcome and diagnostics; it does not require a passed successor. |
| Superseded executable/object files | An explicit release record, accepted successor, complete source/build/input/result evidence and matching bytes. Only the supported output names and ELF/archive formats qualify. |
| Disposable executable/object files | An explicit `disposable` release, a closed producer in the owning run, and exact output hashes. No source/configuration reconstruction or accepted successor is required. Only compiled ELF/archive output can qualify. |
| Obsolete logs | An explicit release record, accepted successor, complete build/source/input/result evidence, and retained diagnostics for a failed producer. |

The cache report adapter matches the isolated prototype build reports used by
the current compiler work. For releases that require replay, the collector also supports standalone
`zllvm-compiler-build-v1` receipts. This adapter checks the successful command,
output prefix, compiler hash, toolchain binary and complete library identity.
Every recorded source hash must match the receipt's Git revision or an explicit
source-reconstruction ledger's Git blob or saved override. The ledger's
`verified` flag is never sufficient: the actual bytes are checked. Used commits
are pinned with local Git refs, and used overrides and ledgers remain retained.
The live checkout may have advanced. Isolated prototype reports used as replay
proof still require their recorded source files unchanged. Disposable outputs
do not use this adapter, so an old source mismatch does not retain a temporary binary.
Other report formats and shared caches require another adapter or explicit review.
The collector does not infer that a failed parent succeeded because a child
command passed. It does not infer diagnostic redundancy from version numbers,
equal sizes, elapsed time, or an old document reference.

Only owned paths below `local-state/validations/` can be removed. Sources, IR,
shared AIR, input directories, worktrees and artifact-store objects stay outside
the rules. Use the artifact store's collector for unreachable store objects.
Hardlink aliases, symlinks, special files, foreign owners, mounted subtrees,
frozen cache directories and changed metadata/content prevent admission.

The project policy allows **zero idle hours**, at most **1,024 candidates** and
**32 GiB of allocated file bytes per invocation**. Age alone never makes a file
eligible. A custom policy can add a delay or smaller batch size; `--minimal`
overrides only those first two limits, and reports its effective policy explicitly.
The byte limit still bounds each pass; another fresh pass collects any remaining
eligible candidates after that cap is reached.

`release-trace` translates the existing `zllvm-native-event-audit-v1` format into
a qualified owner release. Use repeated `--reconstruction FILE` arguments for
canonical builds with historical source overrides. The supported ledger format
has a `sources` array containing `sha256`, `revision`, `path` and/or `saved`.
Unresolved entries remain blockers. An absent original compiler needs a verified
completed retirement record, supplied with `--compiler-retirement RECORD.json`;
absence alone does not qualify. This preserves its recorded identity without
rebuilding an obsolete executable. Producer adoption of the release commands is
explicit; ordinary build invocations do not automatically declare prior runs
obsolete. The
[follow-up plan](plans/2026-11-13-storage-cleanup-followups.md) records those gaps.

## Reviewing historical batches

Prepare explicit requests from a newline-delimited list of completed build
reports, then review them. Preparation writes only small request files under
the new cleanup output directory:

```sh
tools/clean-storage prepare-builds --builds BUILDS.txt \
  --reason 'Completed temporary compilers are no longer used'
tools/clean-storage --requests PREPARATION/requests.json
tools/clean-storage prepare-pins --requests PREPARATION/requests.json \
  --review REVIEW/report.json
tools/clean-storage --requests PIN_PREPARATION/requests.json
tools/clean-storage --apply --requests PIN_PREPARATION/requests.json
```

Each command prints its actual output location. Request lists bind every release
file by SHA-256. Review and apply both rediscover state and verify all evidence.
`prepare-pins` handles only hash-bound references in completed retirement records
or checksum ledgers under `local-state/retirements/`, after a bound review has
qualified the candidate under its selected retention contract. It does not transition current
manifests, unfinished records, bare fingerprints, mismatched hashes, or other
validation-suite pins. The resulting exact transitions are reviewable; nothing
is removed during preparation. `pin-references.json` identifies matching pins.

Release records may contain `retired_pins`: each entry names the original
`manifest` path/hash, the exact `reference` string in it, the artifact `target`
path/hash, and a `reason`. Only that reference to that artifact is exempted.
Other files in the manifest and references from other manifests remain protected.
Original manifests stay unchanged. Current manifests are pins regardless of
their filename or location. Current holds and retained dependencies always win,
including dependencies declared by a release that cannot itself qualify.

### Private native-test caches

`prepare-caches --caches PLAN.json --reason TEXT` prepares hash-bound requests
for explicitly reviewed completed jobs. Review and apply the resulting
`requests.json` as above. Preparation also writes `cache-plan-review.json` with
the reason for each rejected entry; it never removes payloads. For example:

```json
{
  "schema": "zllvm-private-cache-plan-v1",
  "runs": [{
    "producer": "local-state/validations/example/unit/evidence/test.json",
    "run_root": "local-state/validations/example/unit",
    "working_directory": "local-state/validations/example/unit"
  }]
}
```

The receipt must record `status:"finished"`, a completed or canceled outcome,
an actual return code and ordered start/finish timestamps. Its `cwd` must match
the declared directory. New `run_checked` receipts record the actual child cwd.
Old receipts lacking that field require a nonempty
`legacy_working_directory_review` in the plan, documenting the operator's review
of the copied project, launch evidence and cache layout. This is an explicit
ownership declaration, not inferred historical cwd evidence. The copied project
must also contain an owned regular `.zigversion` and an owned `src` directory
or symlink. The source marker is inspected without following it; older test
projects intentionally link to a separate research tree. That tree is neither
reconstructed nor changed by cache retirement.

Supported commands directly invoke Zig `test`, `build`, `build-exe`, `build-lib`
or `build-obj`, optionally through `env`. Cache paths must appear in
`--cache-dir`, `--global-cache-dir`, `ZIG_LOCAL_CACHE_DIR` or
`ZIG_GLOBAL_CACHE_DIR`. Only recognized private cache names directly under the
working directory, its `evidence/`, or its `local-state/` qualify. Shared caches,
default paths absent from argv, shell-wrapped commands and arbitrary source
subdirectories remain unsupported. A failed test does not become a successful
result when its disposable cache is removed.

Private-cache artifacts use `kind:"private_cache"` and omit the single-file
`sha256`. Review snapshots every member's metadata and SHA-256; the same guarded
whole-cache removal checks used for compiler caches apply. Source/configuration
reconstruction is not required. Logs, receipts, current pins, queued holds,
active consumers and retained dependencies remain protected.

### Traces whose original compiler was retired

`prepare-traces --traces PLAN.json --reason TEXT` prepares requests for an
explicit trace list. Review and apply the resulting `requests.json` as above.
For example:

```json
{
  "schema": "zllvm-trace-retirement-plan-v1",
  "traces": [{
    "audit": "local-state/retirements/AUDIT/results/N.json",
    "build": "local-state/validations/SUITE/BATCH/COMPILER/report.json",
    "compiler_retirement": "local-state/retirements/automatic-storage-cleanup/RUN/record-N.json"
  }]
}
```

Omit `compiler_retirement` when the original compiler remains available. An
entry can also supply `source_reconstructions` as path/hash evidence pairs.
Preparation writes small request files; the subsequent review qualifies the
full audit, evidence, pins and consumers. A prepared request is not permission
to skip those checks.

A retired compiler must have a completed guarded `build_output` removal with
matching identity and reclaimed allocation, a hash-bound disposable owner
request, and the unchanged original build receipt retained by that record.
The original path must remain absent. The build, audited run and retirement
must all name the same compiler path and SHA-256. The collector retains this
proof chain and rechecks it before and after mutation. A changed or incomplete
record, unbound build, reappeared executable or changed source prevents removal.
This option applies only to audited raw traces; it does not excuse missing
source, input, audit, toolchain or failure evidence.

## Accounting for the remaining tree

`tools/clean-storage inventory` runs a review and writes `inventory.json`. It
observes every accessible same-filesystem entry and counts each device/inode
allocation once, including hardlink aliases. Buckets identify run, file family,
allocated bytes and a retention reason. A bounded list identifies the 64 largest
files. It writes no full payload copy or million-row archive.

The three dispositions are `required_by_current_contract`, `eligible`, and
`unresolved`. The first means an explicit current manifest, queued hold, or
verified reproduction dependency; it is not proof that the contract itself
cannot be reduced. Generic protected roots and historical references alone do
not establish necessity. Across hardlink aliases, required takes precedence over
eligible, which takes precedence over unresolved. Concurrent changes and skipped
foreign devices are reported; the inventory is observational, not a deletion list.
Use `inventory --requests FILE` to account for a prepared historical batch too.

## Current work and retention pins

[storage_cleanup_policy.json](storage_cleanup_policy.json) records the five
current integrity manifests and known protected directories. Their complete
hash checks must pass before any removal. A missing or changed required control
blocks apply.
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
an accepted successor makes selected outputs obsolete, or a complete trace
audit and preserved replay evidence replace the raw event detail. This is an explicit
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

The successor requirement above applies to `state:"superseded"`. For raw traces,
the owner can instead publish a verified `state:"audited"` release:

```sh
tools/clean-storage release-trace \
  --audit local-state/retirements/AUDIT/results/N.json \
  --build local-state/validations/SUITE/BATCH/COMPILER/report.json \
  --reason 'Completed experiment: retain audit, failure details and replay evidence'
tools/clean-storage --minimal --apply
```

The publishing command verifies the full audit, complete build sources,
compiler, input/report bindings, pins, holds and consumers before creating a
release. It retains all other regular files in the original run, the producer's
external logs when declared, and the build logs/toolchain. It neither removes
the raw trace nor overwrites an existing owner decision. Actual cleanup repeats
the checks. Audited releases may contain **only raw traces**. Disposable build
outputs use their separate completed-producer contract; superseded logs require
an accepted successor. Failed producer outcomes stay failed.

For `raw_trace`, the artifact name must be `profile.events.jsonl`, with an `audit`
path and a retained `audit` role. Keep the original executable in a `compiler`
row, or supply the verified `compiler_retirement` evidence described above.
The audit must use
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

The report includes measured held bytes, idle ages and unmeasured candidate
counts. `footprint-before.json` and, for apply, `footprint-after.json` show the
whole `local-state` allocation by top-level directory and distinguish protected
roots from unassessed storage. Those `du` observations include directories and
concurrent work; they are not deletion inventories or exact savings claims.
Unknown files are never silently counted as necessary. The effective policy
and each held candidate's specific reason remain in `report.json`.

For repeated pin checks, parsed manifests are reused only while their full
identity/metadata matches. Changed manifests abort the pass. Discovery still
finds new manifests before each mutation, and path/alias resolution is refreshed
each time, including previously missing parents. No persistent negative-path
cache can hide a newly created pin.

When no candidate passes provenance/ownership checks, the tool has nothing to
delete and skips the expensive pin-target and integrity-target scans. Required
control files must still exist and their own hashes are recorded. Such a report
explicitly has `current_integrity_verified:false`; it does not claim the target
hashes were checked. Every pass that can remove artifacts performs those checks
in full, including again after collection. Batch limits are applied after pin
checks, so pinned candidates do not prevent later eligible ones from being
collected.

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
checks exercise the shared lease, an interrupted operation, empty apply,
ordinary fresh-cache retention, a bad current manifest, actual minimal
collection, idempotence, maintenance after successful/failed jobs, and an
audited failure whose original compiler has already been retired.
They do not remove project artifacts.

For unattended execution, call `tools/clean-storage --apply` from the existing
job runner after completed builds, with producers using the lease and holds
above. A missing dependency, invalid policy, changed evidence or interrupted
operation produces a nonzero exit and a report. This change installs no timer
or background process.
