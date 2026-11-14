# Address-dependency owner removal: compiler throughput

Date: 2026-11-14
Status: passed; implementation `7e7a1063`.

The [acceptance record](compiler_throughput_20261114.json) binds the source,
compiler binaries, nineteen successful terminal receipts and artifact seal.

The selector's infallible address-owner removal now compacts its owned records
directly. Empty dependency replacements take that path before constructing a
speculative replacement. Nonempty replacements retain their validation and
failure atomicity; transaction rollback, capacities, ABI and frame policies are
unchanged. Borrowed owner names are resolved before compaction.
The current domain occupies 149,761 bytes; removal avoids its clone and copy-back.

The baseline hardware recording for the complete fixed Debug behavior input
contains 23,115 user-space cycle samples, no reported losses and decoded caller
stacks. `memcpy` accounts for 41.01% of self samples. Caller views locate copying
in transaction snapshots and owner removal on binding writes. This slice changes
only owner removal; larger snapshot/liveness changes remain separate work.

## Measured result

Pinned tooling Zig 0.17.0 builds both backends in ReleaseFast, targeting
x86_64 Linux GNU with CPU baseline, symbols and frame pointers retained. The
baseline source is `43a509cc`, whose backend source matches accepted `dbf7ade0`.
The candidate is the three-file source patch over `dcb7b033`. Implementation
`7e7a1063fe67b3f814b2244b26a2b0ccefcecc66` contains exactly that qualified delta.

The fixed input has 7,874 definitions and 67,658,559 bytes, SHA-256
`d8b983f4686a19acdf9f5bcc84c084b6fbc68e104e1671032509f7180c9aa02b`.
Hardware and built-in profiling were disabled during throughput measurement.
Both variants warmed up once, followed by three pairs in the order
baseline/candidate, candidate/baseline, baseline/candidate. No qualification
builds overlapped these measurements; per-run load and pressure are retained.

| ReleaseFast backend | Wall seconds, run order | Median seconds | Maximum peak RSS, KiB |
| --- | --- | ---: | ---: |
| Baseline | 113.93, 114.77, 114.39 | 114.39 | 1,329,124 |
| Candidate | 109.62, 110.04, 109.66 | 109.66 | 1,329,008 |

The median reduction is 4.73 seconds, or 4.135% (about 4.1%). Peak memory is
essentially unchanged. All eight runs, including warmups, reproduce the exact
accepted object SHA-256
`4ea9c9b39f5ab18be66f1e6f1293652ce2e9ba68fe93edbf0aad00324954eb2e`
and byte-identical ownership manifests.

This is backend emission throughput for one fixed postopt Debug module. It does
not measure generated-program performance, a complete frontend build, self-rebuild
or whole-compiler throughput. The 120-second compiler and extracted-function
hardware recordings timed out; they are diagnostic samples with no complete
object or speedup credit. The fresh full compiler replay is a correctness check
with event instrumentation and overlapping validation.

## Qualification

- Debug and ReleaseSafe: each 2,365 unit, 65 structural and two profile checks
  passed. Six focused dependency tests plus eight wrapper tests also passed.
- Original runtime under Debug and ReleaseFast backends: all 455 definitions,
  exact accepted object/owners, 21,792 local and 21,792 reference observations
  per backend, including 641 unsigned-division cases across four helpers.
  Each detects all fourteen runtime faults.
- Separate Small runtime: all 503 definitions and exact accepted object/owners.
  All three runtime captures pass independent census/ELF audits. Their complete
  ordered event streams contain 182,330, 182,330 and 192,100 records, respectively,
  with zero failed functions and matching terminal profile counters.
- Complete original compiler replay passes all 8,928 definitions and reproduces
  the accepted 149,620,056-byte object SHA-256
  `d10d05451b6e553a3bbdd364f5709097df2fdfac208f25fb47a27974723cfeef`.
  Ownership is byte-identical. Independent census/ELF and full ordered-event
  audits pass: 6,123,234 records, zero failures and matching profile counters.
- All 17 integration gates pass. Each complete Debug/ReleaseFast native suite passes
  all 225 populations across three release pipelines. Its source-verified
  comparison preserves all 8,204 command outcomes and all 3,399 backend artifacts,
  with no additions or differences.
- All 6,696 fresh native faults and 28 runtime faults pass: 6,724 required controls.
  The qualified source snapshot verifies after terminal qualification. The main
  source snapshot verifies after the terminal Tier-3 run, before documentation
  edits. The committed implementation diff matches the tested candidate exactly.

The ignored evidence root is
`local-state/validations/compiler-throughput-20261114/batch-01/`. Build receipts,
fixed inputs, measurement scripts, actual statuses, profiles, audits and failed
attempts are retained there. A queued manual storage hold protects the root.
Important evidence is outside `.zig-cache`.

The first isolated Tier-3 run failed because the frozen compiler-core execution
cohort resolves relative artifacts against the canonical main checkout. Its
receipt and terminated siblings remain failures. A narrow strict ReleaseSmall
reproduction passes all 100 object/link rows and 12 paired executions with the
canonical emitter and required pruning setting. The final standard Tier-3 replay
passes all 17 gates using the canonical checkout, fresh evidence roots and the
same authenticated three-mode AIR exports. No harness checks were relaxed.

Native command comparisons need an explicit checkout-path review because the
old and new source fixtures live under different roots. The retained task-local
Zig projection verifies each affected file against its original fixture-report
hash before replacing its source prefix. It then calls the unchanged maintained
comparison implementation. A complete baseline self-comparison preserves all
8,204 outcomes and 3,399 backend artifacts (1,362 objects, 1,353 owner manifests,
684 optimizer outputs), with 456 source files verified. A changed-source negative
control is rejected as `SourceFixtureChanged`. Both fresh reviewed comparisons
pass the same complete preservation checks. Genuine commands and reports remain
unchanged; the ordinary path-sensitive comparison failures are retained separately.

The completed eight-milestone compiler/self-rebuild plan, fixed acceptance
populations and historical seals remain unchanged. The proposed successor is
the [complete ReleaseSafe behavior suite through local preopt](../plans/2026-11-14-release-safe-preopt-behavior.md),
with optimizer and object stages audited separately and remaining LLVM
dependencies explicit.
