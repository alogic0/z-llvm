# Retire completed validation runs

Status: two reviewed cleanup executions complete; next unresolved groups recorded.
Requested by the user on 2026-11-13.

## Objective and starting measurements

Retire temporary outputs from completed experiments, keeping compact accounting
records and verified replay evidence only where the retained conclusion needs it.
Account for retained storage explicitly; do not describe unsupported
or unassessed history as necessary or minimal.

The preceding read-only inventory measured 150.4 GiB in `local-state`, of which
143.9 GiB was in validation directories. The behavior suite accounted for
89.8 GiB and the selection suite for 27.3 GiB. Raw event streams across the
validation directories occupied 30.3 GiB in 91 unique inodes; that is a subset
of the validation total, not an additional amount or a deletion authorization.
Concurrent work can change these measurements.

## Retention contract

User clarification during execution: ordinary old compiler/test binaries and
object files are temporary. Do not reconstruct or archive their build
configuration or source merely to delete them. The collector now has a
`disposable` release state for closed build outputs; original artifact hashes,
current pins, queued holds, active use and guarded mutation still apply.
Existing records can remain without making full replay preservation a condition
of disposal. Completed private compiler caches use the same rule: their passed
producer and exact cache-directory ownership suffice without preserving sources
or the compiler. Current baselines and investigations needing an exact executable
remain protected. This supersedes the earlier rebuild-evidence requirement for
ordinary binaries; audited raw traces retain their separate evidence contract.

Keep active and queued dependencies, adopted baselines, unique unresolved
failure diagnostics, and the source/input/toolchain/command/result evidence
needed to reproduce retained conclusions. Preserve source revisions or verified
reconstruction records for replay-qualified trace releases; ordinary disposable
build outputs need their existing producer receipt and artifact hashes only.
Every retained large file must have a specific consumer, investigation,
reproduction requirement, or explicit unresolved question.

Historical checksum references need explicit per-file retirement transitions.
A transition must bind the original manifest, exact target and original hash,
and the applicable owner release. It must never exempt a current integrity
manifest or an unrelated file. Source mismatches remain blockers for operations
that claim preserved replay; disposable binaries do not require source replay.
No duplicate archive of deleted run trees is created.

## Execution sequence

- [x] Inspect real historical build/source records and current holds. Select
  supported evidence families from the largest completed behavior runs first.
- [x] Extend the tracked collector to verify historical source reconstruction
  and canonical build receipts. Add precise historical pin transitions with
  regression coverage for changed evidence and current-manifest protection.
- [x] Qualify the changes in Debug and ReleaseFast and exercise the actual
  release/review/apply workflow on temporary fixtures.
- [x] Publish verified release records and retire eligible completed artifacts
  in bounded batches. Recheck current integrity manifests and retained evidence
  afterward; record physical file allocation reclaimed without double-counting
  hardlink aliases. Review the selection suite and identify the remaining trace
  evidence gaps for subsequent batches.
- [x] Give producers a supported way to publish completed-run evidence and
  releases; integrate cleanup into the appropriate producer lifecycle without
  changing compilation outcomes or discarding unique failure diagnostics.
- [x] Report the remaining storage as required now, eligible, or unresolved,
  with byte counts and specific reasons. Set a working budget from measured
  requirements and preserve the existing disk-headroom admission rule.
- [x] Update this plan with implementation, validation, actual cleanup results,
  and any remaining concrete evidence gaps. Commit the tracked changes.

## Verification and completion

All applicable collector checks remain in force: owned paths, active readers,
queued holds, source and input identities for replay-qualified releases, immutable controls, aliases,
cross-release retained dependencies, and guarded mutation. A completed cleanup
batch must leave no pending mutation and must preserve required current
manifests. Repeating collection must be safe and account for new producer work
separately from prior removals.

Success means both verified historical reductions and a reusable lifecycle for
future completed runs. Unknown files remain explicitly unresolved. The final
report must distinguish measured reclaim from theoretical candidates and must
not infer that every surviving byte is essential.

## Execution record

- Plan saved before implementation. Repository was clean at `955f9fe6`.
- Implemented canonical receipt/source verification for audited traces, exact
  per-file pin transitions, producer release commands, staged batch reviews and
  inode-aware whole-tree accounting. No deletion had occurred when the user
  clarified that old binaries do not need reconstruction evidence.
