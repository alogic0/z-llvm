# Minimize existing local-state after storage separation

Status: completed, 2026-11-14. Existing payload reclamation: **3.922 GiB**.
Final observed allocation: **85.978 GiB**, down from **89.822 GiB**.

The user approved the three priorities from the fresh 89.82-GiB review:
close completed throughput storage, review unresolved compiled products, and
reduce redundant evidence and repeated inputs. This is an explicit retention
review; an unresolved file or old timestamp is not deletion authorization.

1. Verify the completed throughput acceptance and terminal consumers. Review
   its 48 managed workspaces (2.73 GiB), full artifact seal and identity lists.
   Preserve inputs, source, results, diagnostics and still-needed replay
   dependencies. Transition only reviewed temporary references into historical
   identities, with a replacement manifest covering every maintained reference.
   Close the finished broad hold and release eligible workspaces; preserve all
   independent holds and current contracts.
2. Review the 20.69-GiB unresolved executable/object/cache family, starting with
   the largest remaining groups. Use native closed-owner and alias adapters;
   ordinary temporary outputs do not require new source/configuration archives.
   Collect qualified products and record concrete remaining blockers.
3. Review large redundant records/logs and repeated compiler inputs. Prefer
   lossless compaction of unbound discovery tables and verified immutable-input
   sharing. Do not discard unique failure evidence or unaudited event streams.
4. Verify maintained contracts, absence of pending mutations and unrelated hold
   preservation; remove task-owned scratch, record gross reclamation and a fresh
   inode-counted inventory, then commit the reviewed lifecycle changes/results.

Starting inventory:
`local-state/retirements/automatic-storage-cleanup/1794681650803679748-2166149/inventory.json`.
It records 96,446,066,688 allocated bytes: 31,300,997,120 under current contracts
and 65,145,069,568 unresolved. These categories are review scopes, not guaranteed
savings or proof of permanent necessity.

## Storage for this pass

- Maintain compact decisions, reviewed lists, hashes, before/after controls and
  collection summaries in `local-state/storage-cleanup/minimization-20261114/`.
  Native collector transaction records remain under its standard retirement root.
- Native tools reuse their owned bootstrap caches. Any necessary task-specific
  build cache will use `local-state/tmp/minimization-build/`, be declared in the
  local retention note, and be removed after qualification.
- Existing large payload stays in place until a verified transition and guarded
  collection. No new payload archive is required for ordinary compiled products.
- Existing accepted compiler generations outside this checkout remain outside
  this cleanup. This task does not start the proposed preopt compiler milestone.

## Reviewed ownership and qualification

The completed throughput cycle had 48 workspaces. Its original 64,529-entry
seal was verified before separating 8,475 temporary references from 56,054
maintained references. A replacement current manifest preserves every maintained
entry and also binds the original seal and unchanged acceptance JSON. Only this
cycle's broad hold was closed; the other 517 manual holds remain. Three compiler
workspaces still support retained build/trace evidence, and four object
workspaces have independently maintained aliases. Those seven remain retained.

The legacy cache survey found 413 report/command-ledger pairs. The new native
`prepare-command-caches` adapter prepared 211 requests; 180 entries had no present
explicit cache binding, 16 lacked a passed owner, and six lacked acceptable
diagnostic-retirement proof. The guarded review qualified 1,533 private caches
(1,054,392,320 allocated file bytes). Another 841 caches remain pinned by existing
retirement records or validation manifests. Detailed reasons and sizes are in
`blocked-cache-and-workspace-bytes.ndjson` under this pass's evidence root.

Managed workspaces now use the existing guarded tree-batch transaction. It
admits at most 128 roots within the existing 1-GiB and file-count bounds, retaining
the single-large-root allowance. Tests exercise collection of twenty workspaces,
rollback of all twenty on a fresh hold or pin, and changed-evidence rejection.
This avoids repeating the project-wide retention scan for each empty workspace.

The cache/workspace implementation passed 181 tests in both Debug and
ReleaseFast, command-cache CLI argument/collection checks, and eleven workspace
CLI checks. Collection used qualified ReleaseFast binary
`6695b4dfb79ed17966c7e0aa8d471772040425a34efc70bdd96b7eec3c344a8e`.
Commands, diagnostics, receipts and source identities are retained in
`qualification-bounded/` and `qualified-sources.txt`. The earlier 178-test version
also passed the general collector CLI suite. Task-owned qualification pipelines
were collected after installation and evidence promotion; remaining bootstrap
scratch was removed after verifying ownership and unchanged membership.

