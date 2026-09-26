# Differential testing and generated coverage

The project has separate optimizer and backend comparisons. Their populations
and transformation owners must remain explicit; see [current architecture](architecture.md)
and [pipelines](pipelines.md).

| Runner | Local path | Independent reference and boundary |
| --- | --- | --- |
| `zig build compare-opt` | Named optimizer fixture/pass pairs. | Normalized LLVM `opt-22` output for equivalent rows; local golden output for explicitly conservative/preservation rows. |
| `zig build optimizer-correctness` | 16 regression functions after the focused optimizer pipeline and `release-o3`. | LLVM 22 reference execution plus explicit expected values. Transformed IR passes LLVM verification and is compiled by clang at `-O0`; this isolates optimizer behavior from local codegen. |
| `zig build behavioral-diff` | Local object emission from unoptimized LLVM IR; every function must have composed selector ownership. | LLVM objects from the same source with independent optimization, linked with the same harness. Reference/harness modes do not select local optimizer passes. |
| `zig build generated-scalar-diff` | Six scalar identity comparisons, two rejection cases, optional execution smoke, then the behavioral suite. | `opt-22`, optional `lli-22`, and the behavioral suite's independent LLVM reference. |

## Current generated inputs

The scalar generator still covers `add x, 0`, `sub x, 0`, `mul x, 1`,
`and x, -1`, `or x, 0`, and `xor x, 0`. It also checks unsupported scalable
vectors and invalid atomic ordering. Its optional `lli-22` smoke checks an
expected return value.

The [behavioral suite](../test/behavioral/README.md) adds four fixed composed
programs and four deterministic generated programs. It covers branches,
initialized memory and loops, nested calls, register pressure, wrapping integer
operations, and supported conversions/division/shifts. It checks 272 inputs per
program/mode pair, for 24 pairs and 6,528 observations in the recorded population.
This bounded deterministic generator is not an unrestricted fuzzer.

The new [optimizer regression cases](roadmap/optimizer_review_repairs.md) cover
changing SCCP call arguments, integer bitpattern comparisons, and escaped globals
alongside the earlier memory and LICM regressions. These tests are complementary
to the composed-codegen suite.

## Evidence and failure handling

Record the input, selected pass list, selector owner, reference/harness mode,
and tool identities. Keep compiler-core, compiler-rt, and standalone behavioral
counters separate. Do not interpret a native link as execution or an LLVM-compiled
optimizer result as local-codegen coverage.

Keep generated artifacts in temporary or validation directories. Minimize a
reproduced failure before promoting it into a named tracked regression. Broader
generated compositions, minimization, and performance baselines are proposed in
the [refactor plan](roadmap/architecture_refactor_plan.md); they are not completed
capabilities.
