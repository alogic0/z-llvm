# Behavioral differential suite

Run `zig build behavioral-diff` with Zig 0.16.0 and clang-22, or select a single
case with `-- --case generated_1`. The integrated-executable gate and generated
scalar checks invoke the same suite. Existing canaries remain in place.

Four fixed programs cover argument-dependent branches, loops with initialized
stack memory, nested calls, and twelve overlapping scalar values. Four generated
one-function programs use fixed seeds to combine wrapping arithmetic, signed
power-of-two division, signed/unsigned shifts, and i16 truncation/extension.
Each module must select composed lowering for every function. No structural
fallback is admitted. Owners and source hashes are printed beside results.

The reference is compiled independently from the same LLVM IR using clang-22 at
-O3/-O2/-Oz. An identical Zig driver links each reference/z_llvm object pair in
ReleaseFast/ReleaseSafe/ReleaseSmall. These are reference and harness modes;
z_llvm emits the same unoptimized IR in each pair. No claim about an AIR exporter
mode is made by these standalone cases. `distinct_executed_functions` counts
(case, function) identities; program success counts (case, harness-mode) pairs;
observations count individual inputs. These counters never alter compiler-core
or compiler-rt acceptance records.

The driver uses 13 signed boundary values with 16 loop counts, then 64 LCG inputs
(seed 0x5eed1234), for 272 inputs per pair. Integer arithmetic has no nsw/nuw flags,
divisors are positive powers of two, shifts are within width, and loops range
from 0 to 15. There is no division by zero, signed division overflow, uninitialized
load, or unbounded iteration. Full process termination, stderr and stdout are
compared; missing tools and failed processes fail the suite.

`rejections/` preserves two small unsupported compositions discovered during
implementation. `sext16.ll` rejects with `composed-block-sext-width`;
`live_narrow_alias.ll` rejects with `stage2-cast-value`. They are development
reproducers, not additional passing programs. The positive generated suite uses
an arithmetic shift before truncation and does not retain the narrow alias's
source across zero extension. Unit regressions separately reject non-power-of-two,
negative, zero, i64 and variable signed divisors near the new lowering boundary.

## Fixed-program measurements

The standalone [performance protocol](../../docs/evidence/fixed_program_baseline.md)
freezes these four fixed modules and the combined memset module in
[performance_manifest.json](performance_manifest.json). It measures direct,
release-o3-plus-codegen and independent LLVM routes with prebuilt compilers.
The two `performance_*.zig` drivers repeat deterministic inputs for timing;
the existing full semantic drivers remain the correctness oracle. The runner
is separate from acceptance gates and records unsupported pairs explicitly.

## Retained memcpy family

`zig build memcpy-diff` exercises the exact retained `ssp.__memcpy_chk` and
`memcpyFast` definitions plus seven compositions. It checks 8,967 observations
per route/mode, including unaligned offsets, zero/boundary lengths, surrounding
bytes, source preservation, return pointers and live scalar/vector values.
Direct and release-o3 routes run in three harness modes, always with composed
ownership and an independent LLVM reference. Bounds violations must trap.
See [the evidence and admission boundaries](../../docs/evidence/composed_memcpy_family.md).

## Scalar byte loops and checked strncpy

`zig build byte-loops-diff` exercises the exact retained `ssp.__strncpy_chk`,
`bcmp` and `memcmp` definitions plus four scalar byte-loop compositions. Each
direct/release-o3 route runs in three harness modes against the original IR
compiled by clang-22. All seven functions must use composed lowering.

The harness checks zero padding, truncation, returned pointers, high-bit byte
comparisons, loop-carried values, early exits, source preservation and unchanged
surrounding bytes. Protected pages detect source overreads and zero-length
accesses; paired SIGILL checks cover bounds violations. Native loop executions
have a 30-second timeout. The integrated-executable gate runs the same canary.
See [the evidence](../../docs/evidence/composed_byte_loops.md).
