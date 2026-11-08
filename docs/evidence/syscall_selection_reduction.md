# Syscall contracts and measured compiler selection reduction

Status: accepted. All 17 cumulative integration gates pass on the frozen sources.
Record: [machine-readable acceptance](syscall_selection_reduction_acceptance_20261108.json).
Plan: [ordered implementation plan](../plans/2026-11-08-syscall-selection-reduction.md).
Raw evidence: `local-state/validations/syscall-selection-20261108/`.

Implementation is frozen at `111f2e0a`, following `1f23abba` (syscall contracts)
and `1a522bd4` (same-sign comparisons). The preceding accepted implementation is
`4b8eac2a`, documented at `d4292871`. Compiler, tools, tests and build inputs are
hashed before final builds; documentation is finalized after acceptance.

## Syscall classification and shared contract

An observational replay preserves every baseline selection outcome for all
8,928 compiler definitions and 455 runtime definitions. All 328 result-bearing
assembly rejections are the exact Linux x86-64 `syscall` operation: 327 have the
main control-flow diagnostic and one has a varargs diagnostic. Four concrete
forms occur. The largest contains 325 three-argument syscalls with a typed range
on the last argument; the others contain six arguments, four arguments, and a
tail-marked three-argument form.

The closed assembly matcher now reuses the existing SysV call validators for
typed argument/return facts and optional tail hints. It retains the exact
template, constraints, side-effect and memory contract, i64 carriers and zero
through six kernel arguments. Mandatory tail calls, unsupported ABI promises,
unrecognized constraints and arbitrary assembly remain rejected. Source IR and
attributes remain unchanged. Existing register effects, simultaneous transfers,
live-value preservation and rollback perform the lowering.

