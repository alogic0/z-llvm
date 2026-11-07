# Unchanged Zig document-input program

Implementation and focused execution pass. The existing 457-line
`tools/migrate_langref.zig` passes 29 runtime inputs in each of ReleaseFast,
ReleaseSafe and ReleaseSmall: 87 local/reference pairs and 603 observation
controls. Full 17-gate acceptance remains pending. Accepted
capability counters have not advanced.

The [focused record](zig_input_program_focused_20261106.json) binds the tested
worktree snapshot, compiler hashes, reports, profiles and logs. Raw evidence is
under `local-state/validations/zig-input-20261106/`. The snapshot precedes the
documentation and split commits; it includes the exact corpus and backend
bytes used by the tests, not just the base revision.

## Program and oracle

The source belongs to the existing Zig pin
`1c08b09d1c847f4f02c8216e3b62df323861a437`. Its SHA-256 is
`9aec36ec200d80b82dffefac559d7c488ec616690aca167346c82be4693b7b25`.
Neither the tool nor its library sources were patched. The source matches Git
bytes, and the pinned Zig worktree remains clean after execution.

The tool receives filenames at runtime, reads allocated document data, mutates
tokenizer/directive state and growable lists, extracts named source files,
rewrites a document, and handles parser and filesystem failures. The
[corpus contract](../../test/real_programs/migrate_langref.md) specifies all ten
code kinds, repeated options, 128-entry list growth, 96 extracted blocks, a
document larger than 100 KiB, 2,048 source-comment lines, alternate argv,
missing input, duplicate output names and malformed input.

The frozen manifest contains 171,924 input bytes and 142 expected output files
per mode, including partial results on errors. Each reference and local case
gets a fresh working directory. Exact completion, status, streams and the set
and bytes of output files must match independently authored expectations;
input bytes must remain unchanged. The reference executable is a second
comparison, not the source of expected output snapshots. Qualification corrected
two hand-counted error-location expectations against the unchanged tokenizer:
the truncated name begins at column 18, and an EOF error has no source excerpt.
The earlier failed qualification remains retained.

Controls change completion, status, streams, and extra/missing/changed files.
There are 201 rejected changes per mode. They mutate observations and do not
establish compiler-mutation coverage. Policy tests additionally exercise binary
file contents, isolation, traversal rejection and unexpected symlink outputs.

## Source-backed compiler repairs

The initial three-mode run passes Fast and Small. Safe emits 1,870 of 1,873
selected definitions and rejects the following three. The original IR and
complete diagnostics remain in `three-mode/ReleaseSafe/`.

| Pinned Zig source | Captured IR and failure | Shared repair |
| --- | --- | --- |
| `lib/std/heap/SafeAllocator.zig:397`, `AllocFooter.tracesPtr` | Loaded pointer passed to `call fastcc i1`; `ValueUseRegisterClassMismatch` | Boolean-call requests distinguish runtime pointers from local stack objects using the existing typed register-class accessor. The call transaction revalidates and materializes pointers through the shared authority after preservation. |
| `lib/std/heap/SafeAllocator.zig:688`, `deinitLeakedBucket` | `atomicrmw xchg ptr ..., i16 undef`; `ValueUseUnsupportedSource` | Integer atomic RMW operands can choose zero for `undef`. The atomic operation, ordering and defined old-memory result remain. |
| `lib/std/os/linux.zig:7313`, `CPU_COUNT` | Scalar `llvm.ctpop.i64` without a return range annotation; `unsupported_type llvm.ctpop` | Inspection and selection accept the absent optional attribute for existing i64/i128 popcount lowering. Unsupported widths and other call-form checks remain. |

