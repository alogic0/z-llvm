# Scalar byte loops and checked strncpy

This slice admits scalar i8 loads/stores in composed x86-64 loops and closes the
retained `compiler_rt.ssp.__strncpy_chk` definition. Retained `compiler_rt.bcmp`
and `compiler_rt.memcmp` now use shared composed lowering instead of structural
fallbacks. Admission remains based on typed IR operations, not function names.

## Return-join repair

Reproduction after removing the scalar acyclic guard selected all three
definitions, but bcmp and memcmp failed machine verification with
`ReturnRegisterUndefined`. Their common return block occurs before the loop
body in emitted order. It defines eax and jumps to a final shared epilogue;
the last emitted loop block does not define eax. The old verifier followed
that last block's state instead of the branches entering the epilogue.

The verifier now recognizes a final label followed only by stack restoration
and `ret`. For a join with incoming branches, it intersects return-register
definitions at every conditional/unconditional incoming branch and includes
any fallthrough predecessor. This supports the shared epilogue regardless of
label spelling. It preserves the existing checks for other joins and the
legacy terminal-trap layout; it is not a general CFG dataflow analysis.

Regressions cover early emitted returns, a later unrelated trap, undefined
incoming branches, conditional branches before definitions, fallthrough and
split SSE aggregate return definitions. An undefined incoming path still
rejects even if a later block defines the return register. No verifier error
is suppressed and no dummy return-register instruction is emitted.

Scalar loops reuse the existing framed parameter/phi homes and value-use
transactions. Byte-vector transfers remain acyclic pending separate proof of
loop-carried XMM ownership. Volatile/atomic memory, nondefault address spaces,
other vector forms and general string-family expansion are not newly admitted.
The frozen source-guard inventory, accepted counters and bypass ratchet are
unchanged.

## Retained definitions and discovery

The [family fixture](../../test/behavioral/byte_loops_family.ll) preserves three
definitions and their attribute groups from
`tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll` byte for byte. The source
SHA-256 is `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1`.

| Definition | SHA-256 |
| --- | --- |
| `bcmp` | `b70d3c5417ff76b120173eac6a5d8360401fb3cad954bdda32772912dabc5c4b` |
| `memcmp` | `0dad4b89eb8ab5aed46d7fbad26b9b2b2da4255acd57009ffb5a1b5f234adc74` |
| `ssp.__strncpy_chk` | `83ee66c191e972af9556c3d5fd5922888f03a908a522af0dfa3da8750054e2fd` |

On the same 443-function discovery population used by the
[memcpy slice](composed_memcpy_family.md), support increases from 269 to 270
emitted definitions, with failures decreasing from 174 to 173. Exactly
`ssp.__strncpy_chk` leaves the failure set; no failure is added and no remaining
diagnostic changes. The already-supported comparison functions change lowering
ownership, not the emitted-function count. These are discovery counts, separate
from the accepted compiler-core and compiler-rt populations.

## Native coverage

`zig build byte-loops-diff` verifies the IR with opt-22 and requires composed
ownership for all three retained functions and four
[compositions](../../test/behavioral/byte_loops_compositions.ll): byte copy, a
loop-carried sum, early-exit zero search and constant-byte fill. Direct and
release-o3 routes each run in ReleaseFast, ReleaseSafe and ReleaseSmall.
Clang-22 compiles the original IR as the independent reference, including when
the local route uses optimized IR.

Each route/mode checks 32,648 observations, for 195,888 total:

- Twenty lengths from zero through 512 and four independent source/destination
  offsets, with six terminator positions and exact/larger destination capacity.
- Correct truncation and zero padding, returned pointers, source preservation
  and unchanged surrounding bytes.
- Equal and differing byte ranges, first/middle/last/out-of-range differences,
  both argument orders and byte values spanning the signed-byte boundary.
- Loop-carried wraparound sums, early exits, copy counts and byte stores.
- Protected-page source boundaries for a one-byte empty string, unterminated
  fixed-length copy/comparison and zero-length calls.

Two invalid bounds per run must trap with SIGILL in both implementations:
12 paired checks total, including a maximum-usize count. Native loop executions
have a 30-second timeout. The integrated-executable gate invokes the same
canary, alongside the existing behavioral, memset and memcpy suites.

## Validation and measurement

Evidence root: `local-state/validations/cyclic-byte-memory-20260926/`.
`input-identities.json` pins the retained source and definitions;
`discovery-comparison.json` records the exact failure-set change.

