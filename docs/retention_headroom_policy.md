# Artifact retention and disk headroom

Updated 2026-11-03 for the user-authorized storage simplification and cleanup.
Historical frozen INBOX roots and the exact 43-worktree inventory are retired.

## Retained state

- `local-state/artifacts`: verified immutable objects and retained run manifests.
  All local manifests are pins; accepted copies are tracked under
  `docs/evidence/artifacts/`. Use the artifact-store dry-run/apply collector.
- Schema-2 AIR export cache generations have been removed: the current reader
  accepts schemas 3 and 4. Retain a new generation only for active fresh/cache validation
  or near-term reuse with matching inputs.
- `local-state/inputs/real-candidates-v3`: checked semantic facts for the frozen
  offline membership audit, bound by the versioned fact manifest. Retain these
  facts and the original static classification inventory for audit replay.
- `tmp/o2_calls_perf`: the existing performance tool still reads adopted inputs
  and its baseline checkout here. Keep until that consumer is migrated.
- The udivmoddi4 null-pointer diagnostic is pinned by
  `diagnostic-udivmoddi4-20260910.json`: original IR plus compiler configuration.
  Its regenerable compiler cache and empty/failed output objects are removed.
- `../ziglang`: patched source/emitter and their required build state. This is a
  compiler dependency, not an artifact-store cleanup target.

The exact current exceptions are listed in `docs/evidence/tmp_retention_pins.tsv`.
A historical document reference or superseded pin is not an indefinite keep rule.
Retained source and evidence removed from old run directories can be located by
name in the manifests and retrieved with `artifact-store get`.

## Generated run cleanup

Before removing an old run, preserve unique source edits/commits and the minimum
source/log/input evidence necessary for accepted results or unresolved failures.
Discard reproducible build binaries, cache generations, and verified duplicate
AIR exports. Exclude active processes and runs. Record the classified paths,
retained evidence, remaining exceptions, and measured physical space reclaimed.
Do not create a permanent duplicate archive of the original run trees.

Remove idle compiler caches as complete owned roots, including their object
and manifest directories together. Keeping manifests after removing only the
referenced objects can leave stale compiler-cache entries. Preserve final
outputs, captured inputs, logs and measurements outside those cache roots;
the next build recreates the cache.

The [2026-11-02 cleanup](evidence/space_cleanup_20261102.json) records the
retirement of the superseded selector-v2 failed-run exports and idle compiler
caches. The authenticated accepted exports and the separately frozen selector
inputs remain pinned. Equal file sizes do not establish duplicate content.

The [export-generation cleanup](evidence/startup_headroom_cleanup_20261103.json) retires
the superseded export/execution generation after its replacement fresh run
passed and all replacement hashes were verified. The accepted generation now
lives under `local-state/caches/startup-headroom-20261102`. That checkpoint kept
the frozen raw audit inputs; their later semantic migration is recorded below.
Historical metadata, logs and source probes remain.

The [scalar frame-store cleanup](evidence/scalar_frame_cleanup_20261103.json)
preserves all paths and hashes while hardlinking 228 byte-identical immutable
IR/native evidence files. It retires six superseded debug compiler copies from
completed refactor comparisons and removes complete idle caches. Current AIR,
original scratch probes, performance baseline compilers, captured inputs and logs
remain. Cache deletion intervals include rebuilt caches; do not sum them as net
task savings. No archives are created.

The [scalar startup cleanup](evidence/scalar_startup_cleanup_20261103.json)
retires superseded non-performance executable copies and resolved exploratory
hello captures while retaining final captures, diagnostics and commands. It also
removes an unregistered 2,465-file source copy after verifying that every file
exactly matches Git revision `56e66794`. The local reconstruction manifest records
paths, modes and blob hashes. Original probes, current performance baselines,
current/frozen AIR, accepted evidence and sibling dependencies stay outside this
retirement. Complete idle build caches are removed in separately recorded
intervals; regenerated caches are not counted as net savings. No archives are
created.

The [audit fact migration](evidence/candidate_facts_retention_20261103.json)
retains 74 MB of signatures, counts, reference effects, defined-result facts and
typed-body hashes. Every raw-derived function fact matches in all three modes;
the normal builder reproduces the entire 21,117-row candidate table byte-for-byte,
every selected mode fact and all 1,863 raw/fact rejection identities. The old
audit's rejection count also matches. The versioned
[fact manifest](evidence/real_candidates_release_v3_facts_manifest.json) binds
payload hashes, raw parent identities and the static inventory. It is the current
offline replay entrypoint; historical raw paths in old evidence record provenance.

The three historical payloads had six hardlink paths under `test-real-rows` and
`current-pin-20261102`. All six paths are retired after verification; metadata and
retirement records remain. Distinct raw allocation falls by 3.92 GB and the new
fact inputs use about 74 MB, for a 3.85 GB retained-input reduction. Current
production AIR under `startup-headroom-20261102`, source probes and performance
baselines stay pinned. No archives are created. See the
[replay command](build_steps.md) for checking the adopted inputs.

Use unique run-owned directories for new work. Successful temporary tests clean
up their own fixtures. A failed test may retain a bounded diagnostic fixture,
but it must report that location and must not turn it into a test prerequisite.

## Headroom

The runner's numerical headroom checks remain owned by
`tools/distribution_headroom_policy.zig` and
`tools/distribution_real_rows_parallel_policy.zig`. Storage simplification does
not change these integration execution budgets. Check current free space before
full integration and reuse matching evidence rather than repeatedly rebuilding
unchanged inputs. The obsolete `clean-tmp` INBOX classifier and its fixture are
retired; use the artifact-store collector for objects and classify other generated
roots against the current keep-list before removing them.

The [headroom calibration](evidence/headroom_calibration_20261102.json) replaces
the coarse 4.419 GB forecast with 8 GiB: a 25% margin over the retained 6.05 GB
fresh-run free-space decrease, rounded upward to a whole GiB. The serial reserve
remains the larger of 32 GiB and 5% of filesystem capacity. Nested row workers
inherit that reserve while running, and their transient minimum enters the
serial report before cleanup. The
[combined checkpoint](evidence/startup_headroom_acceptance_20261103.json)
passes both full 17-subgate runs with all 1,396 canonical records matching.
Sampled fresh/cached global decreases are 6.10 GB and 1.60 GB, within the forecast;
the reserve remains enforced independently.

The serial parent records its original admission. Row workers validate that
record's filesystem, starting free space, reserve and forecast, then consume the
remaining allowance rather than demand the entire forecast a second time.
Their monitor still enforces the inherited reserve. Standalone workers continue
to require a complete initial allowance. Telemetry reports the admission source
and original admitted free space separately from the row group's starting space.

Row telemetry schema 3 measures allocated bytes across the parent scratch root,
three work roots and three export roots. It includes retained cached payloads;
it does not identify every byte as new allocation. Filesystem free-space changes
also include unrelated processes, and sampled observations are not atomic
snapshots. Keep these scopes separate when comparing forecasts and measurements.
