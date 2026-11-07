# Large-function selection performance

Status: implementation, repeated measurements and focused validation pass;
full acceptance is pending. The active
[plan](../plans/2026-11-07-large-function-selection-performance.md) uses the
accepted Fibonacci and language-reference migration programs. Raw evidence is
under `local-state/validations/large-function-performance-20261107/`.

## Change and semantic contract

Shared identifier comparisons previously parsed both names on every call.
Temporary-name generation scans parameter, block and instruction-result names;
several successful legalizers repeatedly invoke it for large functions.
Reachability also uses the same comparison helper.

`identifiers.eql` now validates identical spellings once and immediately rejects
different unquoted spellings unless both could be numbered slots. Quoted names,
hexadecimal escapes and numeric aliases retain the existing decoded comparison.
Malformed spellings remain invalid even when compared with themselves. Reference
walkers still need supported spellings before interpreting inequality as proof.
See the [identifier contract and upstream mapping](../ir_identifiers.md).

The temporary-name scans themselves remain unchanged. There is no name cache,
new allocator, skipped legalizer, search-order change or workload-specific rule.
This small shared change is sufficient to investigate the measured parsing cost
without introducing state into normalization or selection.

New tests compare every ordered pair across eighteen spelling classes and
exercise malformed strings, numeric overflow, quoted numeric names, escaped
bytes, prefixes and generated names. A selector integration test preserves
collisions with quoted parameter/block/result names and the first free serial.
All thirteen focused identifier/temporary-name tests pass.

## Diagnostic attribution

Both compilers use ReleaseFast. Inputs are the retained Safe captures from the
accepted Zig-input milestone. The initial baseline runs include one warm-up and
three fresh processes per program; all objects and ownership sidecars match the
accepted capture. One profiled baseline/candidate comparison then isolates the
only production change: seven lines in the shared comparison helper.

| Safe input | Baseline total | Candidate total | Legalization before/after | Reachability before/after |
| --- | ---: | ---: | ---: | ---: |
| Fibonacci | 27.15 s | 17.50 s | 10.16 / 2.46 s | 2.65 / 0.76 s |
| migrate_langref | 29.68 s | 18.78 s | 10.53 / 2.58 s | 3.85 / 1.25 s |

These are diagnostic samples, not the repeated performance result. Every
non-timing profile field matches, including all per-function/per-legalizer
counters and allocation totals; object and ownership bytes are identical.
Selection remains about 14 seconds in each program. The evidence attributes
the observed reduction mainly to legalization and reachability, without
attributing all of it specifically to temporary-name generation.

## Acceptance protocol

The repeated comparison alternates accepted and final compilers, with a warm-up
per compiler/input. Safe uses five timed runs per compiler/program; Fast and
Small each use three. Each sample is a fresh process with profiling disabled.
Wall time, CPU time and peak RSS are retained. Profiled comparisons separately
check all six input/mode combinations. Project builds and tests do not overlap
the measurements; the desktop host is not otherwise isolated.

Required validation includes Debug/Safe units, policy, structural checks,
captured objects, ABI, compilation routes, readiness, both unchanged programs
with independent ownership replay, and all 17 integration gates on a frozen
revision. Existing execution populations and admission/reserve thresholds stay
unchanged. Compiler throughput and generated-program performance are separate
claims; this change must preserve generated object bytes.

## Repeated measurements

The accepted ReleaseFast compiler is
`129cbf907f9fb264e2a930a6206ba7035f3a59d10a53661ad6181293fc2dab0f`;
the final ReleaseFast compiler is
`28962d94a9c832f56098273a55ae92fbe809598f3eb5e670e29b475c1ba53a4a`.
The host is an AMD Ryzen 7 7840HS running Linux, with Zig 0.17.0. Input modes
below describe the retained program IR; both compiler binaries use ReleaseFast.

| Program / input mode | Runs per compiler | Baseline median (range) | Final median (range) | Median time reduction |
| --- | ---: | ---: | ---: | ---: |
| Fibonacci / Safe | 5 | 26.59 s (26.43–26.64) | 16.91 s (16.90–16.96) | 36.4% |
| Migration / Safe | 5 | 29.13 s (28.88–29.26) | 18.68 s (18.61–18.71) | 35.9% |
| Fibonacci / Fast | 3 | 0.07 s (0.07–0.07) | 0.07 s (0.07–0.07) | unresolved |
| Migration / Fast | 3 | 17.65 s (17.59–17.83) | 12.94 s (12.83–12.98) | 26.7% |
| Fibonacci / Small | 3 | 0.07 s (0.07–0.07) | 0.07 s (0.06–0.07) | unresolved |
| Migration / Small | 3 | 5.56 s (5.55–5.56) | 4.04 s (3.99–4.07) | 27.3% |

Safe median CPU time falls from 26.58 to 16.90 seconds for Fibonacci and from
29.12 to 18.66 seconds for migration. Median peak RSS is effectively unchanged:
239,124 / 239,272 KiB for Fibonacci and 241,660 / 241,964 KiB for migration
(baseline / final). This is a CPU-work improvement, not a memory-saving claim.
The 10 ms timer resolution limits the short Fast/Small Fibonacci measurements.

All 44 timed samples preserve accepted object and ownership bytes. All twelve
profiles (baseline/final across six input/mode combinations) preserve every
non-timing field, including allocation totals. Raw distributions and comparisons
are retained in `measurements.json`, `measurement-comparisons.json` and
`profile-comparisons.json`. These local results do not establish a speedup for
other hosts, other programs or generated machine code.

## Focused validation

The frozen 2,971-file source snapshot was verified after the focused run.
Debug and ReleaseSafe each pass 1,915 unit tests and 30 policy tests. All
19 structural checks, 38 captured objects, 60 ABI comparisons, compilation-route
checks and readiness pass. Readiness includes 6,528 behavioral observations and
the existing LLVM comparison for quoted/escaped symbol identity.

Both unchanged programs pass Fast, Safe and Small, with independent ownership
replay in all six program/mode combinations. Migration passes all 87 input/mode
pairs and 603 observation controls. Its independent observations and selection
counters also match the previous accepted corpus. All thirteen original scratch
files are unchanged. The full 17-gate run is still required before promotion.
