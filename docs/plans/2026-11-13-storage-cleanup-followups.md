# Complete the storage cleanup workflow

## Implementation follow-through

The next implementation pass connects completed producer jobs to collection,
refreshes the whole-tree inventory, and reduces repeated input storage. Work is
ordered as follows:

1. Remove the maintenance wrapper's stale command-line consumer; test terminal
   handoff, failure status, queued holds and concurrent readers. Add producer
   completion hooks with explicit job-owned holds. Manual investigation holds
   do not expire merely because they are old.
2. Accept hash-bound completed retirement records for missing empty command
   logs. Review and collect the 21 affected assembly outputs.
3. Refresh allocation and retention references. Review noncurrent milestone
   manifests individually; keep current acceptance contracts intact.
4. Provide immutable shared IR installation and guarded migration of existing
   duplicate names, preserving content and current checksums. Audit all aliases
   and consumers before changing any live input.
5. Qualify Debug and ReleaseFast, exercise installed tools, record actual
   reclamation, and retire this pass's temporary build products.

Shared helper inodes require a complete alias-group decision; partial unlinking
must not be reported as reclaimed physical storage.

### Implemented and qualified

- `run_checked` takes a storage lease, registers its own hold, and closes it
  against the terminal producer receipt. Collection starts after terminal exec,
  with producer descriptors closed and old job arguments gone. Failed test
  status and diagnostics survive collection or completion-bookkeeping failures.
  Storage admission time is excluded from command wall time. Existing manual
  and queued holds remain independent.
- Generated-output proof accepts explicitly approved, hash-bound retirement
  records for missing empty logs. Reviewed noncurrent manifests can release
  exact artifact references; a current manifest cannot be exempted.
- Whole-compiler IR capture publishes immutable content once and installs
  read-only aliases. Existing inputs can be migrated with complete alias,
  hash, hold and consumer checks, atomic name replacement and rollback. Store
  GC retains objects with installed aliases. Writable copies remain available.
- Complete `capture-zllvm` hardlink groups now have an explicit review/apply
  path. Every owner must qualify; one current pin or hold protects all aliases.
  Removal charges the physical allocation only on the final unlink.

Qualification: 106 collector tests pass in Debug and ReleaseFast; 11 artifact
store tests pass in both modes. The installed-utility CLI checks cover 23
collector scenarios and six producer/input scenarios, including a completion
write failure that preserves exit 7. The whole-compiler driver builds in Debug;
the artifact CLI and checked runner build in ReleaseFast. Formatting, shell
syntax and whitespace checks pass. No external library source was modified.

The fresh initial inventory observed **132.642 GiB**: 43.079 GiB covered by
current holds/contracts, 0.160 GiB eligible at that instant, and 89.403 GiB
unresolved. Holds are ownership decisions, not proof that every retained file
is intrinsically necessary. The compiler agent continues to create artifacts.

Completed live operations so far:

- 147 successful assembly intermediates removed: **1,423,613,952 allocated
  bytes**. This includes 21 files whose 84 empty logs had verified retirement
  records, and 126 files from six reviewed selection milestones. All five
  current integrity manifests passed afterward.
- Eight duplicate IR inodes, with 16 names, migrated to one shared object.
  Retired allocation: 3,549,069,312 bytes; new store allocation: 443,629,568 bytes;
  **net reclaimed: 3,105,439,744 bytes**. Three held inode groups with 52 names
  stay unchanged; the differently hashed self-rebuild input is excluded.
  Every filename and content hash remains available, and the five current
  integrity manifests passed after migration.

Evidence is under
[`local-state/storage-cleanup/lifecycle-implementation/`](../../local-state/storage-cleanup/lifecycle-implementation/).
The assembly completion is
`automatic-storage-cleanup/1794594163771306633-45615/report.json`; the input
migration is `1794594685164125839-56147/shared-input-review.json` beneath the
same retirement root. The collector's JSON reports retain exact identities,
hashes, transitions, checks and allocation accounting.

Status: minimal mode, audited traces, canonical build/source reconstruction,
exact historical pin transitions, staged batches, explicit private-test caches,
retired-compiler identity verification and full-tree allocation accounting
implemented. The execution and remaining evidence gaps are tracked in
[completed-run retention](2026-11-13-completed-run-retention.md) and the
[remaining-storage investigation](2026-11-13-remaining-storage-investigation.md).

The initial collector has guarded removal, pin checks and provenance validation,
but its first real apply run reclaimed zero bytes. Its source and tests belong
in Git; generated inventories, logs, binaries and local retirement records stay
under ignored `local-state/`.

## Findings from 2026-11-13

