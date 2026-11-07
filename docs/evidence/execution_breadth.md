# Execution breadth after Fibonacci

Implementation checkpoint: `f68ab145d3f5efc4f4a4f01d30012dc3e4db0eac`, tree
`06d222b29524f157950e80b6e4dd0c1dafdc0462`. All 17 integration gates pass.
The [acceptance record](execution_breadth_acceptance_20261106.json) binds the
frozen 2,941-file source snapshot, compiler builds, reports and validation logs.
The source pin remains `1c08b09d1c847f4f02c8216e3b62df323861a437`.
The fixed 100-row compiler-core candidate SHA-256 remains
`847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31`.

## Shared repairs

The retained tagged-union Fast input reproduced the accepted compiler's
15 failures: nine register-copy cycles, four immediate-left arithmetic forms,
one overlapping copy and one symbolic-base GEP. It selected 1,484 functions
and emitted 1,469. The repaired compiler emits all 1,484.

The common value-use planner now identifies cyclic physical transfers and
snapshots their sources before materializing destinations. Calls also preserve
later arguments that an earlier argument would overwrite, even without a cycle.
Scalar integer register PHIs share this transaction. Scratch selection excludes
all participating registers and early writes; otherwise the existing spill
authority provides storage. All aliases retain their widths and identities.
Unsupported forward references or storage arrangements fail transactionally.
Pair/vector PHIs and spill destinations retain their existing lowering path.

Immediate-left multiplication uses the existing commutative scalar rule.
Subtraction and shifts preserve operand order. `memmove` shares copy planning
with `memcpy` while retaining overlap-safe emission. Symbolic constant GEP bases
are materialized through the shared global-address legalizer. These repairs add
no symbol-specific selectors or machine instructions. The bypass ratchet stays
at 130. Optional legalizers and ordinary CLI structural selection remain future
consolidation work; mandatory semantic normalization remains in place.

The permanent `parallel_transfer` native population checks calls, PHI rotations,
two/three-register cycles, fan-out, dirty upper bits, aliases, memory guards,
overlap in both directions, symbolic addressing and operand order. It executes
49,152 local observations across direct/release routes and three modes against
24,576 LLVM observations. Encoded-machine unit tests add accumulator cycles,
register pressure, exhausted storage, unsupported registers and rollback.

## Executed compiler-core definitions

The execution cohort advances from v3 to v4, with matching v3 real-row counters
and an exact nine-member output parser. Four definitions already in the fixed
100-row prefix join the five existing members:

| Definition | Cases per mode | Observable behavior |
| --- | ---: | --- |
| `bit_set.Dynamic.maskIndex` | 4,108 | Division by the mask width, including boundary indexes |
| `atomic.Mutex.tryLock` | 384 | Successful, repeated and reset attempts; adjacent-byte guards |
| `Metadata.isFree` | 256 | Every packed byte state |
| `Metadata.isTombstone` | 256 | Every packed byte state |

Each descriptor is authenticated against exact raw and structured AIR extracts
from the pinned three-mode cache. Source hashes bind the supporting definitions.
Independent reference harnesses and linked calls check values and memory effects;
the 27 permanent negative controls reject wrong results, wrong symbols and a
correct-returning implementation that corrupts adjacent memory. They require an
explicit oracle failure; crashes and timeouts do not count as rejection evidence.

The first full run stopped at cache probing because source-identity hashing did
not handle the new nested hashes. A regression test now proves that each added
source affects the authority hash. This changes the authenticated cache identity,
so run v2 generated a fresh AIR cache; the old generation is preserved. All three
compiler-core gates passed. That full run then stopped on a variable-shadowing
compile error in the new unchanged-program driver. The corrected driver builds
successfully. Final run v3 reuses the authenticated cache, and all 36 canonical
records match v2's fresh compiler-core results. The compiler and
cohort implementation are unchanged between those two runs.

The later [project cleanup](project_space_cleanup_20261106.json) retires the
superseded `ir-headroom-20261103` payloads after reverifying this replacement's
accepted metadata, payload hashes and 36-record fresh/cached comparison.
Historical metadata and acceptance evidence remain.

This expansion exposed a real atomic lowering error. `atomic.Mutex` is `enum(u8)`
but the previous exchange recognizer emitted a hardcoded 32-bit operation.
The guarded harness failed its first lock attempt. Lowering now proves width,
constants, pointer dataflow, ordering and the returned success reference from
both AIR views. A generic mutation test also admits a 16-bit exchange with
different constants and valid stronger ordering. The enum's width is represented
in the shared type facts, without a function-name exception in selection.