Completed focused checks: 1,501/1,501 Debug unit tests, 8/8 structural tests,
13/13 focused tests in each of ReleaseFast and ReleaseSafe, 60/60 ABI
differential cases across three modes, and all six native canary runs.
Focused release tests do not claim a full ReleaseFast unit-suite pass.

Full Tier 3 passed all 17 subgates with `local_fail=0` in 2,623,421 ms wall time
(`distribution-all.log`). It repeats the complete new canary successfully,
alongside the existing behavioral and memory-family suites. Each real-row mode
lowers, emits and links 100 rows and executes four cohort members. The three
reported object caches are hits; executions are not cached. These are new
development results, not an accepted-counter migration.

The 1,391 source/tool/test/build files recorded before Tier 3 are unchanged
afterward (`source-before-tier3.json`, `source-after-tier3-check.json`).
`tier3-trigger.txt` records the verifier-invariant and capability-closure
triggers, exact command and reason the preceding slice's evidence could not
be reused. Unit, structural and release results are in `unit-final.log`,
`structural.log`, `focused-releasefast.log` and `focused-releasesafe.log`;
`abi-differential.log` records the separate mandatory ABI gate.

## Fixed-program comparison

The unchanged [baseline protocol](fixed_program_baseline.md) ran with the
prebuilt ReleaseFast compiler, Zig 0.16.0 and LLVM 22 on CPU 2, before full
integration. Two warmups and nine unfiltered samples were retained per supported
pair. All 14 supported pairs have identical object bytes and semantic/runtime
output hashes to the [memcpy checkpoint](composed_memcpy_family.md). The
loop-memory release-o3 route still rejects in the optimizer with `TypeMismatch`.

[Raw results](composed_byte_loops_performance.json) retain samples, dispersion,
sizes and hashes; [identities](composed_byte_loops_identity.json) record the tools,
invocation and source-manifest hash. Commands and all artifacts are retained in
`performance-final/` under the evidence root.

The table compares memcpy checkpoint → this slice. Times are milliseconds;
object and executable-section sizes are bytes and are unchanged.

| Workload | Route | Compile median | Runtime median | Object bytes | Code bytes |
| --- | --- | ---: | ---: | ---: | ---: |
| arguments_branches | llvm-O3 | 22.314 → 22.524 | 52.330 → 51.613 | 616 | 22 |
| arguments_branches | direct | 2.496 → 2.585 | 65.320 → 63.527 | 816 | 116 |
| arguments_branches | release-o3 | 3.246 → 3.059 | 64.532 → 63.819 | 816 | 116 |
| loops_memory | llvm-O3 | 25.844 → 23.988 | 79.063 → 78.335 | 720 | 124 |
| loops_memory | direct | 3.041 → 2.644 | 253.776 → 252.112 | 816 | 127 |
| loops_memory | release-o3 | unsupported: TypeMismatch | — | — | — |
| nested_calls | llvm-O3 | 23.205 → 23.711 | 42.447 → 41.315 | 712 | 59 |
| nested_calls | direct | 2.145 → 2.316 | 147.927 → 148.139 | 920 | 88 |
| nested_calls | release-o3 | 2.858 → 2.816 | 148.370 → 149.219 | 920 | 88 |
| register_pressure | llvm-O3 | 24.751 → 22.298 | 49.461 → 49.201 | 1040 | 74 |
| register_pressure | direct | 2.470 → 2.415 | 97.783 → 96.863 | 896 | 199 |
| register_pressure | release-o3 | 3.445 → 2.866 | 98.041 → 96.637 | 896 | 199 |
| memset | llvm-O3 | 26.778 → 26.001 | 32.833 → 32.664 | 1832 | 275 |
| memset | direct | 4.825 → 4.685 | 63.687 → 63.307 | 1944 | 798 |
| memset | release-o3 | 6.052 → 5.730 | 64.008 → 63.231 | 1944 | 798 |

Identical objects still show runtime variability. These observations do not
establish a speedup, and the matrix does not measure the newly admitted string
and comparison functions. No accepted counters are advanced.

An earlier attempt in `performance-after/` completed the measurements but failed
the final consistency guard when the new unit-test file was added to the Git
index during execution. Existing recorded source contents did not change, but
the tracked source inventory did. That attempt is incomplete and is not used
above; `performance-final/` repeated the entire protocol with a stable inventory
and passed all final identity checks.
