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
| `zig build real-program -- --output-root=local-state/validations/<new-run>` | An unchanged, hash-pinned upstream Zig program through local preopt optimization and object emission in three release modes. | The pinned Zig LLVM route, exact stdout, stderr and exit status. IR construction, the system linker/CRT and libc remain external dependencies. A failed stage earns no execution credit. |

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

## Review regressions and reference identity

[Native checkpoint tests](../src/tests/correctness_checkpoint_native.zig) execute
aggregate snapshots with alias mutations under seed `0x5eed1234`, optional pointer
and tagged scalar checks including non-null zero, wrapped zero, typed GEP strides,
127/128/255/256 byte displacements, and a scaled sret load. They also check that
volatile optional reads retain their flag and unsupported optional signatures
reject. They are bounded regressions, not evidence for arbitrary aggregate or
optional ABI coverage.

The [ABI reference contract](../test/abi_diff/reference_identity.env) must agree
with the tracked Zig pin and emitter version. Migrating it requires auditing
the cohort source and upstream file hashes; environment variables cannot override
these expected identities. At revision `1c08b09d1c847f4f02c8216e3b62df323861a437`,
the shift and multiplication source files and extracted integer algorithms are
unchanged. The half/double wrappers now call the upstream float ABI adapters;
the cohort retains those wrappers and their identity adapters under compile-time
x86_64 Linux hard-float assertions. Historical accepted body hashes in the cohort
manifest remain historical; a new pin must still pass the native differential
gate with the same ten rows and the existing provenance and ABI checks.

The unchanged hello-world program is an end-to-end canary. Its runner
requires a new evidence directory inside the project, checks the program against
both its manifest hash and pinned Git contents, and never patches the source.
It exits unsuccessfully when any mode fails, preserving its report and exact
process streams. Command wall times and object sizes are diagnostic measurements;
they do not establish runtime performance or a speedup.

The mandatory integrated-executable gate invokes this runner in all three
release modes. It verifies that Zig's relocatable link preserves the local
object's allocated bytes, symbols and relocations, allowing ELF table repacking.
The local C variadic envelope admits one fixed pointer and no unnamed arguments;
float arguments, additional arguments and indirect variadic calls still reject.
Constant `strlen` folding and a second CFG cleanup remove the statically
unreachable length panic without changing the upstream source.
