# Review and retire remaining compiled outputs

1. Inventory executable, object and archive paths with inode/link accounting.
   Start with the three unresolved readiness-cache groups, then validation
   compilers and test programs. Identify closed owners, current consumers,
   queued work, retained dependencies and all aliases before proposing removal.
2. Use existing native retirement adapters where possible. Extend the collector
   for demonstrated legacy layouts, with explicit evidence bindings and tests;
   preserve current contracts, independent holds, source, commands and results.
3. Qualify Debug and ReleaseFast, install the checked collector, review and
   collect eligible products through guarded transactions. Explain unresolved
   groups rather than treating missing evidence as permission to delete.
4. Remove task-owned build scratch, verify retained integrity, record the new
   inventory and exact reclamation, and commit implementation and results.

Starting inventory:
`local-state/retirements/automatic-storage-cleanup/1794649658752532842-1379413/inventory.json`.
The main checkout contains 85.085 GiB. Unresolved compiled outputs account for
21.251 GiB of executables and 3.655 GiB of objects/archives. These are review
sizes, not guaranteed savings. The preceding pass's 32.510 GiB net reduction is
not part of this task's totals.

Evidence: `local-state/storage-cleanup/compiled-products-20261114/`.

Current acceptance remains
`docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json`.
The compiler agent was idle at the start, with its compiler/self-rebuild work
complete; its accepted generations in the qualified-behavior sibling checkout
remain outside this cleanup. No new source/configuration archives are required
for ordinary closed build products; preserve existing provenance and results.

## Qualification and review findings

- `7475ea10` adds explicit closed-command output preparation and verification
  of the fixed legacy readiness launcher. Its 168 tests passed in Debug and
  ReleaseFast; five CLI argument checks passed.
- `826dd1b3` recognizes the native linker's partial `wrong-symbol` output only
  with the closed failed command, undefined-symbol diagnostic and consistent
  ELF64 program-header structure. All 169 tests passed in both modes.
- `4300a299` binds older compilers without build receipts to their exact hashes
  in passed native comparisons and saved successful compiler invocations.
  Existing receipts still take precedence. All 172 tests passed in Debug and
  ReleaseFast; nine CLI checks cover the two preparation modes.
- `43a509cc` also recognizes the fixed `/usr/bin/taskset --cpu-list 0` child
  wrapper used by one old self-rebuild, including inside the recorded `time`
  wrapper. Other affinity options and process-ID forms are rejected. All 173
  tests pass in Debug and ReleaseFast.
- The final qualified ReleaseFast collector is installed at
  `local-state/storage-cleanup/clean-storage`, SHA-256
  `f8a2eb7a52d06a4ca4f47a370629e5b0d28f2e677562faca7a1832e5267d61bb`.
- Preparation accepted 1,219 of 1,359 closed owner reports. The other 140 had
  no usable output bindings, noncanonical paths, missing completion/working
  directory fields, or missing diagnostic evidence. Their products stay for
  further investigation.
- The three selected readiness caches were collected through guarded cache
  transactions: 1,051,525,120 allocated file bytes. All five current integrity
  contracts passed afterward; the 517 manual holds were unchanged.
- Older checksum lists pin completed test products as well as maintained
  evidence. Any transition in this pass names only an individually qualified,
  hash-matched compiled product; checksum lists, commands and results remain.
  The five policy current manifests are never transitioned.
- The extra completed unit-test cache is inside the broader
  `behavior-complete-units-v1161` hold. Its 331,681,792 cache bytes remain held.
  The existing hold-narrowing adapter supports direct cache children, whereas
  this project nests caches and diagnostics together under `evidence/`.
- A remaining Debug compiler in selection batch 11 no longer matches its
  canonical build receipt. A receipt mismatch is not evidence of safe removal.
  Compiler files with neither a usable receipt nor a successful matching native
  observation remain unresolved.
- Checking all 3,575 surviving report paths produced 67 native-comparison
  observations identifying 43 distinct legacy compiler paths. After exact
  historical-pin review, 33 paths were collected, reclaiming 2,558,124,032 file
  bytes. The other 10 remained protected by holds, unresolved historical pins
  or incomplete alias groups.
