# Remaining local storage: purpose and retirement review

Status: reviewed cleanup complete; remaining categories and next work recorded. This continues
[completed-run retention](2026-11-13-completed-run-retention.md). Ordinary old
build binaries and objects are disposable; reconstructing or archiving their
source/build configuration is not a prerequisite for retirement. Current uses,
queued holds, adopted baselines and exact-executable investigations remain
separate constraints.

The starting inventory was
`local-state/retirements/automatic-storage-cleanup/1794567509443891881-3494523/inventory.json`:
147.34 GiB allocated, including 23.26 GiB under explicit current contracts and
124.08 GiB unresolved. These are inode counts during concurrent development,
not a claim that the retained files are all necessary.

## Completed compiler builds

All 37 reviewed behavior compiler outputs from v800–v967 were removed:
4,031,119,360 allocated file bytes. Four newly closed compiler caches contributed
another 170,352,640 bytes. Total: **4,201,472,000 bytes (3.91 GiB)**.

Their purpose was to execute completed experiments. The build reports remain;
source/configuration reconstruction was not performed for this disposal.
Seventy exact references in completed historical retirement records were
transitioned. Current holds and integrity manifests were not retired.

The first apply stopped on a live state change after 24 removals. A fresh pass
completed the other 17. Both left no pending mutation, and the completed pass
verified all five current integrity manifests. Records:

- `1794569002644849105-3548554/report.json`
- `1794569724655554928-3605743/report.json`

## Private native-test caches

These directories contain Zig-generated test executables, objects, compiler
modules and cache indexes. Their role ends with the owning test job unless a
current consumer or hold requires them. Original test receipts and logs live
outside the cache, including failure and cancellation diagnostics.

The survey read 305 unit-related receipts. Eighty-six use copied-project
`evidence/` directories; 42 explicitly name private caches. One earlier receipt
reuses the same ReleaseSafe cache as a later completed receipt, so the reviewed
plan has 41 distinct owning jobs. Queued/current roots remain subject to holds.
The 35 default `.zig-cache` directories in these projects contain only 286,720
allocated bytes in total; they are not a substantial remaining opportunity.

Older receipts omit cwd. Their copied-project layout is produced by
`prepare_unit_project_v686.zig`: `.zigversion` is copied, while `src`, `tools`,
`test` and `docs` are linked. The cache plan explicitly records the ownership
review of that layout, relative source/cache arguments and sibling logs. It
does not pretend that cwd was recorded historically. New `run_checked` receipts
record the actual child cwd.

The collector now supports explicit private-cache requests and retains every
producer log. It checks terminal status, actual return code, timestamps, exact
cache arguments, owner scope, pins, consumers, links and a complete cache
snapshot. The first real preparation rejected all entries because the initial
marker check tried to traverse `src`. That was corrected to inspect the owned
source link itself without following or changing it. The rejected preparation
removed no payloads. The corrected preparation accepted all 41 requests.
Fresh review qualified 70 cache roots totaling 11,045,298,176 allocated file
bytes (10.29 GiB). Twelve other private-cache roots remain held under the
current tail-owner and legacy-tail test projects. No historical pin transition
was needed for the 70 admitted caches.

All 70 qualified caches have now been removed. The first pass removed 43
(6,651,994,112 bytes); a fresh pass removed the other 27 (4,393,304,064 bytes).
Both passes subsequently stopped when controls changed, with no pending
mutation and no partially reclaimed action. Completed records remain valid:

- `1794570765801491596-3667800/report.json`
- `1794572128285454410-3709751/report.json`

Implementation commits: `8584a487`, `cd595a6e`. Native qualification passes
74 tests in Debug and ReleaseFast. All 16 isolated CLI checks pass again after
the source-link correction; real-batch results are recorded below.
An independent smoke test verified that the recorded cwd equals `/bin/pwd`
when the invoking shell is in a different directory.

## Audited raw traces

Raw event streams explain compiler selection, failures, counters and timing.
They are different from executable build outputs. Complete semantic audits,
summaries, original outcomes and failure diagnostics already exist for many.

