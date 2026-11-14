# Automatic project storage cleanup

For each new development cycle, follow the
[storage contract](development_storage.md): classify outputs before execution,
name retained consumers and close temporary pipelines at handoff. Managed
launchers implement the workspace lifecycle; a bare reader lock does not.

New checked commands, real-program validations, execution-breadth controls,
upstream behavior and whole-compiler diagnostics separate their work files from
maintained evidence:

| Location | Contents and lifetime |
| --- | --- |
| `local-state/validations/SUITE/BATCH/RUN/` | Reports, command records, logs, generated test sources, captured inputs, profiles and raw traces. |
| `local-state/tmp/validations/SUITE/BATCH/RUN/.workspaces/KEY/` | Private caches, generated assembly, objects, capture helpers and executables. A fresh directory owned by one producer. |
| `RUN/KEY.storage-layout.json` | The exact mapping, producer state and hashes of the terminal result and diagnostic records. Retained after collection. |
| `local-state/artifacts/` | Shared immutable inputs and explicitly maintained objects. |

The collector's own build caches and staging executable also live under
`local-state/tmp/storage-cleanup-build/`; its installed executable, locks and
cleanup records remain under `local-state/storage-cleanup/`. Its build lock
serializes access to that reusable cache.

The converted tools select this layout automatically for output roots governed by
the project policy under `local-state/validations/`. Existing mixed runs and
standalone outputs keep their original paths and retention rules. There is no
bulk move of historical files or rewrite of current manifests.

