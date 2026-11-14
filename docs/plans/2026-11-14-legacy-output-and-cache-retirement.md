# Legacy output ownership and closed cache retirement

1. Review the unresolved executable/object inventory against existing terminal
   reports and commands. Extend native ownership adapters only for demonstrated
   producer formats; ordinary disposable outputs need no source/config archive.
2. Find every name of the 705 previously incomplete hardlink candidates and bind
   each owner independently. Retire only complete, unheld, unpinned groups.
3. Review the 128 held private caches. Narrow obsolete cache retention only where
   closed producer evidence proves ownership; preserve compilers, maintained
   evidence, queued work, current pins and independent investigation holds.
4. Test new rules in Debug and ReleaseFast, install the qualified helper, perform
   guarded removals, remove this task's build scratch, and record a new inventory.

Starting verified inventory: 129.338 GiB in main `local-state`, with 27.638 GiB
of unresolved executables and 4.116 GiB of objects/archives. The 128 held cache
candidates account for approximately 5.092 GiB. These quantities define review
scope, not guaranteed reclamation. The previous 705-name alias set and cache
decisions are recorded in
`local-state/retirements/automatic-storage-cleanup/1794624079900682835-949682/report.json`.

## Implementation and reviewed boundaries

Commit `5c1de555` adds native receipt preparation, independent hardlink-owner
discovery, explicit cache-hold narrowing and bounded cache transactions. Its
qualified ReleaseFast binary, used for the first three collection passes, had
SHA-256 `7b92e84ccf3cdef6b20937b8faa6b24ef3e18d277af9a78b4324303d1b39e0f8`
and passed 154 cleanup tests in each mode.

The helper review then exposed an older capture layout without a batch directory.
It stopped before mutation with `InvalidReleaseScope`. Commit `1257836a` admits
only the direct capture helper from that layout, still requiring the passed
comparison and exact runner-provenance hash. All **155 cleanup tests** pass in
both Debug and ReleaseFast, and eight CLI checks pass. The final installed
ReleaseFast collector has SHA-256
`042bb1cd3e49dca81747b23961be0820347c9e4499c36eec1859f0d7f59d831f`.
Qualification evidence and source hashes are under
`local-state/storage-cleanup/legacy-retirement-20261114/`.

- 65 checked-run receipts bind explicit, present compiled products: 5.546 GiB
  before retention checks. Thirteen other receipts have no supported present
  output binding, including environment/debugger wrappers and compile-only
  checks. No output destination was inferred for those commands.
- 121 passed report/command owners bind 11,784 product names covering 1.818 GiB
  before retention checks. Failed owners and unsuccessful output commands remain
  unqualified. Another 14 capture-helper requests were prepared independently.
- The 705 old hardlink candidates belong to 53 inodes with 3,425 observed names.
  Discovery prepared 64 additional owners. It found 158 names without a supported
  report/command owner and five rejected owners (four failed reports, one with
  an unsuccessful command). Those names prevent collection of their complete
  physical groups. Several belong to current selection-contract runs.
- All 64 reviewed run holds contained exactly two closed private caches and five
  maintained children: compiler, report, command record and both build logs.
  Hold narrowing retained those 320 children and all 263 unselected holds,
  producing 583 explicit holds. No compiler hold was removed.

Native preparation and collection remain separate. Overlapping preparation
lists are collected in successive passes, so independently generated requests
cannot silently replace one another's evidence or pin transitions. Historical
pin exceptions bind exact manifest bytes, target paths and hashes; the five
current integrity manifests remain mandatory.

## Completed collection

| Pass | Removed | Reclaimed allocated file bytes |
| --- | --- | ---: |
| Closed caches and complete aliases | 128 caches and 510 compiled-file names | 5,479,751,680 |
| Historical checked-run products | 63 compiled-file names | 5,914,222,592 |
| Passed command-output owners | 10,486 compiled-file names | 1,434,890,240 |
| Capture helpers and reviewed frame prototype | 6 compiled-file names | 59,437,056 |
| This task's completed build/test scratch | 767 files | 313,004,032 |
| **Total** | **128 caches, 11,065 compiled-file names, and owned scratch** | **13,201,305,600 (12.295 GiB)** |

Hardlink allocation is counted once, on the last unlink. The first pass includes
73,976 cache files. All 320 maintained children of the narrowed run holds and
all 263 other manual holds remain protected. The frame prototype's four-entry
checksum manifest remains unchanged: only its exact temporary compiler
reference was retired; the three source checks remain binding.

The fresh inventory observes **126,266,855,424 bytes (117.595 GiB)** across
1,732,139 paths, with no vanished or foreign-device entries:

- 51,243,900,928 bytes (47.725 GiB) are covered by explicit holds/current contracts.
- 75,022,954,496 bytes (69.871 GiB) remain unresolved.
- No eligible bytes remain in the final reviewed candidate set. All five current
  integrity manifests pass, and no pending mutation journal remains.

The observed folder reduction is separate from gross reclamation: new review
and retirement evidence and directory allocation are included in the inventory.
Remaining unresolved storage is not established as necessary. It includes
22,818,111,488 bytes of executables, 3,924,180,992 bytes of objects/archives,
15,535,005,696 bytes of compiler inputs and other historical data. Incomplete
aliases, failed owners and validation checksum pins remain explicit blockers;
counts from overlapping review sets must not be added together.

The full result, qualification, source hashes and per-pass references are in
`local-state/storage-cleanup/legacy-retirement-20261114/summary.json`.
The final inventory is
`local-state/retirements/automatic-storage-cleanup/1794641931970003745-1242439/inventory.json`.
Only this task's own build scratch was retired. The installed collector and its
source remain available; no sibling checkout was collected.

All four plan steps are complete. Further reduction requires reviewing the
remaining compiler/input owners and the specific outstanding contracts, not
assuming that every unresolved file is disposable.
