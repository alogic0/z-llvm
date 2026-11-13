# Retire completed validation runs

Status: in progress. Requested by the user on 2026-11-13.

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
- [ ] Publish verified release records and retire eligible completed artifacts
  in bounded batches. Recheck current integrity manifests and retained evidence
  afterward; record physical file allocation reclaimed without double-counting
  hardlink aliases. Then review the selection suite and remaining raw traces.
- [x] Give producers a supported way to publish completed-run evidence and
  releases; integrate cleanup into the appropriate producer lifecycle without
  changing compilation outcomes or discarding unique failure diagnostics.
- [ ] Report the remaining storage as required now, eligible, or unresolved,
  with byte counts and specific reasons. Set a working budget from measured
  requirements and preserve the existing disk-headroom admission rule.
- [ ] Update this plan with implementation, validation, actual cleanup results,
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

## Remaining investigations and operating budget

The unclassified executable allocation includes private native-test caches such
as `sign-extension-units-v1035/evidence/zig-local-Debug-v1039`. Its run receipt
records relative cache arguments and a failed terminal test, without a working
directory. The isolated-compiler adapter does not establish ownership for this
format. Verify its producer working directory and lifecycle before adding a
test-cache adapter; source reconstruction is not needed for temporary outputs.
Remove whole owned caches, including manifests, rather than individual objects.

Next review the selection suite's noncurrent accepted/expected-binary manifests,
the one mismatched compiler identity, and raw traces whose original compilers
have already been retired. Current manifests and explicit queued holds continue
to protect their targets. Raw trace auditing has a separate evidence requirement
from binary disposal.

A read-only follow-up also identified 37 present compiler outputs from passed
behavior builds v800–v967. Their candidate list is
`local-state/storage-cleanup/completed-run-qualification/later-present-builds.txt`.
They still need explicit requests and fresh pin/consumer review; the list itself
does not authorize removal and version order alone does not establish disuse.

Do not impose an arbitrary total-size cap while 131.2 GiB in the initial full
inventory remains unresolved. The measured 20.9 GiB under current contracts is
a review starting point, not a proven minimum. The operating limits remain
20,000,000,000 bytes of free space for admitting serial validation, its existing
8 GiB working allowance, and at most 32 GiB reclaimed per collector invocation.
Refresh whole-tree accounting after the batch and retain explicit unresolved
categories until their consumers or retirement rules are established.
