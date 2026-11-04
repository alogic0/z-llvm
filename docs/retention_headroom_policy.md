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

The [symbol identity checkpoint](evidence/symbol_identity_acceptance_20261103.json)
retires 0.81 GB of complete idle project build-cache file allocation before its
full run. Sources, all 13 probes, installed output, current exports and diagnostic
evidence are reverified; shared caches are not deleted. The full cached run
passes all 17 stages with a 31.92 GB reported minimum, above the 24.36 GB floor.
Builds regenerate cache files, so the deletion interval is not net task savings.
No archives are created.

The provisional [attribute-group evidence](evidence/reference_attributes_focused_20261103.json)
is retained under `local-state/validations/opaque-references-20261103` for the
ongoing dependency-reference work. It contains source hashes, the earlier binary's
observed outputs, native IR comparisons, focused validation and the next metadata
plan. The 13 original probes remain unchanged; this slice creates no archives
and retires no caches.

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
passed and all replacement hashes were verified. The accepted generation then
lived under `local-state/caches/startup-headroom-20261102`. That checkpoint kept
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
fact inputs use about 74 MB, for a 3.85 GB retained-input reduction. Audit facts,
current production AIR, source probes and performance baselines stay pinned.
No archives are created. See the
[replay command](build_steps.md) for checking the adopted inputs.

Use unique run-owned directories for new work. Successful temporary tests clean
up their own fixtures. A failed test may retain a bounded diagnostic fixture,
but it must report that location and must not turn it into a test prerequisite.

The [allocation-padding cleanup](evidence/allocation_padding_cleanup_20261103.json)
retires 3.53 GB of fully owned cache-file allocation after compiler processes
finish. Sources, accepted and provisional proofs, performance baselines, current
AIR, audit facts and all 13 source probes remain. Cache allocation and global
free-space movement are recorded separately; no archives are created.

The [global-memory generation cleanup](evidence/global_memory_cleanup_20261103.json)
retires 3.92 GB of superseded AIR payload allocation only after the replacement
passes both full 17-stage runs, all 1,403 canonical records match, and old/new
payload hashes are reverified with no active consumers. Historical metadata,
logs, sources and performance baselines remain. At that checkpoint, production
exports and their paired work selection used `global-memory-headroom-20261103`; the old
`startup-headroom-20261102` cache retains metadata and its retirement record.
No archives are created.