- The initial fresh inventory accounted for 1,663,152 paths: 22,438,195,200
  bytes required by current contracts, 2,229,936,128 eligible, and
  140,861,800,448 unresolved. These are observations during concurrent work,
  not a proof of the minimum working set.
- The first strict review qualified 83 older isolated compiler outputs and two
  audited canonical traces after 52 exact historical pin transitions. Following
  the user's clarification, rebuild this batch as disposable build requests so
  source mismatches alone cannot retain ordinary temporary binaries.
- Rebuilt the batch from 85 older behavior compiler reports and 12 selection
  receipts with present binaries. The bound review and 85 precise historical
  pin transitions qualify 89 binaries (9,143,136,256 allocated bytes), six private
  caches (255,291,392 bytes) and two audited traces (1,888,923,648 bytes).
  These are pre-apply figures; fresh holds and concurrent work can change them.
  Seven selection binaries remain pinned and one has an artifact hash mismatch.
- Added a regression for the collector incorrectly recognizing its own
  `release-build` command as a consumer. Only its own PID is excluded; other
  processes, including parent jobs, remain protected. All 65 native checks pass
  in Debug and ReleaseFast. All 14 isolated CLI checks pass, including actual
  deletion, repeated collection, disposable publication without sources,
  maintenance leases, failed-job protection and publication failures.
- Committed the implementation as `7c6d0062`. The first apply completed 11
  removals, reclaiming 2,508,615,680 allocated file bytes, including both traces.
  It was then stopped at a verified read-only consumer-check boundary with no
  pending mutation; completed action records remain intact. A fresh apply
  rediscovers the remaining disposable binaries. Local restart evidence is in
  `local-state/storage-cleanup/completed-run-qualification/collector-restart.md`.
- Fixed mixed batches coupling disposable removals to another action's replay
  environment. Only actions whose contract requires replay recheck Git revisions
  and toolchain libraries. Hashes, controls, pins, holds and guarded removal
  still apply to every action. All 66 native checks pass in Debug and ReleaseFast,
  and all 14 isolated CLI checks pass after this correction.
- Retired the cleaner's own completed qualification cache after its tests ended
  and a scoped consumer check found no users: 449,220,608 allocated bytes,
  including directory allocation. Qualification logs remain; no source or build
  configuration archive was made for those temporary test binaries.
- The next apply completed 51 more removals (5,173,702,656 allocated file bytes)
  before the other agent changed `holds.json`. The collector stopped with
  `FileChanged` and no pending mutation. Its completed records remain valid;
  a new invocation starts with the new holds. The updated helper is committed
  as `5e69a93d`.
- A subsequent pass completed 19 removals (1,919,676,416 allocated file bytes),
  including two newly closed caches outside the original batch, before another
  hold update stopped it without a pending mutation. The remaining 18 historical
  binaries are handled by a new invocation with the latest holds. These stops
  are retained in the reports rather than relabeled as complete passes.
- The final pass completed all 18 remaining removals, reclaiming 1,770,500,096
  allocated file bytes, and reverified all five current integrity manifests.
  A fresh repeated apply found zero eligible candidates and removed nothing;
  all five manifests passed again and no pending mutation remained.
- Retired eight superseded cleanup helpers, reclaiming another 64,032,768
  allocated bytes. The sole remaining helper is the qualified ReleaseFast
  `local-state/storage-cleanup/clean-storage`.

## Verified results of the first execution

| Removed category | Count | Allocated bytes reclaimed |
| --- | ---: | ---: |
| Old compiler binaries | 89 | 9,143,136,256 |
| Complete private compiler caches | 8 | 340,434,944 |
| Audited raw traces | 2 | 1,888,923,648 |
| Collector qualification cache and superseded helpers | 9 roots/files | 513,253,376 |
| **Total** | | **11,885,748,224 (about 11.07 GiB)** |

The original reviewed batch had six private caches. The other two completed
during execution and account for 85,143,552 bytes of the cache total. Collector
records count regular-file allocation; the separately measured qualification
cache includes directory allocation. No hardlink allocation is counted twice.
Concurrent writers mean whole-folder and filesystem free-space changes need not
equal this measured reclaim.

All 85 selected behavior compilers and four selection compilers were removed.
Seven selection compilers remain pinned and one has an output hash mismatch;
the repeat pass also retains 16 private cache roots covered by queued holds.
These are the 24 held candidates, totaling 1,313,607,680 allocated file bytes.

The apply and repeat reports are under
`local-state/retirements/automatic-storage-cleanup/`:

