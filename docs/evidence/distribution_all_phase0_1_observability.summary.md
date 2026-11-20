# Distribution-All Phase 0-1 Observability Interlude

schema_version: 1
date: 2026-07-14
directive: post-`INBOX-44` scheduled infrastructure interlude
target: `x86_64-unknown-linux-gnu`
status: pass

Implementation identity before validation: committed baseline `f9eb5b71` plus
staged gate-infrastructure tree
`4557af159c2709649ba17097928c5b7a8bf5d5a0`. The staged production/test diff
has SHA-256 `78a5bafae897a53b7b26050aad7538e2c1913c71a73494a09ae21c5c00f9ee97`.

Changed subsystem: `distribution-all` gate/cache infrastructure. The runner
now reports stable gate IDs, runner-visible command inputs, declared cache
telemetry contracts, and successful child exit status. Canonical comparison
schema 2 validates every gate lifecycle and compares all semantic child output
while removing only declared timing/cache observations and normalized run
paths.

Tier-3 trigger: the validation-tier routing table requires full distribution
plus one same-state fresh/cache comparison for gate/cache infrastructure.

Exact commands and intended evidence outputs:

```text
/usr/bin/time -f wall_seconds=%e -o tmp/distribution_all_phase0_1_fresh.time zig build distribution-all -- --fresh-real-rows > tmp/distribution_all_phase0_1_fresh.log 2>&1
/usr/bin/time -f wall_seconds=%e -o tmp/distribution_all_phase0_1_cached.time zig build distribution-all > tmp/distribution_all_phase0_1_cached.log 2>&1
zig run tools/compare_distribution_all_logs.zig -- tmp/distribution_all_phase0_1_fresh.log tmp/distribution_all_phase0_1_cached.log
```

Prior evidence cannot be reused because every accepted full-gate log predates
the stable input records, explicit reported-versus-unreported cache contracts,
child-exit records, gate-inventory record, and schema-2 full semantic-output
comparison. Per policy, this implementation state receives exactly one fresh
run and one cached run unless a relevant input changes.

## Acceptance Result

Both invocations passed all 17 subgates. The forced-fresh run reported three
explicit AIR-export cache misses; the same-state cached run reported three
hits with the same cache keys and descriptor sizes. The other 14 gates all
declared `cache_contract=unreported` and reported
`cache_observation_unreported_subgates=14`. Thus the historical
`cache_status=none` count means **no child cache telemetry**, not a demonstrated
cache miss or lack of Zig compiler caching.

Canonical comparison schema 2 validated each unique gate ID's complete
input/start/end lifecycle, successful child exit, all child output records,
the 17-gate inventory, and the terminal success record. It compared 1,258
semantic records after removing only declared timing/cache observations and
normalizing repository/scratch paths:

```text
summary distribution-all-equivalence schema_version=2 expected=tmp/distribution_all_phase0_1_fresh.log actual=tmp/distribution_all_phase0_1_cached.log gates=17 canonical_records=1258 semantic_match=true local_fail=0
```

The first comparator invocation failed before reading either log because
Zig 0.16 did not resolve the cwd directory handle through `Dir.realPath`.
Changing only the comparator startup to `realPathFile(".")`, rerunning its
four unit tests, and rerunning the comparison closed that focused defect. No
runner, child gate, raw log, or semantic input changed, so the expensive pair
was not repeated. The final staged production/test tree after that correction
is `fee56f38cdfca5ee9b153471b35cd6aa3f6f183c`; its diff has SHA-256
`cd3df82bc2d66c2f3d92f564b02a585b21609d0bdc55f17893ad991f9ee4700a`.

## Timing And Inputs

Every gate now records its stable ID, tool and arguments, target, runner
(`zig-run`), runner-visible input scope (`runner-command`), declared cache
contract, and fresh/default cache mode. The cache mode is an observation
control and is intentionally excluded from semantic equivalence; the other
input fields are compared.