The [array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
records retirement of 1.42 GB of complete idle compiler-cache allocation before
its full run. Captured inputs, final outputs, diagnostics, current AIR and all
13 original probes remain. Builds regenerate the main cache, so this deletion
interval is not net task savings. No archives are created.

The [module selection focused checkpoint](evidence/module_selection_focused_20261103.json)
records removal of 314 complete idle cache roots, totaling 1.39 GB of allocated
space. Most roots were empty retained directories; the main cache and completed
ABI/Fibonacci caches supplied the allocation. Installed output, source captures,
logs, current AIR, measurement inputs and all 13 probes remain hash-verified.
The resulting 41.71 GB free-space measurement was below full-run admission.
At that point, the shared cache outside the project was audited read-only and
left untouched because it had active consumers. No archives are created. Rebuilt caches are not net
retention savings.

The [module dependency acceptance](evidence/module_selection_acceptance_20261103.json)
also records the user's explicit approval to clear `/home/oleg/.cache/zig` once
idle. A fresh file-descriptor/executable/mapping check found no consumers before
removing the complete shared cache. That interval removed 6.74 GB of cache
allocation and measured 48.04 GB free afterward. Installed compilers, source captures,
current AIR and all probes remain hash-verified. No archive was created. Later
builds regenerate shared cache entries; this is an interval measurement, not a
permanent net reduction or a standing instruction to clear other projects' caches.

## Headroom

The runner's numerical headroom checks remain owned by
`tools/distribution_headroom_policy.zig` and
`tools/distribution_real_rows_parallel_policy.zig`. Storage simplification does
not change these integration execution budgets. Check current free space before
full integration and reuse matching evidence rather than repeatedly rebuilding
unchanged inputs. The obsolete `clean-tmp` INBOX classifier and its fixture are
retired; use the artifact-store collector for objects and classify other generated
roots against the current keep-list before removing them.

The [headroom calibration](evidence/headroom_calibration_20261102.json) established
the 8 GiB forecast: a 25% margin over the retained 6.05 GB fresh-run free-space
decrease, rounded upward to a whole GiB. At the user's direction on 2026-11-03,
headroom policy schema 3 lowers the former fixed 32 GiB reserve by exactly
10,000,000,000 bytes (10 decimal GB). It reserves 24,359,738,368 bytes
(approximately 24.36 GB) and keeps the 8 GiB working allowance. Serial admission
therefore requires 32,949,672,960 bytes (approximately 32.95 GB) free, also
10 GB below policy schema 2. This supersedes both the 42.95 GB fixed requirement
and the earlier capacity-based 57.70 GB requirement on this filesystem. Nested workers
continue to inherit and enforce the caller's reserve, including any stronger
caller floor, and their transient minimum enters the serial report before cleanup.
The separate sharding policy is unchanged. The
[focused policy checks](evidence/headroom_reduction_focused_20261103.json) pass
all 51 runner/policy and 41 comparison tests. The accepted
[IR/headroom pair](evidence/ir_headroom_acceptance_20261103.json) passes all 17
stages in both runs, with all 1,406 canonical records matching on one frozen
2,681-file snapshot. Reported fresh/cached decreases are 7.09 GB and 1.97 GB,
within the unchanged 8 GiB forecast. Reported minima are 30.85 GB and 33.65 GB;
independent two-second sampled minima are 30.71 GB and 33.65 GB, above the
24.36 GB reserve. Historical measurements below retain their original policy
values; filesystem noise and non-atomic samples remain measurement limits.

The earlier
[combined checkpoint](evidence/startup_headroom_acceptance_20261103.json)
passed both full 17-subgate runs with all 1,396 canonical records matching under
the previous reserve policy. Its sampled fresh/cached global decreases were
6.10 GB and 1.60 GB.

The [fixed-reserve/global-memory acceptance](evidence/global_memory_acceptance_20261103.json)
passes its own fresh/cached 17-stage pair with all 1,403 canonical records matching
on unchanged implementation inputs. Reported free-space decreases are 5.86 GB
and 2.16 GB, within the 8 GiB forecast. Reported minima are 44.09 GB and 43.31 GB;
independent two-second samples reach 44.02 GB and 43.28 GB. Both remain above the
34.36 GB reserve. The 51 runner/policy and 41 comparison tests pass. These
filesystem measurements do not establish a performance improvement.

The array-stride cached run passes all 17 stages under the same fixed policy.
It starts with 43.97 GB free and reports a 2.11 GB decrease; the reported and
two-second sampled minima both round to 41.86 GB, above the 34.36 GB reserve.
The source snapshot and three authenticated cache hits are verified. No cache
or headroom implementation changed in this compiler checkpoint.

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

The [boolean-call checkpoint](evidence/boolean_call_acceptance_20261103.json)
passes a further 17-stage cached run under the same policy. It starts with
44.90 GB free; the reported minimum is 42.97 GB and the independent sampled
minimum is 42.94 GB. The reported decrease is 1.94 GB, within the 8 GiB
allowance. All three AIR exports are authenticated cache hits and execution
checks run again. The 32 GiB runtime reserve remains enforced.

The [boolean-checkpoint cache cleanup](evidence/boolean_call_cleanup_20261103.json)
retires ten complete idle cache roots after the 17-stage acceptance run. About
1.16 GB of regenerable compiler state is removed. Captured Fibonacci inputs,
the installed compiler, full logs, source snapshots, current AIR, audit facts,
performance baselines and all 13 original probes remain. Open-file and mapping
checks found no active cache consumers. No archives are created.

The module dependency cached run passes all 17 stages with
47.94 GB free at admission. Its reported minimum is
43.72 GB and its sampled minimum is
43.33 GB, both above the 34.36 GB reserve. Three
authenticated AIR exports are reused and execution checks run again. No headroom
or AIR-cache implementation changes are part of this compiler checkpoint.

The [IR serialization focused checkpoint](evidence/numeric_ssa_focused_20261103.json)
records another idle-cache interval after readiness. Project cache roots and two
superseded interrupted-test roots released 2.17 GB; the previously authorized
shared Zig cache cleanup released 0.84 GB after a fresh consumer check. These
are allocation intervals, not cumulative net savings. Source probes, captured IR,
current AIR, installed compilers and retained proofs remain verified. The
artifact-store dry run found no unreferenced objects. The user-revised headroom
admits the planned fresh/cache pair. The earlier pip-cache cleanup proposal is
superseded; no pip cache was deleted. No archives are created.

After the first full IR run failed, its input, log and frozen source snapshot were
retained. The follow-up passes 1,718 units, readiness, structural checks and the
exact failing native case. Before the retry, another complete idle checkout build
cache released 2.35 GB after an open-file and mapping audit. Free space measured
38.06 GB afterward, above the revised 32.95 GB admission requirement. Installed
compilers, captured IR, original probes and the prior accepted AIR remain intact.
The receipt is `local-state/validations/numeric-ssa-20261103/retry-idle-cache-cleanup.json`.
The retry uses a new frozen snapshot and distinct fresh/cache logs; no archives
are created.

The isolated retry passed nine stages before the export worker's canonical
repository working directory disagreed with the caller's relative paths. It
stopped at `FileNotFound`, with a sampled 35.51 GB minimum, above the reserve.
After merging the focused commits, validation moves to `/home/oleg/prog/z_llvm`,
the location required by the current export/execution cohort. The idle checkout
and unpublished failed-run outputs were retired after preserving failure records,
source commits and snapshots, releasing 2.19 GB. The prior accepted AIR and all
13 original probes were preserved during this recovery. See
`local-state/validations/numeric-ssa-20261103/canonical-root-recovery.json`.
No archives are created.

The [IR/headroom cleanup](evidence/ir_headroom_cleanup_20261103.json) retires
3.92 GB of superseded AIR payload allocation after all 17 fresh stages pass,
the source snapshot is verified, and both generations' metadata and hashes are
checked. The initial plan retained both generations through the pair; the fresh
run ended below the cached run's admission threshold, so the old generation was
retired first under the user's obsolete-file cleanup authorization. Historical
metadata and hashes remain, and the new payloads remain unchanged through the
successful cached run and comparison. This cleanup did not clear the shared
tool cache or pip cache. Current exports and paired work selection use
`ir-headroom-20261103`. Two obsolete checkout dependency links are also removed;
the actual dependency repositories, original probes and performance baselines
remain. No archives are created.