Qualification exposed an explicit-owner fallback in common project discovery:
an owner without project markers could resolve to its parent project. The
collector now rejects that mismatch before reading policy or creating state.
The regression fails against the original collector; the fix passes the
command-cache/root checks and all eleven workspace CLI checks in both Debug
and ReleaseFast. The installed ReleaseFast binary is
`c63831ac284f673a2d458be4a6aa9560cdfe283f3b33b630037668653098533f`.
The mutation modules and their 181-test qualification remain unchanged by this
startup check. Evidence is in `qualification-root-guard/` and
`root-guard-original-negative.log`.

The IR survey hashed 837 large inodes and checked all 10,215 observed hardlink
names. Sharing migrated 52 unheld inode groups, preserving their bytes and names;
17 held groups remained untouched. It reclaimed 826,875,904 bytes and created
131,276,800 bytes of shared objects: **695,599,104 net bytes (0.648 GiB)**.
All six current integrity contracts passed. Four derived discovery tables from
this pass were losslessly compressed, avoiding 60,612,608 bytes of audit overhead.
Existing path/hash-bound logs and retirement records were retained.

The remaining review boundaries, including custom Fibonacci/compiler receipts,
shell-built census helpers, existing replay dependencies and record/log roles,
are documented in `reviewed-boundaries.md` under the evidence root. Unresolved
storage remains a review pool rather than a claim of permanent necessity.

## Completed collection and final verification

| Existing data | Result | Allocated file bytes reclaimed |
| --- | --- | ---: |
| Completed throughput scratch | 41 workspaces removed; seven retained with named reasons | 2,460,893,184 |
| Closed legacy compiler caches | 1,533 private caches removed | 1,054,392,320 |
| Duplicate immutable IR | 52 inode groups shared, net of new shared objects | 695,599,104 |
| Total existing payload | No double-counting of new shared objects or task scratch | **4,210,884,608** |

The completed collection is
`local-state/retirements/automatic-storage-cleanup/1794684390755304789-2227235/report.json`.
It removed 39 workspaces and 1,533 caches in bounded transactions; two empty
workspaces had already been removed by the earlier collector before its
intentional stop at a boundary without a pending transaction. The
[throughput retention record](../evidence/compiler_throughput_storage_20261114.json)
binds both receipts, the unchanged acceptance and historical seal, the new
current manifest, and the exact retired and retained workspace references.
The sharing receipt is
`local-state/retirements/automatic-storage-cleanup/1794683614926942706-2205696/shared-input-review.json`.

Task-owned cleanup is accounted separately: four qualification workspaces
(517,308,416 bytes) and two bootstrap scratch sets (237,330,432 bytes) were
removed. The 60,612,608-byte discovery-table reduction also concerns data created
during this pass, so none of these amounts inflate the existing-payload total.
No task build scratch or pending mutation remains.

Final integrity verification passed all six current manifests and four accepted
external artifacts. The original throughput acceptance and seal are unchanged,
and all 517 unrelated manual holds remain. The installed collector and qualified
source hashes match. The verification is recorded in
`local-state/storage-cleanup/minimization-20261114/final-integrity.json`.

The final inode-counted inventory is
`local-state/retirements/automatic-storage-cleanup/1794685867846654759-2257826/inventory.json`:
92,318,474,240 allocated bytes across 1,758,768 paths and 1,749,567 unique inodes.
The measured decrease is 4,127,592,448 bytes (3.844 GiB); audit creation and
concurrent development affect this net footprint. The inventory-only command
had no deletion candidates, so its `current_integrity_verified:false` means it
did not run integrity checks; the separate final verification above did.

The remaining 85.978 GiB comprises 21.925 GiB classified under current contracts
and 64.053 GiB unresolved. Closing the broad throughput hold changes these
classifications; an unresolved category does not imply data was newly created
or may be deleted. The next useful review is the explicit historical pins and
custom helper receipts described in `reviewed-boundaries.md`, followed by
duplicate input groups whose external aliases or holds prevented sharing.
