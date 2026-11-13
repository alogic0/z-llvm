# Complete the storage cleanup workflow

Status: findings recorded; the policy and integration changes below are pending.

The initial collector has guarded removal, pin checks and provenance validation,
but its first real apply run reclaimed zero bytes. Its source and tests belong
in Git; generated inventories, logs, binaries and local retirement records stay
under ignored `local-state/`.

## Findings from 2026-11-13

The default 24-hour idle rule held all 96 discovered private-cache roots. Their
cache/report changes were about 1–7 hours old when inspected. The day-long wait
was an implementation choice, not a condition required by the previous manual
cleanup workflow.

A review-only comparison disabled that delay and raised the candidate cap for
counting. All other source/build, hash, pin, consumer, link and mount checks
remained enabled:

- 94 of the original 96 candidates passed, totaling 3,996,217,344 allocated
  regular-file bytes (3.72 GiB).
- With four newer caches included, 98 of 100 passed, totaling 4,166,381,568 bytes
  (3.88 GiB). The first 64 ready candidates totaled about 2.53 GiB.
- Two caches for the v825 Debug build remained held: two of its 642 recorded
  source hashes disagreed with the source tree. Compiler and toolchain hashes
  matched. These integrity failures must remain blocking.

The original cache roots occupied about 3.81 GiB including directory blocks,
only 2.54% of the contemporaneous 150.03-GiB `local-state` footprint. The rest
was outside this candidate set; the collector had not established whether that
storage was needed or safe to retire.

There were no `storage-release.json` records. Production tools do not yet write
them, and existing audit, reconstruction and owner decisions are not converted
into them. Requiring a distinct passed successor also excludes some previously
approved trace retirements that preserved failed outcomes, complete audits,
replay sources, inputs, commands and diagnostics.

## Required changes

1. Define an appropriate cache-specific lifecycle rule for completed private
   builds. Keep evidence, current pins, active/queued consumers and fresh
   mutation checks; do not let a blanket day-long delay substitute for them.
2. Integrate the existing audit and reconstruction formats with release records,
   and wire production lifecycle decisions to their creation. A record must
   state exactly which outputs are obsolete and which evidence remains.
3. Represent reviewed historical failures without inventing passed successors.
   Full trace audits, replay bindings, retained diagnostics and valid ownership
   release remain necessary; age or missing pins alone are insufficient.
4. Report held bytes and ages separately from unassessed storage. The current
   early `TooRecent` return leaves metadata unset and byte counts at zero, hiding
   the size of the held pool and any subsequent provenance failures.

## Acceptance checks

Keep the existing 37 isolated tests and three CLI checks passing in Debug and
ReleaseFast. Add regressions for the lifecycle policy and each adopted evidence
format. A completed private cache should qualify when its approved lifecycle
permits removal; busy, queued, pinned or changed candidates must remain held.
Source mismatches must never be waived to increase reclaim totals.

Use a fresh review before any apply, preserve exact source/build/result/hash
evidence, and verify current integrity manifests afterward. A review must
distinguish eligible, held, unsupported and unassessed storage. The observations
above are a dated diagnostic result, not a reusable deletion authorization.

Detailed local records are under
`local-state/storage-cleanup/investigation-20261113-0635/`. This tracked summary
preserves the findings without committing those generated artifacts.