**Correction to the initial investigation:** the 24 isolated-prototype traces
in `unlinked-trace-audit-20261113/file-findings.json` were already removed by
`strong-trace-cleanup-20261113/record.json`. That completed record reports
22,711,975,936 bytes and 24 actions; all 24 paths are now absent. The earlier
version of this report incorrectly treated that old catalog as a live candidate
list. Its 21.15 GiB is historical reclaim, not additional space available or freed
in this investigation. Fresh checks of 15,384 old source hashes and original
compiler retirement bindings were valid but did not establish raw-file presence.

The live filesystem scan instead finds **89 distinct raw-trace inodes totaling
30,662,504,448 bytes**. Large surviving behavior traces include newer v733–v921
experiments that are absent from that older audit catalog. They need fresh
semantic audits and current build/input bindings. Some large original-compiler
streams have multiple aliases; current accepted and queued streams remain held.
The 22 surviving entries from the old 48-stream catalog occupy only
737,046,528 bytes: 14 canonical traces and eight legacy command/source cases.

The collector's new retired-compiler transition authenticates a completed
guarded retirement against the original build receipt and audited compiler
identity. It verifies allocation, the hash-bound owner request, unchanged build
receipt and continued absence of the executable. Complete source, input,
toolchain, audit and diagnostic checks still apply. No replacement executable is
built. The implementation passes 82 native tests in Debug and ReleaseFast and
all 18 CLI checks. The initial CLI run caught an unsupported dynamic array-index
query in the test script; selecting the matching retirement file with
`input_filename()` corrected it, and the full CLI suite passed afterward.
This is usable for live newer traces after
their full audits, rather than another retirement of the already absent group.

The fresh live batch contains 18 single-link behavior traces, 17,056,370,688
allocated bytes (15.885 GiB), from v733–v921. Seventeen original compilers have
matching guarded retirement records; v853 ReleaseFast is still present.
The tracked native auditor read **54,834,041 events** and verified all 18 full
streams against input, producer, report, tail counter and failed-function
bindings. All 18 remain recorded as failed compilations. Its results are under
`local-state/retirements/native-event-audit/1794574631493448536-3818051/`.
Build/source, pins, holds and consumers remain separate release requirements.

The reusable auditor is committed as `45b69868`, with pinned-Zig build wiring
corrected in the following commit. Fifteen native checks pass in Debug and
ReleaseFast, including full fixture reads, truncation, changed hashes, unrelated
producer commands, malformed events and exact failure bindings. Both actual
`test-native-event-audit` build targets pass. A stale global Zig `maker` cache
required task-private cache environment variables; no shared cache was deleted.

All 18 live traces subsequently passed full release qualification and were
removed in `1794575010186037946-3833279/report.json`, reclaiming
**17,056,370,688 allocated file bytes (15.885 GiB)**. The completed pass rechecked
all five current integrity manifests. No historical pin exception was needed.
Original failed outcomes, source/input/build evidence and compact audits remain.

## Integrated comparison runs

Twenty-nine unresolved integrated-run roots in the starting inventory total
**25,981,669,376 bytes (24.20 GiB)**. This is a mixed category:

| Family | Allocated bytes | Purpose and next action |
| --- | ---: | --- |
| Executables | 5,058,748,416 | Capture helpers and local/reference programs used by completed comparisons; identify each producer and current baseline before retirement. |
| Objects/archives | 1,806,893,056 | Generated comparison/linking outputs; strong disposable candidates after matching terminal command records. |
| Recognized caches | 1,446,195,200 | Private Zig cache roots; current isolated-build adapter does not bind the integrated-run schema. |
| Compiler inputs | 8,367,509,504 | Captured preoptimization, optimized and object-input IR needed to explain/replay a comparison; review duplicate content independently. |
| Other | 5,384,519,680 | Includes large generated `linked-harness.s` assembly; the filename-family inventory does not assign all of it a semantic role. |
| Records/analyses | 2,594,672,640 | Commands, captured backend reports and local/reference observations; retain compact results while reviewing redundant detail. |
| Logs | 1,121,869,824 | Original command diagnostics; failed/incomplete outcomes require individual review. |
| Source and directories | 201,261,056 | Separate from generated executables and caches. |