- Two allocation-memory compilers are blocked by `fp-bitcast.sha256`. This
  historical file contains only 64 digest characters and no target path;
  the conservative pin scanner therefore protects its containing validation
  tree. The acceptance record retains this digest file, but the digest's
  original target still needs a verified binding. No blanket pin exception
  was introduced for this ambiguous format.
- During the final compiler/cache batch, the other agent started
  `compiler-throughput-20261114` under the shared storage lock. The collector
  refused the batch before discovery; the refusal is retained in
  `lock-busy-compiler-and-unit-cache.log`. All original 517 holds remain, with
  one new hold for that throughput project. New work is outside these reviewed
  retirement requests and can add storage during final accounting. The batch
  resumed after the reader lease ended and collected 12 old compiler paths
  (609,398,784 file bytes). Installation and final inventory also waited for
  reader leases; the new project's temporary workspace remained held.
- The final affinity-wrapper review bound the 150,831,104-byte v34 self-rebuild
  successfully, but found it retained by an earlier raw-trace retirement
  (`1794622414199474427-918921/record-131.json`) and historical object seals,
  alongside two validation identity lists. It is an existing replay dependency,
  not merely an unrecognized temporary output. It remains until that dependency
  has a verified replacement; no pin exceptions were added for this file.

Expanded alias reviews, historical-pin decisions, collection totals and final
inventory are recorded under the evidence directory above.

## Collection results

The reviewed batches removed **31,450 compiled-file paths and three readiness
cache groups**, reclaiming **9,760,071,680 allocated file bytes (9.090 GiB)**.
Every completed mutation report verifies all five current integrity contracts.
`completed-applies.tsv`, `completed-applies.ndjson`, `reclaimed-payload.json`,
`removed-kinds.ndjson` and `reclaimed-kinds.ndjson` provide the exact receipt
paths and accounting. Shared inodes are counted once; path count is not a
count of distinct binary contents.

The two discovery tables are losslessly compressed as `products.tsv.gz` and
`products-with-owners.tsv.gz`. Their decompressed bytes were compared with the
original tables; original SHA-256 values are retained. No hash-bound requests
or retirement records were rewritten.

Task-owned build scratch was removed after installation: **771 files,
362,594,304 allocated bytes (0.338 GiB)**. This is separate from the 9.090 GiB
of existing payload, because these files were created during this pass.
`scratch-retirement.json`, file metadata and SHA-256 lists preserve the checks.

The closing native inventory is
`local-state/retirements/automatic-storage-cleanup/1794658618618398069-1546034/inventory.json`:

| Classification | Allocated bytes | GiB |
| --- | ---: | ---: |
| Total | 83,270,471,680 | 77.552 |
| Required by current contracts or holds | 20,422,836,224 | 19.020 |
| Eligible for automatic collection | 0 | 0 |
| Unresolved purpose or retirement proof | 62,847,635,456 | 58.531 |

It observed 1,701,919 paths and 1,692,778 unique inodes, with no vanished or
foreign-device entries. The inventory decreased **8,088,539,136 bytes
(7.533 GiB)** from the starting observation. Gross reclamation is larger than
the net decrease because this pass added audit records and the other agent
started new build/profiling work. A subsequent `du` measured 83,281,838,080
bytes (77.562 GiB); these are point-in-time measurements during ongoing work.

`final-integrity.json` independently verifies all five current integrity
manifests, all four accepted compiler/source/manifest artifacts, preservation
of every original hold, and the absence of a pending transaction. There are
518 holds after the other agent's single addition. The inventory's own
`current_integrity_verified:false` means no deletion candidate required that
check in its read-only pass; the separate final verification passed.

Unresolved does not mean needed. The remaining review pool includes 12.587 GiB
of executables and 3.384 GiB of objects/archives. It also includes 13.521 GiB of
records/analysis and 11.107 GiB of compiler inputs; the complete breakdown is
in `final-unresolved-kinds.ndjson`. Larger unresolved compiled groups include
the old Fibonacci validation root (0.532 GiB), parser-throughput benchmarks
(0.494 GiB), and validation-performance root (0.277 GiB). Their ownership,
aliases and any retained replay dependencies need review before retirement.
Existing holds, the receipt mismatch, ambiguous hash-only sidecar, incomplete
alias groups and the self-rebuild replay dependency described above were not
overridden.