The semantic boundaries follow LLVM's [call contract](https://llvm.org/docs/LangRef.html#call-instruction)
and [parameter attributes](https://llvm.org/docs/LangRef.html#parameter-attributes),
with Linux's documented [syscall register convention](https://man7.org/linux/man-pages/man2/syscall.2.html).
Optional tail hints impose no mandatory tail-call lowering; typed range facts
restrict defined inputs without changing register representation.

Unit combinations compare machine bytes for all seven arities, three tail
states and four fact combinations. Negative cases cover ABI-changing attributes,
invalid ranges, widths, constraints and mandatory tail calls. The permanent
`syscall_facts` population supplies eight functions and 1,152 observations per
route/mode. It executes getpid, error-returning close, ftruncate, write, pread64
with nonzero offsets, statx, and anonymous/file-backed mmap with a nonzero file
offset. Reversed formal arguments exercise register transfers and the syscall
number arriving on the stack. Independent C checks cover errors, memory canaries,
live GPR/SSE values, PHIs and flags.

This slice selects 7,054 compiler definitions, adding fourteen without losses.
Of the original 328 assembly first failures, three now select, 324 reach an
unknown call-argument rejection and one reaches a freeze-type rejection. The
other eleven additions previously had different final first-failure diagnostics.
Runtime selection remains 284 of 455.

## Same-sign unsigned comparisons

The updated census attributes all 179 comparison-RHS failures to named
`icmp samesign ult i64` operands. Their actual private operand origins and
register/spill locations are retained. The selector and shared scratch action
now admit this case through the existing full-width unsigned comparison path.
Register transfers, preservation, EFLAGS effects and rollback are unchanged.

LLVM's [icmp contract](https://llvm.org/docs/LangRef.html#icmp-instruction)
defines the ordinary predicate when the operands have the same sign. The
`samesign` flag makes opposite-sign inputs poison; it does not require a different
unsigned comparison. Regression inputs obey that defined-input condition.

Unit coverage compares the complete machine stream with the ordinary form and
executes boundary values. The permanent `comparison_facts` population contains
six functions and 3,584 observations per route/mode. An independent C oracle
covers both sign ranges, equal values, high bits, swapped operands, PHIs,
unaligned loads/stores with canaries, spills and a helper that actually clobbers
caller-saved GPR and XMM registers.

The comparison slice adds 62 selections without losses. All 179 targeted first
failures advance: 62 select and 117 expose later boundaries. These are 112
readonly-table global addresses, two unknown call arguments, and one each for
freeze width, load width and cast value.

## Measured complete-input result

| Checkpoint | Compiler selected / total | Compiler failures | Runtime selected / total | Lost prior successes |
| --- | ---: | ---: | ---: | ---: |
| Previous accepted baseline | 7,040 / 8,928 | 1,888 | 284 / 455 | — |
| Validated syscall facts | 7,054 / 8,928 | 1,874 | 284 / 455 | 0 |
| Same-sign unsigned comparisons | 7,116 / 8,928 | 1,812 | 284 / 455 | 0 |

The net reduction is 76 compiler selection failures, or 4.03% of the previous
1,888 failures. Every original input definition is attempted. The compiler input
SHA-256 is `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`;
runtime is `ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.
The original compiler input inode and retained baseline artifacts are preserved.

Independent production replays match every selected function identity and every
failure diagnostic/tag/detail tuple from the final census. Complete event audits
account for all 8,928 compiler outcomes and all 455 runtime outcomes, with balanced
function, normalization, legalization and retry activity. The compiler replay
returns the expected blocked-selection status, without a complete object.

Selection counts do not establish complete compiler/runtime objects, compiler
startup, behavior or self-rebuilding capability. Dependency coverage remains
conservative. Diagnostic timings include profiling and concurrent validation;
they are not a compiler-throughput comparison.

## Classified remaining work

The largest final compiler groups, grouped by the full diagnostic/tag/detail
tuple, are:

| First rejection | Functions |
| --- | ---: |
| Unknown integer call argument | 440 |
| Readonly-table global address | 225 |
| General stage-two value representation | 133 |
| Alloca type, main diagnostic | 123 |
| Inspected comparison type | 102 |
| Freeze width | 92 |

Each of the 440 retained unknown-argument calls has exactly one unresolved
nonliteral candidate. In 326 functions this is the same i64 constant expression:
`ptrtoint` of a GEP at byte offset 1120 into
`Io.Threaded.global_single_threaded_instance`. The other candidates are i32
`undef` in 86 functions, i64 `poison` in 22 and i64 `undef` in six. The observer
retains the complete call, not a dedicated failing-argument marker; candidate
classification is explicitly separate from that recorded evidence.

All 133 general value failures have an attributed private definition, across
twenty shapes. The largest are 67 `<16 x i1>` comparison results, thirteen
`<2 x ptr>` loads, nine `{ i64, i1 }` freezes, eight fp128 calls and seven fp128
loads. Three runtime value failures are `<2 x i128>` insertions.

All 128 allocation failures across diagnostics have attributed types and
attributes: 123 main failures and five varargs failures, across forty shapes.
Leading forms are thirty fp128 slots aligned to sixteen bytes, twenty arrays of
two `%sort.block.Pull` values, seventeen 4,096-byte arrays, and ten one-element
arrays of `{ ptr, i64 }`. These are distinct layout and representation contracts.

Next, extend shared symbolic-address materialization for integer call arguments,
then classify the 225 readonly-table rejections. Preserve relocation identity,
checked addends, aliases, simultaneous transfers and register effects; replay
both complete inputs after each repair. Keep undef/poison handling as an explicit
semantic decision. Vector masks, pointer vectors, aggregate SSA values and
allocation layouts should follow their measured concrete shapes.

## Acceptance and preservation

Debug and ReleaseSafe each pass 1,965 unit tests and 21 structural checks.
Profiling tests, five whole-compiler report checks and readiness pass. Both new
native populations pass against the frozen Debug and ReleaseFast compilers,
adding 28,416 local observations and 14,208 LLVM references per compiler build.
Both independent production replays and their complete event audits pass.
All 17 integration gates and 60 native populations pass. Cumulative native
coverage records 1,942,788 local observations against 971,394 LLVM references,
preserving every one of the 58 preceding population records and fixture sources.
Each compiler-core mode lowers, emits and links 100 functions and executes twelve.
The bypass ratchet remains 130. All five fixed Zig programs, 87 larger Zig
input/mode pairs with 603 controls, and 138 C input/mode pairs with 552 controls
are preserved. Core controls retain 21 function/mode pairs, 22,788 observations
and all 54 fault detections.

All 36 core records preserve selected object bytes and every execution
observation. Local linked-executable sizes are unchanged. Twenty-four LLVM
reference wrappers, in Fast and Safe modes, are 32 or 40 bytes smaller; all
twelve Small-mode sizes match. Executable hashes are recorded separately.
The initial post-run size-equality check stopped on this difference, and its
false result is retained. The existing stable-core comparison already excludes
reference sizes and executable hashes. A separate metadata review records the
exact deltas and confirms unchanged harness/runner sources. The shorter
validation path is a plausible explanation, not a proven section-level identity:
the runner removes temporary cohort executables, so old/new section equality
is not claimed. No compiler or executable test expectation was changed.

The final 1,761-file source snapshot, both compiler binaries, original input
hashes and compiler-input inode verify. All thirteen user scratch files and all
1,891 artifacts from the preceding accepted checkpoint verify. No archives or
manual cache cleanup were performed. The lowest additional disk sample is
36,476,002,304 bytes and final recorded availability is 37,874,925,568 bytes,
above the 24,359,738,368-byte execution reserve. Admission remains
32,949,672,960 bytes. The artifact manifest and its hash are recorded in the
machine-readable acceptance file.