For a sibling source checkout, use `tools/run-validation --project-root SOURCE
--storage-root OWNER ...`. The owner must contain the project storage policy,
collector, `.zigversion` and `src/main.zig` project markers.
`ZLLVM_PROJECT_ROOT` remains the source and command working directory;
`ZLLVM_STORAGE_ROOT` selects the evidence, workspace, lease and job-record owner.
The launcher requires managed output under the owner's
`local-state/validations/SUITE/BATCH/RUN` and rejects a silent fallback into mixed
storage. Child tools inherit this requirement. External source paths in job
records describe the command identity and never extend collection scope.
See [the launcher example](validation_tools.md#launch-current-tools-with-another-source-checkout)
for relative-path rules. Existing direct tool invocations retain their optional
layout unless they set `ZLLVM_REQUIRE_MANAGED_STORAGE=1`.

For direct collector invocations, an explicit `ZLLVM_PROJECT_ROOT` selects the
project/storage owner exactly. The collector rejects `ExplicitStorageRootMismatch`
if ordinary project discovery would select a parent directory. This applies to
native invocations as well as the launcher.

`run_checked` gives commands `ZLLVM_RUN_ROOT` for maintained evidence,
`ZLLVM_TEMP_ROOT` for temporary products and defaults `TMPDIR`,
`ZIG_LOCAL_CACHE_DIR` and `ZIG_GLOBAL_CACHE_DIR` to that workspace. Explicit cache
environment variables and command-line paths remain caller-owned overrides.
Commands can put additional ordinary build products in `$ZLLVM_TEMP_ROOT`;
reports, unique inputs and diagnostics belong in the supplied output root.
The terminal receipt's `storage` field records both roots, the layout path,
lifetime and environment overrides owned by other callers. Command-line cache
overrides remain visible in the recorded argv and need their own declared owner.
For example:

```sh
tools/run-validation \
  --output-root local-state/validations/example/batch-01/unit test \
  --command zig build test-unit
```

Custom scripts use this same `--command` entry point. Pass `--retain-products`
before `--output-root` when later comparison, fault or profiling consumers need
the checked command's workspace. Its successful terminal result retains a
`pipeline` workspace until `release-workspace --layout ... --reason ...` closes
that use. Direct `run_checked` supports the same flag and rejects it for
unmanaged output roots. Nested tools keep their own lifetime decisions.

A passed report or successful completed checked command releases its workspace
for the normal collector. Failed or interrupted runs retain their scratch for
investigation. Holds on either the maintained run or temporary tree protect it;
checksum pins and active consumers still apply. The collector verifies the
whole tree, refuses external hard links, symlinks and mounted trees, and uses its
existing quarantine journal before removing exact inventoried entries. A raw
`profile.events.jsonl` accidentally placed in scratch blocks collection. An
unknown folder under `local-state/tmp` is never automatically disposable.

The standalone producers publish their result for the next `clean-storage
--minimal --apply`; `run_checked` also attempts that collection on exit. A parent
job or shared lease can defer it. Compiler installations prepared for later
validation remain live dependencies until the pipeline owner releases them;
this layout does not infer that build completion closes downstream consumers.

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
limit to 16,384, while retaining the policy's byte limit and the applicable
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
The wrapper replaces its process image after the command exits, so the old job
arguments cannot falsely hold its completed output. No timer is installed.

`tools/run_checked.zig` now uses this lifecycle automatically when it finds the
project storage policy. It holds a shared lease during execution and records a
job-owned hold in `local-state/storage-cleanup/jobs/`. The hold closes only when
the same job has a hash-bound terminal receipt. The next collector discovers its
private caches and verified generated assembly/capture helpers. Failed tests
retain their diagnostic log and exit status; cleanup failure is reported as
deferred and does not alter the test outcome. Launch or supervision failures
without a terminal child result keep the hold for investigation.

Job holds and manual `holds.json` entries are independent. A finished job cannot
expire another investigation's hold. Queued work must still be declared before
it starts. A surviving supervisor or another reader can defer collection until
a later pass. Compiler builds intended for subsequent validation keep their
installed output until the pipeline owner publishes a release.

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

For generated assembly whose empty command logs were already removed, policy can
name hash-bound `retired_empty_log_records`. The collector requires a completed
ledger, successful preservation checks, its unchanged approved audit, and an
applied action for each exact log path with size/allocation zero and the empty
SHA-256. Missing or nonempty diagnostics without that proof remain blockers.

An individually reviewed old milestone can be transitioned without retiring its
whole manifest:

```sh
tools/clean-storage prepare-pins --requests REQUESTS.json --review REPORT.json \
  --manifests REVIEWED_MANIFESTS.json
```

The review file uses `schema:"zllvm-reviewed-pin-manifests-v1"`, a `reason`, and
`manifests:[{"path":"...","sha256":"..."}]`. Only exact artifact references
already qualified in the request review are transitioned. Current manifests are
rejected even if explicitly listed. All other references remain effective.

Whole-compiler IR captures now use the artifact store's immutable `linkInput`
API. Repeated content shares a read-only object; `get` still supplies an
independent copy for consumers that need writable content. Object-store GC keeps
objects with installed aliases, even without a manifest. Concurrent producers
serialize publication through the store lock.

Existing duplicate IR can be migrated through a reviewed plan:

```sh
tools/clean-storage share-inputs --inputs INPUTS.json
tools/clean-storage share-inputs --inputs INPUTS.json --apply
```

The plan uses `schema:"zllvm-shared-inputs-v1"` and
`inputs:[{"sha256":"...","paths":["local-state/validations/.../input.ll"]}]`.
List every name of each original inode. The collector checks content, ownership,
complete aliases, current holds and consumers. It atomically replaces each name
with a read-only store alias while retaining temporary rollback names. It checks
the controls again before unlinking the old data. A new hold rolls back the group;
an interruption leaves `pending.json` for recovery. Current checksum contracts
are verified before and after migration. The report separates retired allocation
from newly created store allocation, so only their difference is net reclamation.
Original filenames and content hashes remain available. Arbitrary mixed run
directories are never removed by this operation.

Capture helpers shared across completed runs require every name in the request
list. After `prepare-generated`, use `--complete-capture-aliases` during both
review and apply. Every owner must pass the generated-helper proof, every alias
must be present, and a pin or hold on one name protects the whole inode. Unknown
aliases block removal. The collector quarantines the complete group, refreshes
controls, and counts allocation only when the final link is removed. The flag
applies only to `capture-zllvm`, never arbitrary linked binaries or caches.

## What is automatic

| Category | Required evidence |
| --- | --- |
| Completed private compiler caches | A passed isolated compiler `report.json` and completed commands whose cache arguments name direct children of that run. The default project policy does not require source/configuration reconstruction; `cache_evidence:"replay"` optionally adds it. |
| Released private test caches | An explicit disposable release bound to a terminal `run_checked` receipt, its working directory and exact cache arguments. The producer log remains hash-bound outside the cache, including for failed/canceled tests. |
| Released comparison caches | A passed `report.json`, its hash-bound sibling `commands.json`, explicit private cache arguments and closed compiler commands. Every using command's diagnostics remain outside the released caches. |
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

Completed test products can be prepared with
`prepare-outputs --reports FILE --reason TEXT`, where FILE lists owner
`report.json` paths, one per line. Each passed report must have a sibling
`commands.json`. Direct compiler `-o` / `-femit-bin=` arguments or the recorded
compiler's `--emit=obj` stdout establish the exact output; direct compiler copies
also require the report's compiler hash. Supported products include `local`,
`reference`, `z_llvm`, other extensionless products, objects, archives and `.exe`
files. The collector keeps the
report, commands and diagnostics, and checks compiled-file magic. Shell commands,
implicit build destinations and file names alone cannot authorize collection.

`prepare-closed-outputs --reports FILE --reason TEXT` explicitly includes
ordinary products from completed commands with nonzero exit codes, including
negative tests and failed builds. Owners must be passed or failed; every command
that names a selected product must have a completed outcome and recorded exit
codes. Running, timed-out or canceled commands remain ineligible. This mode
preserves reports and diagnostics and uses the same compiled-byte, hold, pin,
alias and current-consumer checks. The default `prepare-outputs` still requires
successful commands and passed owners.

The closed-output mode also recognizes one partial-output layout: an
`execution-breadth-controls-v1/v2` run's `wrong-symbol` native-link control.
It requires the recorded failed `zig build-exe -fno-lld -fno-lto` command,
retained undefined-symbol diagnostic, zeroed ELF header and consistent ELF64
program-header/table mapping. Empty files, scripts, unrelated data and other
unfinished binary formats remain ineligible.

`prepare-observed-compilers --reports FILE --reason TEXT` handles older
`z_llvm` binaries that have no canonical `.build.json` receipt. It requires a
passed `native-canary-v1` report with the exact current compiler SHA-256 and a
saved, successful direct `z_llvm --emit=obj` invocation in sibling
`commands.json`. Legacy commands may lack `outcome` and `actual_returncode`;
their recorded return code must be zero, and any present completion fields must
also show success. Compiler and report must belong to the same validation tree.
The report, commands and diagnostics remain; object stdout is a separate
temporary product. Existing build receipts, mismatched hashes, unfinished runs,
holds, pins and incomplete alias groups still prevent this retirement. This
mode does not recreate an old build or require new source/configuration archives.

The generated-output adapter also accepts older capture-helper runs without a
batch directory. Such a release must name only the owner's direct `capture-zllvm`
file; a passed real-program comparison and matching runner-provenance hash are
still required. This does not admit arbitrary outputs from a shallow directory.

`prepare-receipts --receipts PLAN --reason TEXT` supports standalone checked-run
receipts with explicit compiler output arguments. The plan has schema
`zllvm-command-output-plan-v1` and a `receipts` array of `{producer,
working_directory, legacy_working_directory_review?}`. The working directory is
`.` for this checkout or an owned validation subdirectory. Modern recorded `cwd`
must agree; an older receipt without it requires an explicit review of the
original runner convention. A successful terminal result, ordered timestamps,
combined diagnostic log and exact output binding are mandatory. A plan cannot
override a conflicting recorded directory or infer an implicit build product.

Passed `whole-compiler-diagnostic-v1` reports can bind their named `candidate` or
`rebuilt_candidate` to a successful `zig build --prefix` command and the report's
exact binary hash. The recorded `/usr/bin/time -f ... -o ... --` wrapper and
the fixed `/usr/bin/taskset --cpu-list 0` child wrapper are supported, including
that exact affinity wrapper inside `time`. Other affinity options and process-ID
forms are rejected. Help invocations, arbitrary wrappers and unnamed install
outputs do not establish ownership. Reports may also identify their
compiler/emitter in the `toolchain` object.

`prepare-aliases --requests FILE --reason TEXT` searches the validation tree for
every name of the requested compiled-output inodes. It preserves the original
requests and adds independently verified command owners or capture-helper
owners for newly found names. Its review records rejected or unbound owners.
It does not extend authority to aliases outside the validation tree; the full
link-count check below still prevents collection of an incomplete group.

Use `--complete-artifact-aliases --requests FILE` for an explicitly reviewed
complete group of compiled outputs or audited raw traces. Every name needs its
own qualified request and evidence. A missing name, unqualified audit, current
pin, retained dependency, hold or active owner protects the physical file.
Allocation is counted once, on the last unlink. `--complete-capture-aliases`
remains the narrower option for capture helpers.

Minimal mode admits up to 16,384 candidates per pass, within the unchanged byte
budget. Qualified files are collected in batches bounded by that budget and a
separate cap of 1024 names, keeping each alias group indivisible. The durable
`file-batch` journal records every original/quarantine name, hash and metadata.
The collector rechecks pins, holds, consumers and retained evidence after
quarantining all members. Before the first unlink a failure restores every
name; an interrupted or partially unlinked batch leaves the journal for review.
Evidence is verified again before clearing the journal. Private caches and
completed managed workspaces use a
separate `cache-batch` transaction of at most 128 roots, normally at most 1 GiB
and the configured file-count budget; a larger single cache retains the existing
single-root allowance. Every snapshot and allocation is checked before any
rename. All roots are quarantined before refreshing pins, holds, consumers and
evidence; failure before the first unlink restores every name. Exact file and
directory checks continue throughout removal. Workspace layout, result and
diagnostic bindings remain mandatory, as do protection of both evidence and
temporary roots and rejection of raw event streams or external hardlinks.
Empty workspaces use the same bounded transaction, avoiding a full retention
scan for each empty directory.

`narrow-cache-holds --roots FILE --reason TEXT` reviews explicitly selected
run-level manual holds, one path per line. Each run must have a passed producer
whose completed commands own its direct private caches. The proposed holds
retain every existing non-cache child and every unselected hold. Active job
holds, protected roots and a held release refuse the change. Add `--apply` to
write a before/after receipt and atomically narrow those holds after rechecking
the evidence, original holds, directory membership and consumers. This command
does not delete payloads. A subsequent ordinary collection still checks all
independent holds, current pins and live uses.

`retire-held-products --review PLAN --minimal` reviews explicitly selected
ordinary compiler files and old shared Zig caches. Add `--apply` to collect the
eligible products. Its `zllvm-held-products-review-v1` plan binds the original
hold document, a passed checkpoint, retained acceptance evidence and exact
product paths by SHA-256. Compiler entries name their original build reports;
shared-cache entries name closed checked-run receipts selecting that cache with
cache flags, leading `env` assignments or a cached executable. Cache layout,
ownership, complete file snapshots and hashes must also pass verification.

An entry with `release_manual_hold: false` reviews an unheld product without
granting any manual-hold exception. An existing hold therefore still blocks it.
Legacy readiness caches may supply `readiness_launcher` with hash-bound `script`
and `source_snapshot` evidence, plus `compiler`, `zig_source_directory` and
`zig_emitter` paths. The collector accepts only the exact saved 16-line readiness
launcher template and its successful, ordered `bash SCRIPT` completion receipt;
it does not interpret arbitrary shell code. Launcher and snapshot records remain.

This command can except the selected **exact manual holds** for this invocation
and the generic `local-state/caches` policy parent for a reviewed shared cache.
Other manual ancestors or descendants, job holds, specific policy protections,
current integrity contracts, pins and active readers still prevent removal.
Changing the reviewed hold file or evidence invalidates the operation. Ordinary
collection never gets these exceptions. Existing file/cache transactions perform
the removal; raw event traces, special entries and aliased cache files are
rejected. The command removes a manual hold only after its product was actually
collected, saving the before/after hold documents. Blocked products keep their
holds and all existing build/results records remain.

A review is a deliberate lifecycle decision after checking current acceptance,
queued work and all known users. A cache's age or an idle process list alone is
insufficient. The collector does not infer this decision from historical names.

For older whole-compiler runs without a separate checked-run receipt, the trace
auditor also accepts the original passed `whole-compiler-diagnostic-v1` report
as its producer. It requires completed build/source verification, a successful
recorded build bound to that run's install prefix, and exactly one embedded
capture matching the backend report's input and trace identities. Full stream,
compiler, build, source and retirement checks still apply.

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

### Private caches recorded in command ledgers

`prepare-command-caches --reports FILE --reason TEXT` reads a newline-separated
list of project-relative `report.json` paths. It prepares disposable requests
and `command-cache-review.json`, including reasons for rejected owners. Review
and apply its `requests.json` through the normal guarded collector.

The parent report must pass. Its sibling `commands.json` must explicitly name
each cache with an absolute `--cache-dir` or `--global-cache-dir` argument.
Supported commands directly invoke Zig, or the report's recorded frontend or
emitter, with `build`, `test`, `build-exe`, `build-obj`, `build-lib`, `cc` or `c++`.
Every command using an owned cache must have a completed outcome and matching
recorded/actual return codes. Expected negative compile/link cases are allowed
inside a passed comparison; their original statuses and diagnostics remain.

Only recognized cache names directly under the run or one standard optimization
mode qualify. These include `frontend-cache`, `reference-cache`,
`candidate-cache`, `reference-link-cache`, `candidate-link-cache` and the usual
local/global Zig cache names. Default caches, shared locations, arbitrary nested
directories and shell commands are not inferred. Every using command's stdout
and stderr must remain outside every released cache; an already retired empty
log needs its existing verified retirement record. Source and old compiler
preservation are not prerequisites. Current pins, holds, consumers, private
inode ownership and fresh per-file snapshots still decide actual collection.

### Generated integrated-test outputs

`prepare-generated --paths FILE --reason TEXT` reads a newline-separated list
of explicit project-relative paths and writes requests plus
`generated-review.json`. Review the resulting `requests.json`, then use
`--apply --requests` for qualified files. Preparation never removes payloads.

Two reviewed families are supported:

- `linked-harness.s` under an `execution-breadth-controls` run. A passed
  `execution-breadth-controls-v2` row must bind the source, object and two
  consecutive command indexes. The successful compiler command must name that
  exact assembly output, and the successful assembler command must consume it.
- `capture-zllvm` beside a passed `real-program-v1` report. Every selected mode
  must have matched, and the executable hash must equal the report's validation
  runner provenance hash. `program.zig` creates this helper by copying its own
  executable.

Both use disposable output retention. Reports, commands and existing recorded
diagnostics remain. Source or build-configuration archives are not required.
This adapter does not admit arbitrary assembly sources or extensionless test
executables; the command-output adapter above handles named test products.
Current pins, holds, metadata/hashes, hardlinks and active consumers still
protect files; an active parent integrated job protects its finished subtests.
Files with multiple hardlinks remain held by the single-file collector.

Eligible named outputs use the bounded file batches described above. The
collector journals every original path, hash and metadata,
quarantines only those files, then refreshes holds, pins and consumers before
unlinking. A failure before unlinking restores every original name; an
interruption or partial removal leaves a pending journal that blocks another
cleanup. Each removed file still receives its own completed retirement record.
Mixed run directories, reports, inputs and source files are not removed.

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

### Auditing live traces

Start from paths that exist now. Historical audit catalogs describe an earlier
state and may include already retired payloads; reconcile them with completed
retirement records before estimating reclaim.

`zig build audit-native-events -- --plan PLAN.json` reads an explicit list of
live streams and creates compact `zllvm-native-event-audit-v1` results. The plan
uses schema `zllvm-native-event-audit-plan-v1`; each `traces` entry contains a
`path` and `producer`, `top_report`, and `backend_report` path/SHA-256 pairs.
All paths are project-relative. Producer receipts must be completed
`run_checked` jobs whose `--output-root` names the report's run directory.

The auditor holds the shared cleanup lease, checks every event's order and
scope balance, hashes the entire stream, and compares its final counters and
failed-function names with the backend report. It verifies input bytes and
rechecks file identities and report hashes after reading. Failed compilations
remain failed outcomes. Truncation, mismatched hashes, unrelated producers and
changed controls cannot produce a verified audit. Results preserve failure
details, event offsets, source snapshots and the auditor's Git revision.
It does not delete files or replace the collector's separate source/build,
retired-compiler, alias, hold and pin checks. Unrecognized producer layouts
remain explicit review cases.

Run `zig build test-native-event-audit` and the same command with
`-Doptimize=ReleaseFast` to qualify the stream state machine and report binding.

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
CLI qualification requires `jqz` and `zigrep` on PATH; `JQZ` and `ZIGREP` can
select explicit executable paths.
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

## Reviewed workspace release

Fresh C/native, input-program and retained integrated runs use the same layout
as real-program and whole-compiler validation. Generated objects, executable
files, shared libraries and binary stdout go into the temporary tree. Reports,
commands, textual logs, generated inputs and profiles stay in the evidence tree.
Native fault checks and comparisons resolve old mixed runs and new mapped
products. Run faults in the native command with `--fault-count`. For a later
comparison or fault check, use `--retain-products` on `run_native_canary` or
`run_upstream_c_program`, then explicitly release that workspace afterward.
Queued holds on the input run also protect its products.

Fresh `build_validation_compiler` installations use a `pipeline` lifetime. Their
stable `MODE/bin/z_llvm` alias points to the temporary executable; the adjacent
build receipt and terminal report remain maintained. Successful builds do not
release the compiler. Rebuilding a retained installation is supported under its
build lock; a failed or released installation requires a fresh output root.
Existing mixed installations are not moved.

After reviewing a resolved failure or finishing all downstream compiler work:

```sh
tools/clean-storage release-workspace \
  --layout local-state/validations/PROJECT/BATCH/RUN/validation.storage-layout.json \
  --reason 'Failure resolved; retained diagnostics reviewed; no further consumers'
tools/clean-storage --minimal
tools/clean-storage --minimal --apply
```

For compiler installations, select `MODE/compiler.storage-layout.json` instead.
Publication creates a separate `*.workspace-release.json` authorization; it
does not change the original result or delete the products. The normal collector
rechecks its layout/result hashes, diagnostics, holds, current pins and readers.
An unfinished producer cannot be released this way. A raw trace accidentally
written into scratch still blocks whole-workspace deletion. Existing explicit
shared-cache overrides remain caller-owned and outside that workspace release.