For example, `integrated-behavior-followup-v781` occupies 2,252,787,712 bytes.
Its `input-program/report.json` records 138 local and 138 reference executions
with passed status. Other subtrees have their own commands and results; that
one passed report does not close the entire tree. The next adapter should read
those command/output bindings and release only generated outputs, preserving
IR, sources and result records. Blanket deletion of an integrated root would
mix these different roles.

Closer inspection of this example found seven separate `capture-zllvm`
executables of about 19 MB each and generated `linked-harness.s` files of about
14.6 MB each. These are concrete output families, rather than unexplained
"other" bytes. Some commands intentionally return 2 for negative test inputs;
the comparison records matching local/reference results. An adapter must bind
the successful build commands separately from these expected execution
outcomes, rather than requiring every command to return zero. Executables named
`local`, `reference` and `capture-zllvm` also need explicit output ownership;
the current filename allowlist does not treat arbitrary extensionless files as
disposable binaries.

A fresh filename/inode scan across the integrated roots found 38 distinct
`capture-zllvm` executable inodes occupying 723,795,968 bytes (three have
aliases), and 567 `linked-harness.s` files occupying 5,490,835,456 bytes. The
scan includes current as well as unresolved integrated roots, so these are
purpose-specific totals, not all immediately eligible bytes. These two known
output families make the next command-ownership adapter concrete.

## Duplicate large IR inputs

A fresh scan of `input.ll` files at least 400,000,000 bytes found 68 paths but
only **12 distinct inodes**, occupying 5,323,603,968 bytes. Existing hardlinks
already share many names. Hashing one representative of every inode found:

