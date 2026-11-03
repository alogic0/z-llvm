# Differential testing and generated coverage

The project has separate optimizer and backend comparisons. Their populations
and transformation owners must remain explicit; see [current architecture](architecture.md)
and [pipelines](pipelines.md).

The compiler-core execution cohort now includes `ascii.isAscii` within the
unchanged 100-row selector-v3 population. Its independent bit-mask oracle checks
all 256 byte inputs and the entire ordered result transcript in each release
mode. The [focused evidence](evidence/ascii_execution_20261102.json) records 768
matching observations and six rejected constant-result implementations.
Schema-3 cohort records distinguish five executed functions from their input
observations: 256 for ASCII and one for each retained constant method. Accepted
counters retain five in the
[current acceptance](evidence/scalar_startup_acceptance_20261103.json): the serial
run passes all 17 subgates on the unchanged 100-row selection. The earlier
fresh/cached infrastructure pair remains separate evidence.

| Runner | Local path | Independent reference and boundary |
| --- | --- | --- |
| `zig build compare-opt` | Named optimizer fixture/pass pairs. | Normalized LLVM `opt-22` output for equivalent rows; local golden output for explicitly conservative/preservation rows. |
| `zig build optimizer-correctness` | 16 regression functions after the focused optimizer pipeline and `release-o3`. | LLVM 22 reference execution plus explicit expected values. Transformed IR passes LLVM verification and is compiled by clang at `-O0`; this isolates optimizer behavior from local codegen. |
| `zig build behavioral-diff` | Local object emission from unoptimized LLVM IR; every function must have composed selector ownership. | LLVM objects from the same source with independent optimization, linked with the same harness. Reference/harness modes do not select local optimizer passes. |
| `zig build generated-scalar-diff` | Six scalar identity comparisons, two rejection cases, optional execution smoke, then the behavioral suite. | `opt-22`, optional `lli-22`, and the behavioral suite's independent LLVM reference. |
| `zig build real-program -- --output-root=local-state/validations/<new-run>` | An unchanged, hash-pinned upstream Zig program through local preopt optimization and object emission in three release modes. | The pinned Zig LLVM route, exact stdout, stderr and exit status. IR construction, the system linker/CRT and libc remain external dependencies. A failed stage earns no execution credit. |
| `zig build upstream-c-program -- --output-root=local-state/validations/<new-run>` | Zig's unchanged C compiler fixture, local memory/release pipelines, local objects, two argument cases per mode. Separate pointer/length memory canaries use direct and release routes. | LLVM 22 compiles the identical inputs; exact stdout/stderr/status, integer-call/heap checks and pointer/length field/guard checks. C sanitizers are disabled; this does not establish Zig startup support. |

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
The local C variadic envelope admits one or two fixed pointers and at most one
unnamed i32; floating, aggregate, stack and indirect variadic calls still reject.
Constant `strlen` folding and a second CFG cleanup remove the statically
unreachable length panic without changing the upstream source.

The [C fixture](evidence/upstream_c_program_20261102.json) adds one separate
program in three local pipeline modes, with six paired argument-case executions.
Its mandatory native canary contributes 48 integer-varargs and 18 heap-call
observations across those modes. Assembly shims check AL directly, and boundary
integers and a register permutation exercise the caller. These observations do
not advance compiler-core or compiler-rt function counts.

The mandatory [pointer/length memory canary](evidence/startup_word_pair_memory_20261102.json)
checks two functions through direct and release routes in all three modes.
Four pointer values and eight full-width lengths give 384 local observations,
compared with 192 LLVM-reference observations reused across routes and independent
expected fields. It checks copy independence after source mutation, exact pointer
and length bits, output guards and composed lowering ownership. These are separate
from the C fixture cases and its 66 call/heap observations.

The mandatory [scalar frame-store canaries](evidence/scalar_frame_acceptance_20261103.json)
add two standalone populations. Four pointer functions contribute 768 local
observations against 384 references, checking argument spills across a C callee
that clobbers caller-saved registers, returned RAX pointers, frame-object addresses,
live values and output guards. Three scalar functions contribute 486 local
observations against 243 references: 64 value/live combinations, 16 constant-field
checks and one literal-null check per executable. Both populations use direct and
release routes in three modes, reusing references across routes.

A native before/after reproducer confirms the existing i64 immediate-store bug:
positive `4294967295` was sign-extended to all ones. Full-width intent now preserves
the required `00000000ffffffff` bits. Unit rejection checks cover non-default
address spaces, 32-bit default pointer layouts, invalid frame kinds/widths,
misalignment and frame bounds.

The [scalar startup canaries](evidence/scalar_startup_acceptance_20261103.json)
add four integer-to-pointer functions and four signed nonnegative-compare
functions. Each population checks 1,536 local observations against 768 LLVM
references through direct/release routes in three modes. Casts cover full-width
patterns, register/spill/returned-RAX inputs and pointer returns; comparisons
cover i32/i64 signed extrema and exact zero-extended booleans. Native C callees
clobber caller-saved registers, independent expected fields check every result,
and output guards detect overwrites. Unit tests cover live EFLAGS, aliases,
rollback and the deliberately unsupported forms.

The unchanged Fibonacci retry passes frame stores, pointer casts and the signed
comparison but remains blocked in `start.main` at
`unsupported_value:composed-block-memcpy-dst`, on a constant-offset global
copy destination. Its reference executes once and local execution remains
zero; this program is not accepted.
