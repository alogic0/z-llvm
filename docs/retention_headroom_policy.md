# Retention And Disk-Headroom Policy

status: proposed-for-review; cleanup unauthorized
directive: `INBOX-59`
date: 2026-07-15

This policy covers the repository's per-INBOX/per-run temporary artifacts,
the semantic AIR-export cache, and the patched-Zig build-local cache. It does
not authorize deletion, rename, rotation, pruning, sharding, or a gate run.
Every cleanup requires a separate explicit user authorization after review of
the current live-pin and would-remove manifests.

## Sharding readiness

Sharding may start only when a fresh filesystem observation satisfies:

```text
starting free bytes >= ceil(filesystem bytes / 10) + projected sharding peak
```

The ten-percent floor must remain free at the projected peak; merely reaching
the floor before starting is insufficient. Until a measured sharding run
replaces it, the conservative incremental peak is **16 GiB**: at most four
bounded shards, each with a 4 GiB scratch envelope. The per-shard envelope is
the current healthy three-mode AIR-export footprint (about 4.01 GB) rounded
up. A design proposing more concurrency or a larger shard must raise the peak
before it can be considered ready.

At the INBOX-59 observation:

- filesystem size: `982240026624` bytes;
- free space: `93332955136` bytes;
- ten-percent floor: `98224002663` bytes;
- projected peak: `17179869184` bytes;
- required starting free space: `115403871847` bytes.

The system is **not ready for sharding**. The would-remove manifest estimates
`2795765275` logical bytes as candidates, yielding projected free space of
`96128720411` bytes after cleanup and `78948851227` bytes after the peak. Even
that optimistic cleanup projection remains `19275151436` bytes short of the
required starting headroom. Logical sizes can overstate filesystem blocks
actually reclaimed, so readiness must always use a fresh `df` after an
authorized cleanup, never the projection alone.

## Per-INBOX and per-run `tmp/`

- A short-lived run directory is protected for two hours from its newest
  content modification. Two hours is a candidacy threshold, never an automatic
  deletion timer.
- A per-INBOX build cache, install prefix, or reproduction directory becomes a
  candidate only when its INBOX is accepted and its newest content is at least
  24 hours old. The 24-hour interval is the short acceptance grace period.
- The active cycle and the latest accepted capability checkpoint remain
  protected regardless of age. For this checkpoint those are INBOX-59 and the
  accepted INBOX-56 fma artifacts.
- Explicit diagnostic pins always win. In particular,
  `tmp/udivmoddi4_ptr_null_cache` remains protected because the accepted
  INBOX-57 ADR depends on its frozen capture.
- A path mentioned by documentation is not pinned. Live retention pins exist
  only in
  [`docs/evidence/tmp_retention_pins.tsv`](evidence/tmp_retention_pins.tsv),
  with a reason and pin/key for every entry.
- Unclassified temporary directories are protected for manual review; the
  reporter does not guess that they are reproducible.
- The repository `tmp/` soft limit is 8 GiB. Crossing it triggers a report and
  headroom review only. It never triggers automatic age-only deletion or
  gate-triggered pruning.
- Cleanup must not run while a producer or consumer process has the candidate
  path open. Process-use inspection is repeated immediately before any future
  authorized cleanup.

## `real_rows_air_export_cache`

Retention is based on semantic cardinality, not age. Preserve exactly one
complete current-Zig-pin/current-exporter pair for each of `ReleaseFast`,
`ReleaseSafe`, and `ReleaseSmall`, even when those three pairs are large.
Old-pin pairs, incomplete meta/AIR pairs, and duplicate current-mode pairs are
candidates. The present three complete pairs occupy about 4.01 GB and are the
healthy footprint, not a cleanup target.

The semantic key is the tuple `(ziglang_pin, z_llvm_export_state, mode)`. A
candidate report must expose all known tuple fields and must fail closed on
missing metadata.

## Patched-Zig build cache

The located cache is the project-dedicated
`/home/oleg/prog/ziglang/.zig-cache`. Retain the current accepted Zig pin and
at most one previous known-good generation. The current opaque cache layout is
not safely separable by pin, so this cycle protects the whole current cache and
proposes no hash-entry deletion. Future Zig rebuilds should use distinct
per-pin cache roots; after that migration, whole obsolete generation roots can
be proposed instead of deleting opaque entries.

If a future cache trace resolves to a shared cache, it is report-only by
definition. It cannot appear as reclaimable and requires a separately scoped
policy and explicit authorization.

## Reporter and cleanup boundary

`tools/clean_tmp.zig --retention-report` is deterministic for a fixed
`--now-seconds` and filesystem observation. It sorts entries by path and emits
path, class, logical size, age, pin/key, status, reason, regeneration cost,
reclaimable bytes, and headroom projections. The mode rejects `--delete`.

The tracked result is
[`docs/evidence/inbox59_would_remove.tsv`](evidence/inbox59_would_remove.tsv).
It is a proposal only: `candidate` means eligible for review, not permission to
remove. The report-only fixture proves that a candidate sentinel remains
byte-for-byte present. No Tier 2, Tier 3, distribution-all, or sharding gate
was run.

INBOX-59 is acknowledged. Stop and request review plus explicit user
authorization before any cleanup.
