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

For the current filesystem the retention reserve is about 49.1 GB (5%) and
the initial provisional serial incremental peak was **8 GiB** (about 4 GiB
for one AIR generation / cache-miss footprint plus about 4 GiB for serial
scratch and temporary duplication), so the initial `serial_start_required`
was about 57.7 GB. The INBOX-56 fma cumulative Tier 3 completed cleanly at
this level, proving feasibility for the present topology; it did not measure
high-water disk use, so the next serial Tier 3 records free space before each
subgate and the minimum observed free, then replaces the provisional 8 GiB with
`max(measured_serial_peak * 1.25, measured_serial_peak + 4 GiB)`.

INBOX-63 supplied that measurement across the same 17-subgate topology, with
the three real-row modes serialized: starting free `119978582016`, minimum
sampled free `119854436352`, and final free `120229638144` bytes. The sampled
serial peak was `124145664` bytes. The formula is therefore governed by the
4-GiB additive margin and refines `projected_serial_incremental_peak` to
`4419112960` bytes. With the current `49112001332`-byte reserve,
`serial_start_required` is now `53531114292` bytes (about 53.5 GB). This is a
topology estimate from child-boundary samples, not permission for parallel
sharding or an unbounded cache-producing run.

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

The machine-readable serial policy authority is
`tools/distribution_headroom_policy.zig`. Both the tracked serial
`distribution-all` runner and the report-only retention inventory consume that
authority; reserve, projected-peak, and required-start values are not copied
into the runner. The runner initializes its minimum-free measurement from the
first real sample, then records preflight, every subgate boundary, final free
space, and the observed peak.

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
115.4 GB. The INBOX-63 serial Tier-3 per-subgate samples observed roughly
119.9 GB free (starting `119978582016`, minimum sampled `119854436352` bytes),
which now exceeds the 115.4 GB threshold. Sharding is nonetheless **NOT
automatically authorized**: the required fresh `df` plus report-only retention
inventory for a sharding preflight has not been performed, and no directive
authorizes it. The stale ~90-93 GB figure is superseded; sharding remains
deferred pending its own fresh preflight (and, if the observation regresses,
freeing non-z_llvm space or a further reviewed revision).

For the authorized INBOX-68 bounded preopt run, the machine-readable sharding
authority is `tools/distribution_headroom_policy.zig`. It defines the ten-percent
floor, the 16-GiB projected peak, and their required-start sum. The preopt
orchestrator samples free space while workers are active and fails closed if
runtime free space falls below the floor; this authority does not authorize
general subgate parallelism or concurrency above two.

INBOX-69 supersedes that activation: tracked gate 7 is unsharded again. The
only authorized parallel topology is the fixed ReleaseFast/ReleaseSafe/
ReleaseSmall real-row group. Its independent machine-readable authority is
`tools/distribution_real_rows_parallel_policy.zig`; it does not reuse the
preopt 16-GiB estimate. The initial projected disk peak is 8 GiB, combined with
the ten-percent filesystem floor, and the minimum available-memory threshold
is 8 GiB. The runner verifies three cache hits before launch, pins the shared
AIR descriptors read-only, suspends pruning, gives each mode separate local and
global Zig caches, and samples free space plus aggregate process-tree RSS while
children run. The focused concurrency-three runs observed peak group-root disk
usage of 539,158,368 bytes. The existing
`max(measured_peak * 1.25, measured_peak + 4 GiB)` margin is governed by its
additive branch, refining the projected peak to 4,834,125,664 bytes and the
current required start to 103,058,128,327 bytes. This does not authorize a
fourth worker or another parallel subgate.

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

`--retention-cleanup` reuses that classifier for a single-tool cleanup
workflow. It is a dry-run by default and reports `would-delete` for candidates.
Deletion requires the additional explicit `--delete` flag. Delete mode
recomputes the classification from the live filesystem, preserves explicit
pins, the active and unaccepted INBOXes, the acceptance grace window,
unclassified paths, current export-cache mode pairs, the patched-Zig cache,
and any tree containing a `.git` worktree marker. It also requires `lsof` and
fails closed if a candidate path is open. This capability does not itself
authorize a cleanup; the user must still approve the reviewed dry-run.

The tracked result is
[`docs/evidence/inbox59_would_remove.tsv`](evidence/inbox59_would_remove.tsv).
It is a proposal only: `candidate` means eligible for review, not permission to
remove. The report-only fixture proves that a candidate sentinel remains
byte-for-byte present. No Tier 2, Tier 3, distribution-all, or sharding gate
was run.

INBOX-59 is acknowledged. Stop and request review plus explicit user
authorization before any cleanup.