- `1794564726615204666-3385000/report.json`: 11 completed removals; stopped at a verified read-only boundary.
- `1794565125136332044-3433930/report.json`: 51 completed removals; stopped after a hold change.
- `1794566308521906905-3459795/report.json`: 19 completed removals; stopped after a hold change.
- `1794566819220651797-3471013/report.json`: 18 completed removals; complete.
- `1794567380590377679-3490531/report.json`: repeated apply; complete, zero removals.

Completed action records reconcile to the totals above even where the enclosing
pass was interrupted. Qualification logs, the restart observation and the
`jqz` aggregation are under `local-state/storage-cleanup/completed-run-qualification/`.

The final inventory at
`local-state/retirements/automatic-storage-cleanup/1794567509443891881-3494523/inventory.json`
observed 1,686,873 paths and 1,676,723 unique inodes, with no vanished entries or
foreign-device entries and all current manifests verified:

| Disposition | Allocated bytes |
| --- | ---: |
| Required by current contracts | 24,976,994,304 |
| Eligible under the current supported releases | 0 |
| Unresolved | 133,233,025,024 |
| **Remaining total** | **158,210,019,328 (about 147.3 GiB)** |

Zero eligible files does **not** mean minimal storage. About 124.1 GiB remains
unresolved, including unsupported report families and history still needing
purpose review. The largest filename/mode families are executables
(55,211,532,288 bytes), raw traces (30,662,504,448 bytes), and compiler inputs
(24,126,558,208 bytes); these classifications do not prove necessity.

## Remaining investigations and operating budget

Second execution, requested by the user: investigate the remaining file groups,
review the 37 closed compiler builds, establish ownership of legacy private test
caches, and examine the large trace/input/record families. Extend the reusable
collector where a verified lifecycle is missing. Keep current holds and baselines,
record concrete reasons for unresolved files, and collect newly verified
temporary outputs under the existing authorization.

The [remaining-storage investigation](2026-11-13-remaining-storage-investigation.md)
records the second execution's concrete purposes, completed removals and fresh
verification. It removed 56 compiler binaries, 74 complete private caches and
18 freshly audited raw traces: **34,524,938,240 allocated file bytes
(32.154 GiB)**, plus about 0.38 GiB of completed tool scratch space. A repeated
apply removed nothing, all five current integrity manifests passed, and no
pending mutation remained. The earlier 21.15-GiB trace catalog described files
already retired by `strong-trace-cleanup-20261113`; that history is explicitly
excluded from the new reclaim totals.

The unclassified executable allocation includes private native-test caches such
as `sign-extension-units-v1035/evidence/zig-local-Debug-v1039`. Its run receipt
records relative cache arguments and a failed terminal test, without a working
directory. The new private-cache adapter binds an explicit review of the legacy
working directory and exact private cache arguments, with current holds and
diagnostics preserved. Whole owned caches were removed, including manifests;
source reconstruction was not required. New receipts record actual cwd.

Next prioritize integrated/native comparison outputs, generated assembly and
immutable input deduplication, then review noncurrent expected-binary manifests
and remaining legacy trace bindings. Current manifests and explicit queued
holds continue to protect their targets. The collector now authenticates a
retired compiler through its completed guarded removal and unchanged original
build receipt. Raw trace auditing retains its separate evidence requirement.

A read-only follow-up also identified 37 present compiler outputs from passed
behavior builds v800–v967. Their candidate list is
`local-state/storage-cleanup/completed-run-qualification/later-present-builds.txt`.
All 37 passed fresh release/pin/consumer review and were removed in the second
execution. The original list remains historical evidence, not a live inventory.

The first large batch exposes a latency limitation: refreshing the full
historical pin graph and consumer checks before every artifact makes historical
collection slow. Profile that path before expanding large batches. Preserve
fresh discovery, alias checks and newly introduced pins when optimizing it;
small producer-completion batches remain the preferred steady-state workflow.

The latest full inventory reports **121.410 GiB**, comprising **28.423 GiB**
under current contracts and **92.988 GiB unresolved**. Do not impose an arbitrary
total-size cap while these purposes and contracts remain unresolved. Current
protection is a review starting point, not a proven minimum. The operating limits remain
20,000,000,000 bytes of free space for admitting serial validation, its existing
8 GiB working allowance, and at most 32 GiB reclaimed per collector invocation.
Refresh whole-tree accounting after each batch and retain explicit unresolved
categories until their consumers or retirement rules are established.