- Eleven distinct inodes with the identical 443,624,107-byte input and SHA-256
  `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
- One different self-rebuild input with SHA-256
  `7217b032845c0bb8e653823eac80bfae571707eed60793047c2576e27b849976`.

The theoretical redundancy is about **4.13 GiB**, not 67 copies. These files
are recorded inputs, and some inode groups already have 35 aliases. They are
writable. Replacing independent copies with hardlinks without establishing
immutability would couple future writes. Use a reviewed immutable input-store
transition that preserves named consumers and verifies every alias; no input
paths were removed by this investigation.

## Pinned and discrepant selection compilers

The broader survey found 41 present canonical compiler install paths with
closed successful build commands. They occupy 36 distinct inodes and
3,776,917,504 allocated bytes; eight paths have multiple hardlink aliases.
Nineteen qualified binaries were removed, reclaiming 2,221,797,376 bytes:
four in `1794572128285454410-3709751/report.json` and fifteen in the completed
`1794573262184771142-3757407/report.json`. Fifty exact historical references were
transitioned; current validation manifests still protect their targets. The
completed pass verified all five integrity manifests and left no pending
mutation. Other paths remain pinned, aliased or discrepant. The receipt and
inode lists are saved beside the cache investigation.

The batch-30 current accepted-artifact manifest references both v3 compilers
and the earlier v1 compilers. Seeing `expected-binaries-v1.sha256` as the first
reported pin did not mean it was their only pin. Other old selection outputs
are referenced by batch-11, batch-13 and batch-14 manifests. These contracts
need specific review; age and a newer compiler version do not automatically
expire them. Being required by a checksum contract is also distinct from
proving that an executable still has a live consumer.

The batch-11 Debug v4 mismatch is explained by
`batch-11/binary-review-v5/inspection-incident.json`: GNU objcopy repacked the
install in place during an inspection. The current hash is
`db03461e04b0f42352180d8de448e025f4f944b028b6bc42105d589ef0b4f329`, matching the
recorded incident, while the build receipt expects `f69bac40…`. The original
receipt remains accurate for the original build. The incident explicitly kept
the repacked executable as discrepancy evidence and gave it no final acceptance
credit. Do not silently replace the expected hash to make cleanup pass.

## Other retained evidence

Native-suite roots outside the integrated-run group contain about 3.19 GiB
unresolved in the starting inventory. They include local/reference test
executables and objects, but also 1,398,972,416 bytes of stdout/stderr logs and
290,463,744 bytes of result records. Large allocations are spread across
thousands of per-case files, rather than one abandoned log. Their comparison
reports and per-command outcomes should drive selective compaction and output
retirement.

Research source copies and accepted source snapshots have a different role
from binaries. They can contain the sole remaining experiment edits or serve
active audit/replay consumers. The disposable-build policy removes the need to
create new source archives; it does not establish that every existing research
tree is redundant. Current shared caches, worktrees and artifact-store objects
also need their own consumer/store lifecycle, not the private-cache rule.

## Local evidence and next order

Small inventories, source-check results, input inode/hash lists, qualification
logs and the cache ownership plan are in
`local-state/storage-cleanup/remaining-investigation/`. They contain no copied
payload archive. The pin optimization was measured on 100,000 repeated absent
references: 0.59 s before and 0.50 s after in one isolated run. That narrow
measurement is not a claim that historical full-project cleanup is fast.

## Verified result and remaining inventory

Completed collector actions in this investigation reconcile to:

| Removed family | Count | Allocated file bytes reclaimed |
| --- | ---: | ---: |
| Compiler binaries | 56 | 6,252,916,736 |
| Complete private caches | 74 | 11,215,650,816 |
| Freshly audited raw traces | 18 | 17,056,370,688 |
| **Total** | **148** | **34,524,938,240 (32.154 GiB)** |

Separately, completed tool qualification caches, a temporary cwd-check runner
and the superseded collector occupied 408,023,040 allocated bytes (about
0.38 GiB) and were removed. Cache measurements include directory blocks.
Their receipts, qualification logs and current installed helpers remain.
No source or configuration archive was created for these temporary outputs.
The old 21.15-GiB trace retirement is excluded from all new reclaim totals.

The repeat pass `1794575674718614739-3860888/report.json` removed zero files.
All five current integrity manifests passed again, with no pending mutation.
It retains 66 known candidate paths: 44 held caches and 22 pinned, aliased or
discrepant compiler paths. Some aliases share allocation; do not sum their
per-path sizes as exclusive disk usage.

The final full inventory is
`local-state/retirements/automatic-storage-cleanup/1794575797261399899-3863323/inventory.json`:

| Disposition | Allocated bytes | GiB |
| --- | ---: | ---: |
| Required by current contracts | 30,518,611,968 | 28.423 |
| Eligible under reviewed releases | 0 | 0 |
| Unresolved | 99,844,767,744 | 92.988 |
| **Total** | **130,363,379,712** | **121.410** |

The walk observed 1,676,696 paths and 1,666,546 unique inodes, with no vanished
or foreign-device entries. The folder fell from 147.34 to 121.41 GiB during
concurrent development; new allocations mean that net change differs from
the completed retirement ledger. These are filesystem observations, not an
atomic snapshot or a claim that 121.41 GiB is necessary.

The remaining executable family alone contains 32,486,006,784 unresolved bytes
(about 30.26 GiB), plus 14,206,308,352 bytes under current contracts. Executable
mode/name classification includes private build outputs; it is not proof of a
live consumer. The integrated-run breakdown above is unchanged in the final
inventory. A fresh raw-file scan finds 71 distinct remaining traces occupying
13,606,133,760 bytes (12.672 GiB), including current baselines, aliases and
older source/build cases.

Next work, in order:

1. Bind integrated/native comparison outputs to completed command and producer
   records. Cover extensionless ELF programs, capture helpers, objects and
   generated assembly, while keeping IR, compact results and failure diagnostics.
   Account for expected nonzero test outcomes and complete alias groups. Many
   small outputs need a guarded generation-level batch; a full pin-graph refresh
   per object would be impractical.
2. Establish an immutable input-store transition for duplicate IR. The verified
   4.13-GiB redundancy in large inputs is potential reclaim, not permission to
   couple independently writable files with hardlinks.
3. Review the remaining original-compiler/self-rebuild traces and legacy source
   bindings from the live inventory. Preserve current seals and queued holds;
   whole-stream integrity alone is not a release decision.
4. Review historical expected-binary contracts and the known repacked v4 Debug
   executable separately from current acceptance. Keep unresolved allocation
   visible until those contracts or producer roles are resolved.

The utility work discovered during this investigation is also complete:
`zigrep` 0.3.19 is installed in `~/bin`, with 454 tests passing in Debug and
ReleaseFast and the original 41-pattern query reduced from 19.53 s to 0.02 s
with identical results. Its own 1,804,275,712-byte cache retirement occurred
outside this project's `local-state` and is excluded from the totals above.
`jqz` 0.33.0 continues to handle exact structured accounting.

## Follow-up: generated files and shared inputs

The follow-up starts from a fresh filesystem scan, not the earlier filename
catalog. Evidence is in `local-state/storage-cleanup/generated-review/`.
It found 609 `linked-harness.s` inodes (5,897,609,216 allocated bytes) and
39 `capture-zllvm` inodes (742,846,464 bytes). Four helper inodes account for
105 names; the other 35 helpers each have one link. Every alias of those four
inodes was found under `local-state`, matching the filesystem link counts.
Seven names in one group are pinned by the current batch-30 acceptance manifest.
Per-path totals for the 105 aliases count the same allocation repeatedly and
must not be reported as reclaimable bytes.

All 169 owning reports passed: 29 `execution-breadth-controls-v2` reports and
140 `real-program-v1` reports. The assembly is temporary executable-harness
output, produced with `-femit-asm` and consumed by the successful assembler
command recorded in the row's two producer indexes. The capture helpers are
copies of the validation runner itself, bound to the report's runner hash.
They are not copies of the compiler being tested.

The new `prepare-generated` adapter verifies these bindings and only prepares
explicit output requests. It initially prepared 728 requests. Twenty-one
assembly files in batch-11 `integrated-v5`, occupying 203,321,344 bytes, were
rejected because their recorded command logs no longer exist. Investigation
found all 84 missing logs in the completed
`reviewed-artifacts-20261112/record.json`: each was an empty file with the empty
SHA-256 and an applied retirement. This is a known historical-log transition,
not missing failure diagnostics; the current adapter still requires those logs
and does not yet consume this older retirement schema. These assembly files
remain outside the current deletion list.

The first full review qualified 133 files (1,549,967,360 bytes). Preparing
1,246 exact transitions from historical cleanup records expanded qualification
to **434 files, 4,530,511,872 bytes (4.219 GiB)**: 399 assemblies and 35 helpers.
The five current integrity manifests all verified. Requests and reviews:

- Prepared ownership: `1794588289225121077-4117891/requests.json`.
- Initial review: `1794588386084504213-4120295/report.json`.
- Historical transitions: `1794588556572342218-4123844/requests.json`.
- Reviewed transitions: `1794588874576236265-4131581/report.json`.

All paths above are under `local-state/retirements/automatic-storage-cleanup/`.
Current acceptance contracts are never excused by these historical transitions.
A further 189 assemblies are pinned by seven selection acceptance manifests and
the performance/throughput artifact manifests. Six of those selection manifests
are older milestones, not one of the five explicitly current contracts; their
continued necessity needs a separate acceptance-lifecycle review. The collector
does not infer their expiry from age. Four aliased helper inodes remain held.

Collection groups eligible named files from one completed integrated run into
a guarded transaction. It does not remove the mixed run directory. The durable
pending record names all original paths, hashes, metadata and quarantine names.
After quarantine it refreshes pins, holds and consumers before any unlink;
pre-unlink failure restores every original name. Each removed file receives
its own completed record. A partial or interrupted batch blocks new cleanup.
An active parent integrated job also protects already finished subtests.

The large-IR review rehashed all 12 distinct inodes. Eleven still have hash
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`; the separate
self-rebuild input retains hash
`7217b032845c0bb8e653823eac80bfae571707eed60793047c2576e27b849976`.
The full alias scan found **69 names**, matching every link count. The earlier
68-name list omitted `whole-compiler-20261107/attempt-4/compiler-module/compiler.ll`,
which shares the 35-link input inode. This changes the name count, not allocation
or the 4,436,340,736-byte theoretical saving.

