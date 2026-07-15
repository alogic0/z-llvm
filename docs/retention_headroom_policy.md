# Retention And Disk-Headroom Policy

status: proposed-for-review; cleanup unauthorized
directive: `INBOX-59`
date: 2026-07-15

This policy covers the repository's per-INBOX/per-run temporary artifacts,
the semantic AIR-export cache, and the patched-Zig build-local cache. It does
not authorize deletion, rename, rotation, pruning, sharding, or a gate run.
Every cleanup requires a separate explicit user authorization after review of
the current live-pin and would-remove manifests.

## Readiness classes (revised 2026-07-15, user-directed)

There are two independent readiness classes. Serial single-process Tier 3 and
parallel sharding have different storage risk and therefore different
thresholds. A fresh `df` and a report-only retention inventory precede either.
The policy reports six fields: `serial_ready`, `serial_required_start`,
`serial_projected_peak`, `sharding_ready`, `sharding_required_start`,
`sharding_projected_peak`.

### Serial Tier-3 readiness

A single-process serial `distribution-all` may start when a fresh observation
satisfies:

```text
serial_retention_reserve = max(32 GiB, ceil(filesystem_size / 20))
serial_start_required     = serial_retention_reserve + projected_serial_incremental_peak
starting free bytes      >= serial_start_required
```

For the current filesystem the retention reserve is about 49.1 GB (5%) and the
provisional serial incremental peak is **8 GiB** (about 4 GiB for one AIR
generation / cache-miss footprint plus about 4 GiB for serial scratch and
temporary duplication), so `serial_start_required` is about 57.7 GB. Current
free space is about 90-93 GB: **serial-ready**. The INBOX-56 fma cumulative
Tier 3 completed cleanly at this level, proving feasibility for the present
topology; it did not measure high-water disk use, so the next serial Tier 3
records free space before each subgate and the minimum observed free, then
replaces the provisional 8 GiB with
`max(measured_serial_peak * 1.25, measured_serial_peak + 4 GiB)`.

Serial operating rules:

- only one Tier-3 process at a time; no concurrent sharding, AIR export,
  patched-Zig rebuild, or other cache producer;
- fresh `df` plus a report-only retention inventory before starting;
- a tmp soft-limit excess remains a warning, not an automatic blocker;
- if free space falls below the retention reserve, do not start another child
  subgate and fail closed;
- a cache-pin or topology change expected to create extra generations must
  raise the projected peak before launch;
- no cleanup is authorized implicitly.

One successful run proves feasibility for the present topology, not unlimited
safety; each serial gate needs its own fresh preflight.

### Parallel sharding readiness

Parallel sharding retains the stronger condition and remains **deferred**:

```text
starting free bytes >= ceil(filesystem_size / 10) + projected_sharding_peak
```

The ten-percent floor (about 98.2 GB) must remain free at the projected peak;
merely reaching it before starting is insufficient. The provisional parallel
peak is **16 GiB** (at most four bounded shards, each a ~4 GiB envelope from the
healthy three-mode AIR-export footprint), so `sharding_required_start` is about
115.4 GB. Current free (~90-93 GB) is below that, so **sharding is not ready**;
z_llvm-owned reclaimable (~2.8 GB) cannot close the gap. Freeing non-z_llvm
space or a further reviewed revision is required before sharding.

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
