# Review held build products and repeated compiler inputs

Status: complete. Implementation commit: `08b18133`.

1. Review the holders, current readers, queued/unfinished jobs, receipt ownership
   and integrity contracts for `behavior-tools-v1038`, `full-zig-local-v7`, and
   the 64 retained compiler binaries. Keep exact active dependencies and records;
   narrow only obsolete manual holds.
2. Extend the native collector where a demonstrated shared-cache or held-build
   lifecycle is not yet supported. Qualify changes in Debug and ReleaseFast,
   install the checked binary, and collect verified disposable products.
3. Inventory compiler inputs by content and inode, including every alias. Use
   the immutable input store for suitable identical copies while preserving
   filenames, bytes, current contracts, queued holds and readers.
4. Verify remaining contracts, remove task-owned build scratch, and record exact
   reclamation and a new purpose inventory. Commit implementation and results.

Starting observation: 117.595 GiB in the main checkout's `local-state`, including
47.725 GiB covered by explicit holds/current contracts and 69.871 GiB unresolved.
Review targets contain 18.756 GiB in `behavior-tools-v1038`, 3.911 GiB in
`full-zig-local-v7`, 6.532 GiB in 64 held compiler files, and 14.47 GiB of
unresolved compiler inputs. These are review sizes, not guaranteed savings;
hardlinks and current obligations must be accounted for before collection.

Evidence for this task goes in
`local-state/storage-cleanup/held-products-20261114/`. The preceding task's
12.295 GiB of reclamation is not part of this task's totals.

## Review findings

The compiler agent is idle and its latest handoff reports the compiler and
self-rebuild follow-up complete. The final acceptance is
`docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json`, superseding
the earlier cumulative checkpoint's open follow-up. Both accepted compiler
generations remain in the separate qualified-behavior-v1461 checkout. None of
the 64 main-checkout prototypes is either final generation; all 64 have one
hardlink and together occupy 7,013,982,208 allocated bytes.

The two caches have 756 directly bound terminal receipts. Six additional old
shell commands in the bounded/remaining sibling checkouts also have finished
outer receipts. The five registered storage jobs are finished. No current
compiler process or queued use of these exact products was found. The review
retains the final generations, acceptance manifest, source snapshot, original
receipts and commands. Generic cache protection remains the default.

The native `retire-held-products` command binds this explicit lifecycle review
to the unchanged hold file and evidence. It keeps independent job/release holds,
retained dependencies, current manifests, historical pins and reader checks.
Only successfully collected paths lose their exact manual holds. The first dry
run exposed a timestamp issue with newly staged release records; qualification
now advances its observation time after staging, with regression coverage.

The input inventory found 87,158 names and 84,306 physical input files across
the whole main `local-state`, including protected inputs and worktree fixtures.
Hashing identified 1,629 repeated-content families, with a theoretical
6,015,201,280 bytes of duplicate allocation before holds, aliases and new store
objects. Those figures exceed the original unresolved-input subset and are not
reclamation totals. Migration is limited to generated LLVM capture/optimized
inputs of at least 256 KiB; checked-in fixture copies, source worktrees, AIR and
bitcode remain outside this migration. The narrowed plan has 1,300 filenames.
The review preserves held inputs and incomplete alias groups.

## Completed results

| Work | Result | Allocated file bytes reclaimed |
| --- | --- | ---: |
| Retire ordinary compilers | 64 files | 7,013,982,208 |
| Retire reviewed shared caches | 2 roots | 24,322,768,896 |
| Share generated inputs | 481 old physical files, 1,027 preserved paths | 3,608,739,840 net |
| Existing payload total | 32.546 GiB | 34,945,490,944 |

Input migration removed 4,480,806,912 old allocated bytes and created
872,067,072 bytes of immutable objects. It preserved 159 paths in 92 held
physical files, 98 paths in two incomplete alias groups, and 16 paths already
sharing one stored object. The incomplete groups include original `compiler.ll`
and `compiler_runtime_division_provider.ll` names outside this migration; their
34/35 and 64/65 selected aliases therefore stayed untouched.

All 1,300 planned input paths independently matched their original SHA-256
after migration. Both mutation reports verified all five current integrity
manifests. The accepted final compiler generations, source snapshots, commands,
reports, diagnostics and other holds remain. Exactly 66 obsolete manual holds
were removed, leaving 517. There is no pending mutation journal.

The installed collector is ReleaseFast, SHA-256
`8f03ed3acd66c36c6e6832e634a2674e327707c85ec82b7430b0f482714eade4`.
All 162 cleanup tests pass in Debug and ReleaseFast, along with eight CLI checks.
Task-owned build scratch was removed after checking ownership, links, hashes,
metadata and readers under both locks: 774 files, 468,873,216 allocated bytes.
That scratch was created during this task and is excluded from the existing
payload savings above. The large inventory tables were compressed and verified
against their uncompressed hashes; the task evidence directory is about 14 MiB.

Final main-checkout inventory: **91,359,010,816 bytes (85.085 GiB)**, down from
126,266,855,424 bytes (117.595 GiB). The measured storage reduction is
34,907,844,608 bytes (**32.510 GiB**); the difference from payload accounting
includes newly retained audit records and directory allocations. The inventory
observed 1,696,495 paths, no vanished entries and no foreign-device entries.

Of the remaining space, 18.115 GiB is covered by current contracts and
66.970 GiB still needs investigation. No further files currently qualify for
automatic collection. This is not a conclusion that all remaining files are
necessary. The largest unresolved family is executables (22,818,287,616 bytes).
Small repeated inputs have a theoretical 780,451,840 bytes of duplicate
allocation across 83,282 names, including source fixtures; they were inventoried
but are outside this generated-input migration.

Evidence:

- Held products:
  `local-state/retirements/automatic-storage-cleanup/1794648371578868863-1352816/report.json`
- Input migration:
  `local-state/retirements/automatic-storage-cleanup/1794648857693195014-1360406/shared-input-review.json`
- Final inventory:
  `local-state/retirements/automatic-storage-cleanup/1794649658752532842-1379413/inventory.json`
- Qualification, commands, original input hashes, compressed inventory hashes,
  retained-alias review and totals:
  `local-state/storage-cleanup/held-products-20261114/`