The default 24-hour idle rule held all 96 discovered private-cache roots. Their
cache/report changes were about 1–7 hours old when inspected. The day-long wait
was an implementation choice, not a condition required by the previous manual
cleanup workflow.

A review-only comparison disabled that delay and raised the candidate cap for
counting. All other source/build, hash, pin, consumer, link and mount checks
remained enabled:

- 94 of the original 96 candidates passed, totaling 3,996,217,344 allocated
  regular-file bytes (3.72 GiB).
- With four newer caches included, 98 of 100 passed, totaling 4,166,381,568 bytes
  (3.88 GiB). The first 64 ready candidates totaled about 2.53 GiB.
- Two caches for the v825 Debug build remained held: two of its 642 recorded
  source hashes disagreed with the source tree. Compiler and toolchain hashes
  matched. These integrity failures block a claim of preserved replay. Under
  the user's later disposable-build policy they do not, by themselves, require
  keeping a completed private cache.

The original cache roots occupied about 3.81 GiB including directory blocks,
only 2.54% of the contemporaneous 150.03-GiB `local-state` footprint. The rest
was outside this candidate set; the collector had not established whether that
storage was needed or safe to retire.

There were no `storage-release.json` records. Production tools do not yet write
them, and existing audit, reconstruction and owner decisions are not converted
into them. Requiring a distinct passed successor also excludes some previously
approved trace retirements that preserved failed outcomes, complete audits,
replay sources, inputs, commands and diagnostics.

## Required changes

Implemented in the minimal-retention follow-up:

- `--minimal` removes the optional cache delay and reviews up to 1,024 candidates,
  without relaxing source hashes, current pins, holds, consumers or mutation
  checks. The effective policy and remaining byte cap are recorded.
  The project policy adopts these settings as its default as well.
- `maintain -- COMMAND` holds the shared lease during a producer job, then runs
  a fresh minimal apply. Failed producer exit codes are preserved.
- `release-trace --audit FILE --build FILE --reason TEXT` consumes the existing
  complete native event audits, preserves all other run files and declared
  external producer logs, and verifies complete isolated build/source evidence
  before publishing an owner release. An audited failure needs no invented
  passed successor. The audited state authorizes only raw trace retirement.
- Held candidates are measured. Whole-storage before/after footprints explicitly
  show protected and unassessed storage instead of calling all remaining bytes
  useful. Candidate limits or unsupported formats remain visible.
- Cross-candidate retention checks normalize unique paths once. Pin refreshes
  reuse parsed, metadata-bound manifests, discover new files and re-resolve
  aliases each time; missing-parent caches and the bounded directory descriptor
  cache last only one refresh. A path index avoids comparing each reference
  against every candidate. Empty passes explicitly skip deletion-only target
  checks. Limits count eligible paths after pin checks, avoiding starvation.

Historical coverage advanced in the completed-run retention follow-up:

1. Canonical receipts now verify exact Git sources or saved ledger overrides,
   completed commands and full toolchain identities. Isolated source mismatches
   remain blockers for replay-qualified releases. Audited traces can now bind a
   missing original compiler to its completed guarded retirement and unchanged
   original build receipt. This does not rebuild an old executable or waive
   source verification. Unsupported legacy command formats still need review.
2. Per-file transitions bind original manifest, reference string and target hash.
   Completed retirement records have a review adapter; current manifests and
   unrelated targets stay pinned. Other validation-suite pins require review.
3. `release-build`, `release --request` and `maintain --release-request` provide
   producer lifecycle integration. Ordinary closed build outputs use the
   `disposable` contract without source reconstruction or an accepted successor;
   the optional stronger `superseded` contract retains both requirements.
   Unique unresolved failure diagnostics cannot be inferred redundant.
4. `inventory` counts each observed inode once and groups every file family by
   current contract, eligibility or unresolved reason. This exposes coverage
   without declaring all remaining bytes necessary or storing payload archives.

## Acceptance checks

Keep the expanded native and CLI suites passing in Debug and ReleaseFast.
Regressions cover minimal lifecycle, changed/missing pin aliases, cross-candidate
retention, failed trace releases, real collection, idempotence and the maintenance
wrapper. A completed private cache should qualify when its approved lifecycle
permits removal; busy, queued, pinned or changed candidates must remain held.
Source mismatches must never be represented as verified replay. The user's
disposable-build policy does not require replay for ordinary temporary outputs.

Use a fresh review before any apply, preserve the evidence required by the
selected retention contract, and verify current integrity manifests afterward. A review must
distinguish eligible, held, unsupported and unassessed storage. The observations
above are a dated diagnostic result, not a reusable deletion authorization.

Detailed local records are under
`local-state/storage-cleanup/investigation-20261113-0635/`. This tracked summary
preserves the findings without committing those generated artifacts.