LLVM's [undefined-value contract](https://llvm.org/docs/LangRef.html#undefined-values)
permits an unspecified bit pattern; choosing zero is a valid refinement here.
The [atomic RMW contract](https://llvm.org/docs/LangRef.html#atomicrmw-instruction)
still requires the original memory value as the result. Popcount's
[intrinsic signature and semantics](https://llvm.org/docs/LangRef.html#llvm-ctpop-intrinsic)
require matching integer input/result types and bit counting; a call-site range
annotation is not required.

Executable regressions check direct and loaded pointer arguments, pointers and
integer values live across a callee that clobbers volatile registers, and dirty
upper return bits. Transaction failure injection checks restoration of register,
spill and accumulator state. Atomic checks cover 8/16/32/64-bit old values,
neighboring bytes and live inputs for exchange/add/xor with `undef`. Popcount
checks cover i64/i128, annotated and unannotated calls, zero, high bits and
all-one inputs. The reviewed popcount body fingerprint changes with its attribute
admission condition; residual pair-operation classifications and counts remain.

## Results and compiler cost

`fixed-three-mode/report.json` retains all 174 actual execution observations,
authenticates the oracle manifest, and records tool/source identities. Ownership sidecars match independently
reselected manifests byte for byte. Linked candidate objects match the captured
hook object's sections, symbols and relocations.

| Program mode | Selected/emitted definitions | Composed block / CFG | Object-emission profile | Ownership replay |
| --- | ---: | ---: | ---: | ---: |
| ReleaseFast | 1,654 | 669 / 985 | 19.21 s | 19.92 s |
| ReleaseSafe | 1,873 | 595 / 1,278 | 30.98 s | 30.88 s |
| ReleaseSmall | 866 | 377 / 489 | 5.99 s | 5.88 s |

These use a ReleaseFast compiler. Profiles retain per-function and per-legalizer
timings and counters. Selection plus optional legalization accounts for 16.82 s,
26.67 s and 5.36 s respectively, with 140,522, 163,738 and 71,071 legalizer
attempts. These single observations ran alongside other validation and are not
controlled speedup measurements. Emitted definitions are not executed-function
counts, and the ownership replay remains substantial duplicate selection work.

All 1,913 unit tests pass in both Debug and ReleaseSafe, as do all 30 policy tests
in both modes, 19 structural checks, 38 captured-object checks, 60 ABI differential
cases, compilation-route checks and readiness. Readiness includes 6,528 generated
program observations. Unchanged Fibonacci passes all three modes with independent
ownership replay. The existing single-observation hello manifest still passes.
The modified integrated runner compiles; its complete run and the full native
and compiler-core populations remain part of pending full acceptance.

## Acceptance, storage and reproduction

The `zig-input-program` build step and integrated executable gate require the
corpus and ownership replay. The source is compiled for baseline x86-64 Linux
using the local preopt optimizer/object route. Both implementations use
single-threaded startup and disable error-return tracing for exact diagnostics.
LLVM IR construction, Zig's linker/compiler-rt and libc/CRT remain dependencies.
This corpus does not claim allocation-failure injection, concurrency or panic
trace coverage.

After validation, 32 complete idle project/task cache roots were removed. The
deletion interval reclaimed 2.64 GB. All 4,359 retained task files, compiler
identities and thirteen original probes were verified unchanged. Shared caches,
authenticated AIR, diagnostic worktrees, accepted evidence and installed outputs
remain. No archives were created. The retained cache audit distinguishes
allocated bytes from filesystem free-space movement and notes regeneration.

The first full admission measured 14,188,736,512 bytes available: 18,760,936,448 bytes short
of the unchanged 32,949,672,960-byte requirement. No full gate started. The
24,359,738,368-byte execution reserve also remains unchanged. The prepared
`local-state/validations/zig-input-20261106/full-acceptance.sh` checks admission,
compiler and source identity, freezes a new snapshot, retains reports, and runs
the authoritative 17 gates once space is available. The
[plan](../plans/2026-11-06-unchanged-zig-input-program.md) stays open until that
run passes and its evidence is reviewed.

To rerun the bounded corpus:

```sh
zig build zig-input-program -- --output-root=tmp/zig-input-check
```

Use `--zllvm=local-state/validations/zig-input-20261106/compiler-fast/bin/z_llvm`
to select the retained ReleaseFast compiler. New output roots must not exist.
