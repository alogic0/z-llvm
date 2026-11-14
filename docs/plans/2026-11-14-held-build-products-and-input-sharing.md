# Review held build products and repeated compiler inputs

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

Implementation, collection and final accounting are in progress. Results and
exact net savings will be recorded after guarded mutation and verification.