Two duplicate inodes are mode 0444; the remaining duplicate inodes and the
separate self-rebuild input are writable. The captured input is a run-specific
replay input: `whole_compiler.zig` copies it into a newly created run directory
and records its hash. `Context.copy` opens its destination with truncation.
The artifact store publishes read-only objects but `get` currently copies them
into new files; it does not migrate existing aliases. A scratch probe on this
ext4 filesystem confirmed that `cp --reflink=always` is unsupported. Safe sharing
therefore needs an explicit immutable-input installation/consumer transition,
with all 69 names and current contracts covered. No input path or permission was
changed by this review.

Implementation `3a36c17e` passes 94 native checks in Debug and ReleaseFast,
plus 20 isolated CLI checks. Coverage includes changed producer records,
failed/unrelated commands, hardlink rejection, parent-job protection, frozen
parent permissions, rollback on a newly discovered pin, preservation of inputs
and repeat collection. The first apply
`1794589246953680298-4138793/report.json` stopped on a changed holds file before
any removal, with no pending mutation. A fresh pass uses the updated controls.

The qualification's two private caches were removed after tests finished and
a no-open-consumer/no-hardlink check: 299,638,784 allocated bytes including
directory blocks. This is separate temporary-tool accounting, not part of the
4,530,511,872-byte reviewed payload set. Test logs and the compiled helper remain.

