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
