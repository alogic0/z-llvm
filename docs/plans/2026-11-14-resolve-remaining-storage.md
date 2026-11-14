# Resolve remaining storage consumers and duplicated inputs

Status: completed reviewed pass; the remaining cases below need further review.

The starting inventory contains 78.286 GiB, with 56.361 GiB still unresolved.
Investigate concrete consumers and historical retention decisions rather than
using the unresolved label as a deletion rule.

1. Review the largest copied inputs and their aliases. Share identical immutable
   inputs while preserving their names and bytes; retain active holds and verify
   every current checksum contract before and after migration.
2. Review historical pins on ordinary completed build products. Transition only
   individually identified references whose binary consumers are closed. Preserve
   the original records and exclude current contracts and exact replay inputs.
3. Investigate the remaining large traces, records and temporary workspaces.
   Record their actual consumer or the precise missing proof for retirement.
4. Apply qualified changes, verify retained contracts, record actual space saved,
   close task scratch, inventory again and commit the code and result.

Evidence root: `local-state/storage-cleanup/remaining-storage-20261114/`.
Any qualification uses managed commands in an isolated owner under
`local-state/tmp/remaining-storage-build/owner/`. The launcher places compilers,
test products and private caches in that owner's temporary workspaces. Keep the
terminal reports and diagnostics in the evidence root, then remove task-owned
scratch after qualification and installation. Native cleanup transaction records
remain under `local-state/retirements/automatic-storage-cleanup/`.

Retained exceptions: current manifests, independent holds, unique inputs and
raw traces without verified semantic audits. These need a named consumer or a
separate reviewed transition; age or a historical reference alone is not a
permanent-retention decision.

## Findings and implementation

- The largest copied inputs were three AIR exports. The collector now supports
  explicitly listed `.air`/`.ll` inputs in validation, input and cache storage,
  including shallow legacy paths. Sharing preserves all names and bytes and
  excludes only generic policy-root protection. Independent holds and consumers
  still block changes. Seven old inode groups were shared, preserving ten paths
  and reclaiming **3,925,946,368 net allocated bytes**; 17 held groups and their
  182 paths remain unchanged.
- Historical cleanup sibling lists pinned completed binaries after their use
  ended. The reviewed-product format now accepts exact manifest/reference/target
  transitions. Original manifests remain, current contracts cannot be waived,
  and unfinished records or changed evidence fail closed. The first reviewed
  group removed **33 files / 123,703,296 bytes**. A separate Fibonacci review
  removed **five files / 435,032,064 bytes**, including three old compilers;
  the accepted arithmetic-slice compiler remains.
- The two self-rebuild captures have terminal producer evidence under the
  original report's `self_rebuild_invocations`, which the auditor previously
  ignored. It now binds their separate build command and exact captures,
  rejecting reused outputs and warmup/help commands. Both streams pass full
  semantic validation: **135,024 and 4,763,096 event records**.
- Preparing separate retirement requests for these streams created a cycle:
  each retained the other's raw stream as a sibling. Compatible requests now
  become one release retaining both audits. Retained identities preserve all
  their roles, including a receipt that supplies both source and build evidence.
  Different producer/proof identities remain separate; every raw artifact still
  needs its own qualification and all independent retention guards.
  The resulting collection removed both traces, reclaiming **1,468,473,344
  bytes**. Twelve exact historical references were transitioned; the original
  manifests, audits and source/build/input evidence remain unchanged.
- All **3,599 unaliased object-store files / 678,174,720 bytes** are referenced
  by committed artifact manifests. They are archived inputs/results/diagnostics,
  not object-store orphans. The old 326,066,176-byte instruction census has no
  current code consumer found, but its original acceptance seal still pins it.
  The 1,263,316,992-byte `v854` trace belongs to an interrupted run with return
  code -9 and no terminal backend report; it needs a diagnostic disposition.

`remaining-purpose-review.md` under the evidence root records these consumers
and release conditions, the remaining seven throughput workspaces, and a
breakdown of historical cleanup records. It does not classify all leftovers as
necessary. Failed initial test/audit/preparation attempts and their diagnoses
remain in `qualification-disposition.md`.

## Result and qualification

The collection reclaimed **5,953,155,072 bytes (5.544 GiB)** of existing payload:
ten input paths retain shared immutable contents, and 38 obsolete compiled
products plus two audited raw traces are gone. The final inventory contains
**78,136,582,144 bytes (72.770 GiB)**, down from 78.286 GiB. The observed net
reduction is 5,922,713,600 bytes; new audit records and other allocation changes
account for the difference from payload savings.

All 196 cleanup tests and 17 event-auditor tests pass in Debug and ReleaseFast.
Reviewed-product CLI checks passed in both modes, and the general CLI suite
passed. The installed ReleaseFast tools match the qualified sources. Formatting
and diff checks pass. The final integrity check verifies all six current
manifests, 512 retained identities, ten shared inputs and four accepted external
artifacts. All 517 manual holds and the policy are unchanged.

Seven qualification workspaces and the isolated owner's bootstrap were removed
after their evidence was promoted with byte comparison. Their 851,050,496 bytes
were created by this task and are excluded from existing-payload savings. There
is no remaining task scratch or pending cleanup transaction.

[The tracked result](../evidence/remaining_storage_cleanup_20261114.json) records
the exact inventories, collection receipts, plans, original evidence hashes,
test logs, installation identities and integrity check.

## Remaining decisions

The final inventory still labels **54,594,428,928 bytes (50.845 GiB)** unresolved;
that is not a finding that all those bytes are needed. The strongest concrete
follow-ups are:

1. Give the interrupted `v854` trace a diagnostic disposition, preserving its
   failed outcome and useful failure evidence rather than claiming a successful
   semantic audit.
2. Review the 17 independently held duplicate input groups and their consumers
   before sharing them. Review exact replay consumers for the seven remaining
   throughput workspaces separately.
3. Transition the historical instruction census and archive object manifests
   only after checking their accepted summaries and unique diagnostic inputs.
4. Compact repeated cleanup reports and inventories while preserving referenced
   per-file and source/compiler proof records.

The native final review has no eligible automatic deletions. Future cleanup
must resolve these particular contracts rather than broadly ignoring historical
pins or treating an unsuccessful search for consumers as deletion authority.
