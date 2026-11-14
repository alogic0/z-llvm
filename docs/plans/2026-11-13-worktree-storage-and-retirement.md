# Worktree storage ownership and historical retirement

1. Separate the source checkout from the storage owner. Managed launches must
   publish evidence and temporary workspace records under the owner's existing
   validation roots, even when compilation runs in a sibling Git worktree.
   Reject unmanaged output paths before creating output or launching a child.
   Preserve explicit cache overrides as caller-owned storage.
2. Qualify external-source jobs, nested tools, failed runs, invalid output paths,
   and collection through the owner. Test with an actual sibling-worktree shape.
   Install the qualified ReleaseFast collector and document future invocations.
   Existing running jobs retain their original inputs and output paths.
3. Review the executable families from the last purpose inventory (29.60 GiB),
   checking terminal receipts, active consumers, baseline pins and aliases.
   Collect only proven obsolete products; ordinary binaries do not need new
   source/configuration archives.
4. Review the unresolved raw traces (9.48 GiB) against exact audit, producer,
   input, compiler and source identities. Retain traces without that proof.
5. Record tests, applied retirements, exact reclaimed allocation, retained
   blockers and a fresh inventory. Commit the source changes and review results.

Initial inspection found the active qualified-behavior worktree using the same
workspace code as main, but its `local-state/isolated-validations-*` paths bypass
the managed scope. Main storage measured 147,808,153,600 allocated bytes; the
sibling's local-state added 13,226,483,712 bytes. Both jobs and source checkouts
must be distinguished from the storage owner; using current tool sources alone
does not establish managed storage.

## Implementation and qualification

Explicit `ZLLVM_STORAGE_ROOT` ownership now controls workspace paths, leases,
job receipts and completion collection independently of `ZLLVM_PROJECT_ROOT`.
The managed launcher requires owner-relative validation output. Nested tools
inherit that requirement; source paths and symlink escapes are rejected before
output creation. External job working directories are identities, not deletion
scopes. Explicit cache overrides remain caller-owned.

The first real sibling canary passed and exposed a completion issue: its
waiting `zig run` launcher still named the finished run, correctly causing the
collector's active-consumer guard to defer collection. The launcher now builds
the checked runner under a lock and execs it directly. Its child command and
recorded source working directory are unchanged.

Qualification: all 127 collector tests pass in Debug and ReleaseFast. The full
ReleaseFast storage suite passed all ten build steps. After the launcher change,
eight targeted worktree CLI checks passed, including real Git-worktree fixtures,
nested ownership, failed-run retention, unmanaged paths, symlink escapes,
source preservation and automatic launcher completion collection.

Evidence is recorded in `local-state/storage-cleanup/worktree-storage/`.

## Historical review

The fresh guarded review admitted nine completed compiler binaries
(921,272,320 allocated bytes) and thirteen raw traces (2,184,843,264 bytes).
Four of the compilers needed exact transitions of completed retirement-ledger
references; current manifests were not transitioned. Existing reconstruction
ledgers supplied the trace source bindings and were checked against the original
build hashes, Git blobs and saved files. No compiler rebuild or new source
archive was needed.

The review covered 31 present compiler builds and 14 trace requests. Other
compiler candidates have accepted-baseline pins, live holds, external aliases,
or a receipt/hash mismatch. The 1,463,066,624-byte worker-medium trace has two
hardlinks, one in the original compiler run and one in an unchanged rebuild's
capture directory. Its audit and source proof qualify, but the single-file raw
trace collector cannot retire that alias group. Both names remain intact.

The trace inventory found 65 names under unresolved buckets. A fresh audit
verified 37 of 38 streams with standalone producer/top/backend bindings; one
producer was not terminal. Of those 37, fourteen had a recorded build and a
guarded compiler-retirement chain. Eleven lacked a recorded build and twelve
lacked a suitable original-compiler retirement chain. Another 27 names use
capture or other layouts requiring owner-specific binding; some are aliases,
so these counts must not be added as unique allocated bytes.

Large executable families still include extensionless test programs such as
`local` and `reference`, copied `zig-out/bin/z_llvm` products lacking matching
build receipts, and readiness caches without supported recorded ownership.
These are review cases, not a claim of ongoing necessity. They need a bounded
producer/output adapter or individual ownership proof; broad deletion by file
extension would bypass that distinction.