To prevent these output families from accumulating again, completed producers
should declare their temporary outputs to the collector. Future acceptance
manifest design should distinguish retained reports/inputs from temporary
assembly and helper executables; current manifests must keep their existing
meaning until that lifecycle transition is explicitly reviewed.

The fresh apply completed in
`1794589425429925414-4141890/report.json`: **434 removed, zero eligible remaining,
4,530,511,872 allocated file bytes reclaimed**. All five current integrity
manifests verified afterward, with no pending mutation. A fresh path check
matches the 434 absent names exactly to the 434 completed removal actions.
The original 749 reviewed names now leave 315 names on 214 inodes:

| Remaining family | Distinct inodes | Allocated bytes | Reason |
| --- | ---: | ---: | --- |
| Generated assembly | 210 | 2,033,745,920 | 189 contract-pinned files and 21 files requiring the verified empty-log retirement transition. |
| Capture helpers | 4 | 76,197,888 | 105 hardlink names; one group includes current accepted paths. |

The qualified ReleaseFast collector is installed at
`local-state/storage-cleanup/clean-storage`, SHA-256
`51ee26d3fac62a10d471ed12f86a48454c6c7cf18c0cefeb16011ee13812541e`.
Replacing the previous helper and removing two qualification executables retired
another 26,251,264 allocated bytes. The final helper check exposed an unsupported
`zigrep -x` flag. The original pre-install lsof snapshot was independently
verified using literal whole-line comparisons: none of the three superseded
helpers had an open consumer. This was an ad hoc probe issue; the native
collector rejects zigrep error exits and its completed cleanup was unaffected.
The utility feature request and implementation follow-up are in the zigrep
repository. The shared workflow now requires separate match/no-match/error
handling for cleanup probes.

A concurrent whole-folder `du` sample was 138,503,094,272 allocated bytes
(about 129 GiB). This is not a new full
purpose inventory. Other compiler work continued during this investigation,
so the folder's net change is not the sum of these retirement records.

The utility follow-up is complete: zigrep 0.3.21 adds `-x` / `--line-regexp`,
with 469 passing tests in Debug and ReleaseFast and 33 installed-binary ripgrep
comparisons. Its ReleaseFast binary is installed in `~/bin`; the original
three exact-path queries now return no match (exit 1), agreeing with the literal
snapshot check. The implementation is zigrep commit `3a7e6e3`, with installation
and task-cache retirement recorded in `566b0bb`. Its separate 733,945,856-byte
scratch retirement is outside z_llvm and excluded from the payload total above.

A fresh review through both installed tools completed in
`1794591539984689209-4183507/report.json`: zero eligible files in the prepared
set, zero further removals, and all five current integrity manifests verified.
`generated-review/summary.json` and `installed-validation.json` retain the
compact machine-readable results alongside the per-path evidence.