| Gate ID | Fresh ms | Cached ms | Fresh cache | Cached cache |
| --- | ---: | ---: | --- | --- |
| `selected-object-suite` | 53,945 | 54,958 | unreported | unreported |
| `selected-object-inspection` | 2,316 | 2,316 | unreported | unreported |
| `selected-native-link` | 3,887 | 3,844 | unreported | unreported |
| `selected-native-probe` | 3,780 | 3,815 | unreported | unreported |
| `zig-source-native-link` | 29,351 | 28,849 | unreported | unreported |
| `integrated-object-postopt` | 141,559 | 140,739 | unreported | unreported |
| `integrated-object-preopt` | 567,557 | 574,223 | unreported | unreported |
| `integrated-object-ir-writer` | 82,254 | 83,748 | unreported | unreported |
| `integrated-object-release` | 95,164 | 96,265 | unreported | unreported |
| `real-rows-release-fast` | 955,496 | 378,928 | miss | hit |
| `real-rows-release-safe` | 1,003,501 | 402,988 | miss | hit |
| `real-rows-release-small` | 805,142 | 335,361 | miss | hit |
| `integrated-executable` | 2,065 | 2,068 | unreported | unreported |
| `release-object-inspection` | 93,669 | 93,986 | unreported | unreported |
| `release-native-link` | 94,166 | 94,995 | unreported | unreported |
| `release-native-probe` | 93,972 | 94,965 | unreported | unreported |
| `boundary-gates` | 764 | 795 | unreported | unreported |

| Measurement | Forced fresh | Cached |
| --- | ---: | ---: |
| Actual suite wall time | 2,268.35 s | 1,678.60 s |
| Summed child duration | 4,028.588 s | 2,392.843 s |
| Concurrent-duration overlap (sum minus wall) | 1,760.238 s | 714.243 s |

The three real-row gates execute concurrently. Consequently the timing
summary's `total_duration_ms` is accumulated child duration, not suite wall
time. The previously cited newest full-gate value near 39 minutes was also a
summed-child value. This run's cached child sum is 39.88 minutes while its
actual wall time is 27.98 minutes; those numbers must not be compared as the
same metric. Fresh-to-cached wall savings are 589.75 seconds (26.0%), with the
ReleaseSafe real-row mode defining the concurrent batch's critical path.

Fresh log: `tmp/distribution_all_phase0_1_fresh.log`, SHA-256
`86687111c4000f6413bfac57608b4fbadb1bc0a6ab0daaf03b713b0fc889e6f8`.
Fresh wall-time record: `tmp/distribution_all_phase0_1_fresh.time`, SHA-256
`f5eb67cd5d56858c8bb5a6474c32fb5faecd2deef6fc343f2f6788cb7e5b71d4`.

Cached log: `tmp/distribution_all_phase0_1_cached.log`, SHA-256
`6749f2fd6d34e9c8f45885a09a04d6becb95992a86591e260333ef4e94327268`.
Cached wall-time record: `tmp/distribution_all_phase0_1_cached.time`, SHA-256
`ad141ead3486a52cc884499728ef8ae4a18d813247186e09e37788393eefe4b1`.

## Phase 1 Decision

decision: **no-go / deferred**

The Phase 1 threshold requires evidence that repeated tool compilation and
startup consume at least 10% of cached wall time, currently 167.86 seconds, or
another approved material absolute cost. This cycle still does not isolate
that cost. The 14 `unreported` observations cannot be counted as misses, and
the measured wall is dominated by child gate work: preopt integrated objects,
the concurrent real-row critical path, postopt integrated objects, and the
three release-source-owned gates. Replacing nested `zig run` calls therefore
has no evidence-backed 10% claim.

Do not begin compiled-tool reuse, a gate manifest, broader caching, or new
concurrency work from this result. If infrastructure optimization is revisited,
the next measurement must isolate compile/startup from tool execution for the
dominant gates before authorizing Phase 1. Return to the INBOX-44 capability
ranking; its normalized i6/i7 comparison pipeline remains the recommended
next bounded implementation, pending direction.

Focused validation:

```text
zig test tools/run_distribution_all_gates.zig
All 3 tests passed.
zig test tools/compare_distribution_all_logs.zig
All 4 tests passed.
```