## Unchanged programs

Permanent manifests add `optionals`, `taking_pointer_of_global_tagged_union`,
`array_in_anon_struct` and `while_loops` to the pinned three-mode Fibonacci gate.
They cover optional branches, global tagged storage, aggregate initialization
and a runtime loop. Every source byte and assertion is preserved. Each program
compares exit status, stdout and stderr with LLVM, using baseline x86-64 and the
same pinned runtime/CRT. Emitted helper counts are kept separate from executed
programs and callable compiler-core functions.

All five unchanged programs pass all three modes in the frozen v3 integration run.
Their selected/emitted definition counts remain separate from execution coverage:

| Program | Fast definitions | Safe definitions | Small definitions | Executed modes matched |
| --- | ---: | ---: | ---: | ---: |
| `recursive_fibonacci` | 34 | 1,568 | 34 | 3/3 |
| `optionals` | 33 | 1,567 | 33 | 3/3 |
| `taking_pointer_of_global_tagged_union` | 1,484 | 1,575 | 660 | 3/3 |
| `array_in_anon_struct` | 1,485 | 1,576 | 661 | 3/3 |
| `while_loops` | 33 | 1,567 | 33 | 3/3 |

Exploratory `program-optionals-v1` and `program-array_in_anon_struct-v1` executed
all three modes successfully but were rejected because validation tools changed
during those runs. They are diagnostic evidence only. The final frozen integration
run supplies accepted reports with unchanged tool provenance for all programs.

## Acceptance

Both Debug and ReleaseSafe pass 1,901 unit tests and 36 policy tests. Nineteen
structural checks, 60 ABI comparisons, compilation-route checks and readiness pass.
The cohort's source/descriptor tests pass 32 checks, and its gate tests pass 16
checks in each build mode. The permanent new controls execute 15,012 observations
over 12 function/mode pairs and reject all 27 negative controls.

All 45 native populations pass 1,767,660 local observations against 883,830 LLVM
observations. The full integration log passes the 17-gate structural validator
with 1,469 canonical records. This is a structure check of the new population,
not an equivalence claim against the old five-member cohort or 44-population run.
The separate fresh/cache comparison validates all 36 compiler-core records.

## Compiler throughput

The measurement script uses the same retained Safe Fibonacci IR with Debug and
ReleaseFast builds of the current compiler. It times object emission and ownership
manifest replay separately, records CPU time and peak RSS, and compares both
outputs byte-for-byte. This is compiler throughput, not generated-code performance.
The measurements overlap other validation work and are single samples.

| Compiler build | Route | Wall seconds | User seconds | System seconds | Peak RSS, KiB |
| --- | --- | ---: | ---: | ---: | ---: |
| Debug | Object | 328.94 | 319.05 | 9.72 | 780,124 |
| Debug | Ownership replay | 321.48 | 311.61 | 9.74 | 780,040 |
| ReleaseFast | Object | 32.40 | 27.70 | 4.67 | 610,048 |
| ReleaseFast | Ownership replay | 33.01 | 28.22 | 4.77 | 610,064 |

Both builds produce byte-identical objects and ownership manifests. Using the
ReleaseFast compiler for large development gates substantially reduces their
cost while retaining Debug tests. Ownership replay repeats most compilation
work; combining emission with ownership reporting is a possible later improvement,
subject to preserving the existing ownership proof and output contracts.

Hardware profiling was unavailable: `perf stat` was rejected by the host's
`perf_event_paranoid=4` policy. No sampling-based hotspot claim is made. The
existing generated-code workload matrix remains the optimization-quality gate.

## Evidence and boundaries

Raw reports, commands, hashes, source snapshot and original failing inputs are
under `local-state/validations/execution-breadth-20261106/`.
The full suite sets `ZLLVM_EXE` to the ReleaseFast compiler for integrated objects,
integrated executables and the five large unchanged programs. The ordinary build
and native-population tools use Debug from the same implementation. The accepted
installation remains Debug. Full Debug/Safe unit tests cover the shared code.

The start threshold is 32,949,672,960 bytes and the execution reserve is
24,359,738,368 bytes. No archives were created. The temporary previous-compiler
copy and the standalone driver build were removed after acceptance. About 44.07 GB
remains free. The 13 original scratch probes,
diagnostic worktrees and authenticated AIR cache remain intact.

The next architecture work is consolidation of optional legalization and explicit
machine register effects. Further execution breadth should include larger state
and memory interactions. Neither this checkpoint nor its emission counts establish
self-hosting, complete language support or release optimization quality.
