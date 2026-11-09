# Active direction

The user authorized the [narrow freeze slice](plans/2026-11-08-narrow-freeze.md).
Implementation and validation are in progress; the accepted checkpoint below
remains authoritative until its complete validation passes. The 94 classified
first failures use i1/i3/i8/i10/i16 in EAX, 32-bit scratch registers and scalar
spill slots. Preserve their existing carriers and validate aliases and consumers.

The [checked-multiply operand slice](plans/2026-11-08-checked-multiply-operands.md)
is complete and accepted at `29e034a7`. Compiler selection is **7,713/8,928**:
56 additions, preserving all 7,657 preceding successes. Runtime stays
**284/455**. Both complete production replays match their censuses and pass
event audits. The full serial run passes 17 gates and 63 native populations,
preserving all 62 preceding populations and all 36 stable core records. See the
[evidence](evidence/checked_multiply_operands.md) and
[acceptance record](evidence/checked_multiply_operands_acceptance_20261108.json).

All 59 `composed-block-smulo-i64-rhs` failures advance. Shared scalar transfers
now materialize their constant operands through the existing register and
rollback contracts while retaining argument facts. Fifty-six functions select;
the later rejections are `composed-block-freeze-width` in `link.Coff.addReloc`
and `link.Elf2.addGlobalSymbol`, and `stage2-phi-dst` in
`codegen.wasm.CodeGen.airSwitchBr`. The repaired multiply boundary should not be
repeated. Literal accumulator operands retain their existing boundary.

Debug and ReleaseSafe each pass 1,983 units and 23 structural checks. The new
eight-function native population passes all modes and both routes with Debug
and ReleaseFast compilers. All nine readiness commands, both input corpora,
five fixed programs and 54 core fault controls pass. The suite records
1,968,132 local observations against 984,066 references.

The remaining classified groups are prioritization evidence for a subsequent
bounded task. Their concrete definitions should be inspected before choosing
the next repair. Leading groups include
133 general-value failures, 123 main allocation failures, 115 unknown call
arguments, 102 comparisons, 94 freeze-width failures, 90 call-attribute ABI
failures, 72 load-type failures and 59 immediate-comparison range failures.
General-value observations include 67
`<16 x i1>` comparisons and thirteen `<2 x ptr>` loads. Allocation observations
include fp128 slots, `%sort.block.Pull` arrays and large byte arrays. The 115
unknown call arguments are i32 undef (86), i64 poison (23) and i64 undef (six);
keep their semantics as a separate decision.

Raw evidence is under `local-state/validations/checked-multiply-20261108/`.
Preserve the twelve-function core cohort, ratchet 130 and every execution
population. The suite Debug binary matches the frozen Debug binary exactly;
review wrapper metadata separately from selected objects and observations.
No complete compiler/runtime object, startup or self-rebuild is claimed.

The 20 GB admission and 11.41 GB execution-reserve settings retain their prior
fresh/cache acceptance and unchanged 8 GiB working allowance. Reuse the
authenticated `local-state/caches/quoted-symbols-20261108` generation when its
inputs match. Finish any cache retirement before validation; preserve original
inputs, accepted evidence, AIR payloads and all thirteen scratch files. Create
no archives. See the [headroom policy](retention_headroom_policy.md#headroom).

## Preceding checkpoints

The [quoted-symbol checkpoint](evidence/quoted_symbol_addresses.md) at
`a9e9c0f1` selected 7,657 compiler and 284 runtime definitions, with fresh and
cached full runs passing 17 gates and 62 native populations. It closed the
225 quoted-table first failures with 216 additions. Its checked-multiply
recommendation is completed by the current checkpoint above.

The [symbolic integer call-address checkpoint](evidence/symbolic_call_addresses.md)
at `b43dd3dc` selected 7,441 compiler and 284 runtime definitions, with all 17
gates and 61 native populations passing. Its quoted-table recommendation is
completed by the current accepted slice.

The [syscall and comparison checkpoint](evidence/syscall_selection_reduction.md)
at `111f2e0a` selects 7,116 compiler and 284 runtime definitions, with all 17 gates
and 60 native populations passing. It establishes typed syscall facts/tail hints
and full-width transfers for named `samesign ult i64` comparisons. Its symbolic
call-address recommendation is completed by the accepted checkpoint above.

The [global TLS, scalar intrinsic and pressure checkpoint](evidence/global_intrinsics_pressure.md)
at `4b8eac2a` selects 7,040 compiler and 284 runtime definitions, with all 17 gates
and 58 native populations passing. It establishes shared general-dynamic TLS,
scalar bit-intrinsic widths/facts and dynamic allocation/frame admission. Its
syscall and comparison recommendations are implemented by the current frozen
accepted slice above.

The [constant-address, intrinsic-fact and wide ABI checkpoint](evidence/address_intrinsic_wide_abi.md)
at `761ea199` selects 6,752 of 8,928 compiler definitions and 274 of 455 runtime
definitions. All 17 integration gates and 53 native populations pass. Its
global-property, intrinsic and pressure recommendations are implemented by the
accepted `4b8eac2a` checkpoint above.

The [census classification and integer ABI checkpoint](evidence/census_integer_abi.md)
at `baf7a767` selected 4,341 of 8,928 compiler definitions and 274 of 455 runtime
definitions. All 17 integration gates and 50 native populations passed. Its
constant-pointer, advisory-intrinsic and wider-carrier recommendations are now
completed by `761ea199`.

The [compiler parser and runtime cast plan](plans/2026-11-07-compiler-parser-vector-casts.md)
is complete at `57a78095`. All 8,928 compiler definitions and the full unchanged
compiler module parse; all 455 runtime definitions verify. All 17 integration
gates and 47 native populations pass. See the
[evidence](evidence/compiler_parser_vector_casts.md) and
[acceptance record](evidence/compiler_parser_vector_casts_acceptance_20261107.json).

At that checkpoint, the next slice was allocation-related parameter attributes.
Verification first rejected `allocptr` on `free`'s declaration at input line 737421. The
LLVM-valid `local-state/validations/parser-vector-20261107/next-allocptr.ll`
reproducer led to the accepted [allocation/runtime-memory repair](evidence/allocation_runtime_memory.md).
Vector GEP result semantics were a separate gap after their syntax repair.

That earlier runtime census examined all 455 definitions: 265 succeeded and 190 rejected,
with complete diagnostics and capability grouping retained under
`local-state/validations/parser-vector-20261107/`. Its first failure was memset
attributes; `sincos_f32` then rejected ordinary scalar FP pointer loads. Those
repairs were subsequently accepted through shared memory/register contracts.
No complete compiler or runtime object, compiler startup or self-rebuild is
claimed. Preserve the 12-function core cohort, ratchet 130 and all existing
populations. Admission and runtime reserve remain 32.95 GB and 24.36 GB.

The entries below describe preceding checkpoints.

The [whole-compiler diagnostic plan](plans/2026-11-07-whole-compiler-diagnostic.md)
is complete as a diagnostic; compiler emission remains blocked. The pinned
LLVM-enabled ReleaseFast configuration produces 443.6 MB of optimized compiler
IR with 8,928 definition lines. Local parsing stops on a packed aggregate
global. Independent syntax census records 111 packed-global rejections among
36,959 global/alias lines. The executable build separately stops on runtime
verification: vector `fptrunc` in `compiler_rt.sincos.sincos_f32` is rejected
with `InvalidCast`. No compiler object, executable or self-rebuild is accepted.
See the [report](evidence/whole_compiler_diagnostic.md) and
[record](evidence/whole_compiler_diagnostic_20261107.json).

That diagnostic selected shared packed aggregate support, using
`test/whole_compiler/packed_global.ll` and the retained complete compiler IR.
Packed aggregate support, the subsequent parser repair and the runtime vector
cast slice are now complete. The twelve-member cohort and all accepted
populations are preserved. This direction superseded the earlier isolated AIR
error-returning function recommendation.

Raw diagnostics and exact configuration are under
`local-state/validations/whole-compiler-20261107/attempt-4/`. Use the new runner's
`--input-ir` mode for backend replay. Both census tools and focused controls
pass; original probes and compiler/provider hashes verify. Postcheck free space
is 39.64 GB. Admission remains 32,949,672,960 bytes and execution reserve
24,359,738,368 bytes. No archives were created. The older worker-inbox directive
remains historical and superseded.

The entries below describe preceding checkpoints.

The [compiler-core memory and width execution plan](plans/2026-11-07-compiler-core-execution-breadth.md)
is complete at `c08b98d1`. Guarded event resets and packed 64-bit conversions
extend the fixed-prefix cohort from nine to twelve executed functions per mode.
All 45 fresh/cache records match, and all 17 integration gates pass on the
verified frozen source. The 54 fault controls, both input corpora, five fixed
Zig programs and all 45 native populations pass. See the
[acceptance record](evidence/compiler_core_memory_width_acceptance_20261107.json)
and [evidence](evidence/compiler_core_memory_width.md).

The preceding recommendation was callable error-returning compiler-core
execution. `fmt.charToDigit` fails typed AIR lowering on its `error!u8` contract.
Establish Zig-owned payload layout, error-code and calling-convention facts,
then execute the unchanged function on valid and invalid character/base pairs.
It lies outside the 100-row prefix, so declare any additional execution
population separately. Preserve the twelve-member cohort and existing programs.
The retained diagnostic does not prove that payload width is its only gap.

Historical core evidence remains in `local-state/validations/core-execution-20261107/`.
Current core evidence and authenticated AIR use the `quoted-symbols-20261108`
validation and cache roots described above. The superseded AIR payloads are
retired in the [quoted-symbol cleanup](evidence/quoted_symbol_space_cleanup_20261108.json).
At the older core checkpoint, admission was 32,949,672,960 bytes and the execution
reserve was 24,359,738,368 bytes; the current limits are 20,000,000,000 and
11,410,065,408 bytes. That checkpoint's lowest additional disk sample was
40.53 GB and final recorded free space was 41.10 GB. Original probes, prior
evidence and compilers remain; no archives were created. The older worker-inbox
directive is historical and remains superseded.

The entries below describe preceding checkpoints.

The [large-function selection performance plan](plans/2026-11-07-large-function-selection-performance.md)
is complete at `82f485c0`. The shared identifier comparator avoids repeated
parsing while preserving the existing grammar, numeric namespaces and temporary
names. Five alternating Safe comparisons reduce median compiler time from
26.59 to 16.91 seconds for Fibonacci (36.4%) and from 29.13 to 18.68 seconds for
migration (35.9%). Fast/Small migration also improves; the short Fibonacci
measurements remain unresolved. All timed object/owner bytes and all non-timing
profile fields match. See the
[acceptance record](evidence/large_function_selection_performance_acceptance_20261107.json)
and [measurements](evidence/large_function_selection_performance.md).

All 17 gates pass on the verified frozen source. Debug and ReleaseSafe each pass
1,915 unit tests and 30 policy checks; ABI, structural, captured-object, route and
readiness checks pass. Both input corpora, the five fixed Zig programs and all
45 native populations remain green. The 36 core records match prior fresh
execution, retaining 100 lowered/emitted/linked and nine executed per mode.

That performance slice did not expand the cohort. Selection itself remains the
largest Safe profile cost; further performance work should measure inside that phase.
The older cohort-v3 inbox directive remains historical: it predates the accepted
nine-function cohort. Preserve the original probes and create no archives.

The [unchanged Zig input-program plan](plans/2026-11-06-unchanged-zig-input-program.md)
is complete at `9cc31c38`. The pinned language-reference migration tool runs
unchanged with runtime document input, allocation, mutable directives, generated
files and error paths. All 87 input/mode pairs and 603 observation controls pass,
with identical independent ownership replay in Fast, Safe and Small. Three Safe
backend gaps are repaired through shared lowering and executable regressions.
See the [acceptance record](evidence/zig_input_program_acceptance_20261106.json)
and [implementation evidence](evidence/zig_input_program.md).

All 17 integration gates pass. All five existing fixed Zig programs and the C
parser remain green; the parser passes 138 input/mode pairs and 552 observation
controls. Compiler-core counters remain 100 lowered/emitted/linked and nine
executed functions per mode, with all 36 records matching prior fresh execution.
All 45 native populations pass. Original probes and diagnostic worktrees remain.

The [project cleanup](evidence/project_space_cleanup_20261106.json) removes
7.24 GB of allocated data across three audited intervals, including 185.56 MB
of cache regenerated during full validation. This is not a net project-size
change. Current AIR, compiler binaries and prior evidence remain; no archives
were created. That cleanup checkpoint recorded 53.30 GB free; the subsequent
performance acceptance records 51.22 GB free after builds and retained evidence.

The preceding [compiler selection performance plan](plans/2026-11-06-compiler-selection-performance.md)
completed at `fbb249a7`. Profile v2 attributes
time and allocation work to functions and legalizers; nine legalizers defer
candidate copying until the first rewrite. See the
[acceptance record](evidence/selection_performance_acceptance_20261106.json) and
[measurements](evidence/selection_performance.md).

Five alternating comparisons on the retained Safe Fibonacci IR reduce median
ReleaseFast compiler time from 29.78 s to 27.28 s (8.4% less) and median peak RSS
by 60.0%. Logical legalizer allocations fall 70.7%. Every benchmark object and
ownership manifest is byte-identical, with unchanged per-function/per-stage
counters. Profiling overhead is unresolved within sample variation. Twenty-five
parser comparisons per compiler show no regression at 10 ms timing resolution.

Both Fibonacci and the document-input corpus remain useful performance inputs.
Block-sort specializations and the DWARF stack-machine interpreter remain among
the expensive functions after the shared comparison repair. Ownership replay
still duplicates selection work. Ordered scans and original-form retries remain.
Keep extending the common transfer contract when addressing pair/vector PHIs
and spill destinations; those cases and ordinary CLI structural
selection still use their existing paths. Generated-code optimization quality
remains a separate measured milestone.

For large development gates, use a ReleaseFast compiler while retaining Debug
tests. Unchanged programs obtain ownership during object emission; independent
replay remains a permanent route/corpus regression and is available with
`--replay-owners`. Storage thresholds remain 32,949,672,960 bytes before starting
and 24,359,738,368 bytes during execution. No archives were created.

The entries below describe earlier milestones. The requested
[Python-to-Zig tooling migration](evidence/python_tools_migration_20261105.json)
completed at `978ffaf9`. All nine maintained Python modules were replaced using
the pinned `zig-process` and `zig-test-support` sources. All 22 policy/provider tests pass in
Debug and ReleaseSafe, all 17 integration gates pass, and the final log matches
all 1,430 canonical records from the Python-backed accepted run. The separate
fresh/cache replay matches all 24 records across three modes. The frozen
15-pair performance matrix retains its supported outcomes and semantics;
cross-engine timings do not establish a speedup. See the
[tool commands and scope](validation_tools.md).

Obsolete build caches and the verified temporary export cache were removed,
with hashes, metadata and reports retained. No archives were made. The compiler
source and accepted status remained unchanged during that tooling task.
At that tooling checkpoint, unchanged Safe had 46 emission failures; the first was
`debug.writeCurrentStackTrace` / `inline-asm-call`. Fixed acceptance counters
remain 100 lowered/emitted/linked and five executed functions per mode, with
compiler-rt bypass ratchet 130.

The [architecture refactor plan](roadmap/architecture_refactor_plan.md) is
complete for its bounded scope: four refactors, the memset shared-lowering
capability, the correctness checkpoint and the
[fixed-program performance baseline](evidence/fixed_program_baseline.md).
The baseline records two runs of five workloads across three explicit routes,
with semantic checks and all three metrics for 14 supported pairs. The loop-memory
`release-o3` pair rejects with `TypeMismatch`; that optimizer limitation is
recorded separately and does not acquire invented performance results.

The [checked memcpy family](evidence/composed_memcpy_family.md) is now complete
for the retained `ssp.__memcpy_chk` and `memcpyFast` definitions. Shared composed
lowering, native comparisons, the ABI differential gate and all 17 integration
subgates pass. The frozen performance matrix retains its supported outcomes and
semantic results; two local memset code sections grow by 11 bytes for the
byte-GEP preservation repair. Timing differences do not establish a speedup.

The subsequent [scalar byte-loop slice](evidence/composed_byte_loops.md) closes
the retained `ssp.__strncpy_chk` definition and moves retained `bcmp`/`memcmp`
to composed lowering. A bounded shared-return proof fixes their verifier
rejection. Native comparisons, protected-page checks, ABI checks and all 17
integration subgates pass. The frozen performance matrix retains all outcomes,
semantic results and object hashes from the memcpy checkpoint.

The [loop-memory repair slice](evidence/loops_memory_repair.md) repairs the
frozen `loops_memory/release-o3` optimizer `TypeMismatch`. SROA scalarizes single-element
aggregates with direct field loads/stores, and `mem2reg` enforces alloca-type
safety. Focused regressions and the behavioral differential suite pass. Semantic
and runtime driver outputs match Clang-22 -O3 byte-for-byte across all 272
observations. The matrix is versioned to `fixed-architecture-programs-v2` with all
15 pairs supported, and repeated measurements are recorded while preserving the
original frozen manifest and baseline evidence.

The [cyclic byte-vector transfer slice](evidence/cyclic_byte_transfers.md) admits
cyclic `<16 x i8>` vector loads and stores in composed x86-64 loops with a verified
loop-carried XMM ownership proof. Invariants enforce block-local vector life cycle,
sequential single-register ownership, absence of loop-carried XMM phi values, and
no external vector escapes. Machine structure, assembly (`movups`), and bit-exact
runtime execution pass across 0, 32, and 64 byte inputs.

## Historical checkpoints

The counts and failures below describe earlier checkpoints. Current accepted
capability and the next action are recorded above.

The earlier accepted [integer arithmetic and hash checkpoint](evidence/fibonacci_arithmetic_acceptance_20261105.json)
at `9a8cc1c9` passes all 17 integration stages. Accumulator-address stores,
narrow integer normalization and ABI carriers, constant two-word stores, and
bounded i128 arithmetic preserve values and live operands. Reusing generated
scalar words closes the unchanged `Wyhash.hash` and `Wyhash.init` emission rows.
Immediate arithmetic and shifts now preserve live RCX sources and aliases in
both typed and production dispatch; executable regression and rollback checks
cover the repair. The i16 integration oracle now accounts for truncation before
the reverse shift, with LLVM and local execution agreeing on `0x0234`.
Native fixture accounting and provenance derive from the shared registry.

All 1,862 unit tests, 13 structural checks, 38 captured objects, readiness and
frozen executable canaries pass. The four added native populations check
162,816 local observations against 81,408 LLVM references in all three modes.
All 35 native populations and the unchanged 100-row/five-function cohort pass.
Minimum free space is 35.46 GB, above the unchanged 24.36 GB reserve.
The [focused evidence](evidence/fibonacci_arithmetic_focused_20261105.json)
retains component mutation controls, both earlier integration failures and
their fixes, exact source identities, and the native `Wyhash.init` check.

Unchanged pinned Fibonacci executes all six assertions in Fast and Small with
LLVM-equivalent exit status, stdout and stderr. Safe emits 1,522 of 1,568
functions; 46 failures still prevent whole-program emission and execution.
The first was `debug.writeCurrentStackTrace` / `inline-asm-call`.
The broader i65/i96 work remains an uncommitted diagnostic draft under
`local-state/worktrees/fibonacci-crash-investigation`; it is excluded from this
acceptance. The thirteen original scratch probes remain unchanged; no archives
were made. That slice was stopped at the user's request; subsequent authorization
led to the accepted completion above.

The earlier accepted [atomic, pointer, frame and call checkpoint](evidence/fibonacci_state_acceptance_20261105.json)
at `4242debd` passes all 17 integration stages. Scalar atomics preserve old
values and compare-exchange success flags. Pointer and two-word values retain
symbols and layout, and boolean branches consume the low bit even when upper
bits are dirty. Bounded frame addresses and scaled indexes preserve byte offsets;
CFG scheduling respects definitions. Direct C integer/pointer variadic calls
support up to sixteen arguments through the existing register and stack paths,
and ordinary known function addresses retain module-owned symbol names.
All 1,847 unit tests, 13 structural checks, captured-object smoke, readiness and
frozen executable canaries pass. The four added populations check 153,996 local
observations against 76,998 LLVM references. Each component also rejects its
36 mutation controls. All 31 native populations and the unchanged 100-row/five-function
cohort pass. Minimum free space is 33.03 GB, above the 24.36 GB reserve.
Unchanged pinned Fibonacci executes all six assertions in Fast and Small with
LLVM-equivalent exit status, stdout and stderr. Safe emits 1,478 of 1,568
functions; 90 failures still prevent whole-program execution. The remaining
scalar, memory, vector, CFG and ABI forms, pinned runtime linkage and mandatory
three-mode Fibonacci regression remain open.
The [focused evidence](evidence/fibonacci_state_focused_20261105.json) records
source identity, component checks and the repaired boolean regression. Full-width
accumulator aliases now survive immediate arithmetic and spills; the old poisoned
high-half failure and its regression tests are retained. The separately diagnosed
narrow arithmetic-shift error remains in this checkpoint; its tested prototype
repair awaits the next cumulative full integration. The
thirteen original probes remain unchanged; no archives were made.

The earlier accepted [integer-intrinsic and comparison checkpoint](evidence/fibonacci_intrinsics_acceptance_20261105.json)
at `fb39db75` passes all 17 integration stages. Scalar saturating operations,
narrow extrema and bit reversal preserve significant bits and live operands.
Compare staging now saves overlapping operands: the confirmed `umax33(1, 0)`
wrong-code case returns one. Select condition formation also preserves its arms.
All 1,827 unit tests, 13 structural checks, captured-object smoke and readiness
pass; focused tests pass in all three release modes. The added native population
checks 87,552 local observations against 43,776 LLVM references, and all 36
mutation controls are rejected. All 27 native populations and the unchanged
100-row/five-function cohort pass. Minimum free space is 33.59 GB, above
the 24.36 GB reserve. Unchanged pinned Fibonacci executes all six assertions in
Fast and Small with LLVM-equivalent exit status, stdout and stderr. Safe emits
1,289 of 1,568 functions; 279 failures still prevent whole-program execution.
The disk sampler accepts disappearing linker temporary files only when every
owned root still has a complete count; other sampling errors remain failures.
A fresh export and a cache hit on its exact authenticated bundles check the
same three cohorts.
The [focused evidence](evidence/fibonacci_intrinsics_focused_20261105.json)
records source identity and checks. The thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [word arithmetic and switch checkpoint](evidence/fibonacci_flow_acceptance_20261105.json)
at `be90e939` passes all 17 integration stages. Full-word division, remainder,
checked products, signed checked sums, extrema and byte swaps preserve exact
results and live inputs. Fixed-register arithmetic receives spill capacity
without eagerly relocating all parameters. Private switch chains support wide
conditions and large case lists; the bounded CFG envelope now admits 1,024 blocks.
All 1,822 unit tests, 13 structural checks, captured-object smoke and readiness
pass. Focused word and switch tests pass in all three release modes. The two
added native populations pass 55,680 local observations against 27,840 LLVM
references, with 66 mutation controls. All 26 native populations and the unchanged
100-row/five-function cohort pass. Minimum free space is 33.58 GB, above
the 24.36 GB reserve. The unchanged pinned Fibonacci program still passes all
six assertions in Fast and Small with LLVM-equivalent exit status, stdout and
stderr. Safe emits 1,264 of 1,568 functions; 304 failures still prevent a local
object and whole-program execution. The [focused evidence](evidence/fibonacci_flow_focused_20261105.json)
records the source identity and checks. All thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [checked-integer and address checkpoint](evidence/fibonacci_checked_acceptance_20261105.json)
at `9b6bf0c8` passes all 17 integration stages. Stack addresses can flow through
pointer PHIs, selects, stores, casts and returns. Call preservation saves all
live aliases. Signed and unsigned checked arithmetic covers widths one through
32, and general boolean calls preserve their low ABI bit through pointer,
indirect and stack-argument calls. Zero extension from i32 clears stale upper
accumulator bits. All 1,812 unit tests, 13 structural checks, 13 focused tests per
release mode, captured-object smoke and readiness pass. The two added native
populations pass 49,920 local observations against 24,960 LLVM references,
with 54 mutation controls. All 24 native populations and the 100-row/five-function
cohort pass. Minimum free space is 36.14 GB, above the 24.36 GB reserve.
The unchanged pinned Fibonacci program still passes its six assertions in Fast
and Small with LLVM-equivalent exit status, stdout and stderr. Safe emission
reaches 1,155 of 1,568 functions; 413 failures still prevent a local object and
whole-program execution. The [focused evidence](evidence/fibonacci_checked_focused_20261105.json)
records the two wrong-code repairs and exact source equivalence. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [Fibonacci foundation checkpoint](evidence/fibonacci_foundation_acceptance_20261105.json)
at `580a866f` passes all 17 integration stages. Named indirect calls, seven to
sixteen word/pointer arguments, checked word arithmetic and narrow comparisons
use the existing scalar and System V machinery. Bounded storage supports objects
through 64 KiB and total frames through one MiB, with page touches that preserve
incoming arguments. All 1,803 unit tests, 13 structural checks, 22 storage tests
per release mode, captured-object smoke and readiness pass. The four added native
populations pass 38,400 local observations against 19,200 LLVM references;
eighteen protected-stack checks verify page probing. Earlier populations and the
100-row/five-function cohort retain their counts. Minimum free space is
38.80 GB, above the 24.36 GB reserve.
The unchanged pinned upstream Fibonacci program now executes all six assertions
in ReleaseFast and ReleaseSmall, matching LLVM exit status, stdout and stderr.
ReleaseSafe remains incomplete: 1,025 of 1,568 selected functions emit, and 543
fail. Remaining Safe value flow, arithmetic, memory, control flow and the real
compiler runtime link precede three-mode acceptance. The
[focused evidence](evidence/fibonacci_foundation_focused_20261105.json) records
source equivalence, exact validation and remaining boundaries. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [scalar startup checkpoint](evidence/scalar_forms_acceptance_20261105.json)
at `d8c135e5` passes all 17 integration stages. Unsigned minimum and signed
less-equal forms reuse scalar compare/select operations. Switch PHI edges retain
original block identities and privately owned machine labels. Bounded stack
memset preserves exact extents and memory boundaries. All 1,788 unit tests,
13 structural checks, 14 focused tests per release mode, captured-object smoke
and readiness pass. Ten native functions pass 3,840 local observations against
1,920 LLVM references; twenty-four mutation controls reject wrong results.
Seventeen earlier native populations and the 100-row/five-function cohort retain
their counts. Minimum free space is 31.29 GB, above the 24.36 GB reserve.
At this source revision, the unchanged canonical Fast capture emits 24 of 34
selected functions and rejects ten, first at `Io.Writer.defaultRebase indirect-call`.
No complete local Fibonacci object or execution is claimed for this checkpoint.
Indirect calls, stack arguments and remaining scalar forms precede execution;
Safe retains its larger separate frontier. The [focused evidence](evidence/scalar_forms_focused_20261105.json)
records the exact validation and unsupported boundaries. All thirteen original
probes remain unchanged; no archives were made.

The earlier accepted [aggregate storage checkpoint](evidence/aggregate_storage_acceptance_20261105.json)
at `fa2371d0` passes all 17 integration stages. Module-owned integer/pointer
layouts up to 256 bytes retain exact padding and alignment. Flat two-word values
support loads, stores, insertion, extraction and ordinary call/return carriers.
Shared frame planning preserves scalar values across stores and argument
permutations, including final-use operands. The 1,783-test unit population,
13 structural checks, 26 focused tests per release mode, captured-object smoke
and readiness pass. Twelve native functions pass 4,608 local observations against
2,304 LLVM references; eighteen mutation controls reject wrong values. Sixteen
earlier native populations and the 100-row/five-function cohort retain their counts.
Minimum free space is 36.84 GB, above the 24.36 GB reserve.
The unchanged canonical Fast capture emits twenty of 34 selected functions and
rejects fourteen, first at `start.expandStackSize composed-block-llvm-intrinsic`.
No complete local Fibonacci object or execution is claimed. Scalar/memory forms,
switch PHI edges, indirect calls and stack arguments remain. Safe retains its
separate larger frontier and real stack-probe runtime requirement. The
[focused evidence](evidence/aggregate_storage_focused_20261105.json) records the
bounded envelopes and validation provenance. All thirteen original probes remain
unchanged; no archives were made.

The earlier accepted [narrow ABI checkpoint](evidence/narrow_abi_acceptance_20261105.json)
at `85f557e9` passes all 17 integration stages. Private register carriers
normalize unannotated integer parameters, returns and ordinary calls at widths
one through sixteen, including direct boolean branches and boolean xor. Ordinary
call preparation now reserves storage for instruction-produced final-use arguments.
All 1,778 units, 13 structural checks, 58 focused tests in each release mode,
captured-object smoke and readiness pass. Thirteen native functions pass 4,992
local observations against 2,496 LLVM references; eighteen mutation controls
reject wrong values. Fifteen earlier populations retain their counts, as do the
100-row/five-function cohort and bypass ratchet. Minimum free space is
39.17 GB, above the 24.36 GB reserve.
The canonical Fast capture emits sixteen of 34 functions and rejects eighteen,
first at `start.expandStackSize composed-block-llvm-intrinsic`. Small has the same
counts. Safe is a separate, larger frontier: conservative selection includes
1,568 functions, of which 206 emit and 1,362 reject. Its LLVM reference also needs
the real `__zig_probe_stack` runtime when linked. No complete local Fibonacci
object or execution is claimed. The [focused evidence](evidence/narrow_abi_focused_20261105.json)
records these mode-specific results and retained scalar limits. All thirteen
original probes remain unchanged; no archives were made.

The earlier accepted [constant remainder checkpoint](evidence/constant_remainder_acceptance_20261104.json)
at `cf1b30cd` passes all 17 integration stages. Unsigned remainder by a
constant power of two now uses the existing AND lowering at 8/16/32/64 bits,
including divisor one and high-bit divisors with signed or unsigned spelling.
The original IR remains unchanged. Existing preservation/home limits remain;
the [focused evidence](evidence/constant_remainder_focused_20261104.json) retains
the frameless loaded-RAX limitation for a 2^32 divisor.
All 1,773 units, 13 structural checks, 32 focused tests in each of ReleaseFast
and ReleaseSafe, captured-object smoke and readiness pass. Eight native functions
pass 3,072 local observations against 1,536 LLVM references, and twelve mutation
controls reject wrong masks or lost live inputs. Fourteen earlier populations,
the fixed 100-row/five-function counts and bypass ratchet remain unchanged.
Minimum reported free space is 41.68 GB, above the 24.36 GB reserve.
Fibonacci still emits ten of 34 selected functions and rejects 24, now first at
`start.expandStackSize composed-block-call-arg-width`. No complete local object
or whole-program execution is claimed. All 13 original probes remain unchanged;
no archives were made.

The earlier accepted [RAX pointer-load checkpoint](evidence/rax_load_acceptance_20261104.json)
at `c6b46f0c` passes all 17 integration stages on a frozen 2,726-file snapshot.
Ordinary integer and pointer loads now stage RAX addresses before preparing the
accumulator result, using the same typed address helper as stores. Physical write
planning and both admission paths agree. Live pointers and scratch values survive;
width/class restrictions, EFLAGS and transaction rollback remain checked.
Seven native functions pass 2,688 local observations against 1,344 LLVM references
across direct/release routes in three modes, including exact-width protected-page
loads, skipped null-slot branches, 56-byte stride loops, helper calls and guards.
Twelve mutation controls reject oversized reads and corrupted live values.
All 1,770 units, 13 structural checks, 17 focused tests each in ReleaseFast and
ReleaseSafe, captured-object smoke and readiness pass. The thirteen earlier
native populations, fixed 100-row/five-function counts, legacy selection and
bypass ratchet stay unchanged. Minimum reported free space is 44.14 GB,
above the 24.36 GB reserve. The retained loop and branch now emit objects.
Fibonacci still emits ten of 34 selected functions; it next rejects unsigned
remainder by 4096 at `start.expandStackSize composed-block-binary-imm-rhs`.
Local whole-program execution remains zero. All 13 original probes remain
unchanged; no archives were made.

The earlier accepted [general array stride checkpoint](evidence/general_stride_acceptance_20261104.json)
at `a81a36fe` passes all 17 integration stages on a frozen 2,720-file snapshot.
Literal integer arrays now use allocation strides from 1 to 255 bytes through
the existing typed address action, including the capture's 56-byte stride.
Stack descriptor and read-only table restrictions remain unchanged. Five native
functions pass 1,920 local observations against 960 LLVM references across
direct/release routes in three modes, checking padding, nesting, negative and
wrapping indexes, helper calls, live values and guarded stores. Twelve mutation
controls reject wrong strides and stores. All 1,766 units, 13 structural checks,
18 focused tests each in ReleaseFast and ReleaseSafe, and readiness pass. The
twelve earlier native populations, fixed 100-row/five-function counts, legacy selection and
bypass ratchet stay unchanged. Minimum reported free space is 45.54 GB,
above the 24.36 GB reserve. Fibonacci still emits ten of 34 selected functions;
its next boundary is an ordinary i32 load through an RAX pointer in
`start.expandStackSize`, reported as `composed-block-load-ptr`. A retained small
loop reproduces it and compiles with Clang; local whole-program execution is
still zero. All 13 original probes remain unchanged; no archives were made.

The earlier accepted [bounded frame checkpoint](evidence/bounded_frame_acceptance_20261104.json)
at `d389d135` passes all 17 integration stages on a frozen 2,714-file snapshot.
Exact integer pairs and padded 16-byte and 24-byte wrappers now reuse existing
frame storage through private codegen views and typed address operations.
Complete layout, alignment and extent checks preserve the source IR and reject
unsupported forms. Four permanent functions pass 768 local observations against
384 LLVM references across direct/release routes in three modes, including mixed
pair/wrapper copies, defined padding, helper calls, live values and guards.
All 1,763 units, 13 structural checks, focused release tests and readiness pass.
The unchanged Fibonacci capture now emits 10 of 34 selected functions and reaches
`start.expandStackSize composed-block-array-gep-stride` for a 56-byte stride;
whole-program execution remains blocked. The 100-row/five-function populations,
eleven earlier native populations, legacy selection and bypass ratchet remain
unchanged. Minimum reported free space is 45.91 GB, above the 24.36 GB reserve.
All 13 original probes remain unchanged; no archives were made.

The earlier accepted [dependency-coverage checkpoint](evidence/dependency_coverage_acceptance_20261104.json)
at `811aa4ba` passes all 17 integration stages on a frozen 2,708-file snapshot.
Bounded attributes, metadata and typed constants now establish complete reference
coverage; unsupported forms remain conservative. Retained raw metadata roots
survive constant merging, and inferred function attributes precede trailing
metadata. All 1,756 units, 13 structural checks and readiness pass. Five optimizer
pipelines add 400 LLVM-backed observations of locally optimized IR. The unchanged
Fibonacci capture selects 34 functions and 16 globals/aliases, matching LLVM after
serialization-only SSA normalization, but still rejects aggregate stack storage.
Three authenticated exports are reused with fresh execution checks. The fixed
100-row/five-function populations, eleven native populations, legacy selection
and bypass ratchet remain unchanged. Minimum reported free space is 47.84 GB,
above the 24.36 GB reserve. All 13 original probes remain; no archives were made.

The earlier accepted [symbol identity checkpoint](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes all 17 integration stages on a frozen 2,691-file snapshot.
The unchanged 100-row and five-function counts pass in all modes, with three
authenticated export-cache hits and fresh execution checks. Its minimum is
31.92 GB free, above the 24.36 GB reserve. The bounded repair and remaining
reference-analysis work are described below.

The earlier accepted [IR and headroom checkpoint](evidence/ir_headroom_acceptance_20261103.json)
at `abd0bae6` passes both full 17-stage fresh/cached runs. All 1,406 canonical
records match on an unchanged 2,681-file primary-checkout snapshot. The numeric
serialization, blockaddress, quoted-name and allocation-ownership repairs are
accepted with headroom policy schema 3. All candidate, execution and bypass
counts stay fixed; the detailed scope appears below.

The earlier accepted [module dependency checkpoint](evidence/module_selection_acceptance_20261103.json)
at `9c7985e2`, with shared analysis extracted at `68a56ca7`, passes all 17
integration stages on a frozen 2,642-file snapshot. Explicit
`--codegen-reachable` selection follows parsed function, global and alias references;
private helpers keep local ELF bindings and selected alias chains resolve in any
definition order. Opaque references conservatively retain all definitions.
Seven functions pass 330 local observations against 165 LLVM references across
direct/release routes in three modes. Thirty rejection controls and three
CLI/environment equivalence checks pass, along with all 1,689 unit tests, focused
checks and 60 ABI cases. Earlier populations and the bypass ratchet stay fixed.
Legacy selection remains the default. Unchanged Fibonacci now rejects during
code generation at `start.expandStackSize unsupported_type:alloca` in the explicit
mode; it still has zero local executions.

The earlier accepted [integer array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
at `4f69c581`, with correctness repairs `d1fe039a` and `e2fb5841`, passes
all 17 integration stages on a frozen 2,635-file snapshot. Named i64 indexes now
form runtime addresses for bounded literal integer arrays using allocation
strides, including padding and nesting. Live values receive preservation space;
in-place address operands survive scratch writes, and stores consume their value
before staging a spilled destination pointer. Four functions pass 1,536 local
observations against 768 LLVM references across direct/release routes in three
modes. Six negative controls are rejected. All 1,685 units, focused checks and
60 ABI cases pass; prior populations and the bypass ratchet remain fixed.

The earlier accepted [boolean call-return checkpoint](evidence/boolean_call_acceptance_20261103.json)
at `43fa83d2` passes all 17 integration stages on a frozen 2,630-file snapshot.
Exact i1 direct-call returns now use the typed call action and normalize the low
bit before publication. Four native functions pass 1,536 local observations
against 768 LLVM references through direct/release routes in three modes; three
controls reject missing normalization. All 1,679 unit tests, focused checks and
60 ABI cases pass. The unchanged 100-row selection, five-function execution
cohort, earlier native populations and bypass ratchet remain fixed.

The earlier accepted [global-memory checkpoint](evidence/global_memory_acceptance_20261103.json)
at `db272521`, with disk policy commit `61dfbb3b`, passes both full 17-stage
fresh/cached runs. All 1,403 canonical records match on an unchanged 2,624-file
snapshot. Four global-address functions pass 192 local observations against 96
LLVM references; seven copy/store functions pass 240 against 120 through
direct/release routes in three modes. The 1,675 unit tests, focused checks and
60-case ABI gate pass. Candidate, execution and bypass counts stay fixed.

Symbolic byte addresses now reach bounded ordinary native integer/pointer global
objects, including named unpacked structs, arrays, explicit alignment, local
symbols and pointer fixups in `.rela.data`. Private legalization feeds the existing
transactional memcpy/store consumers. Constant copy lengths, dying ABI operands
and narrow RAX-address stores have permanent native and rollback coverage. TLS,
weak linkage, custom sections, nondefault address spaces, floating/vector
initializers and zero-sized global placement retain explicit boundaries.

The earlier accepted [allocation-padding repair](evidence/allocation_padding_acceptance_20261103.json)
at `d4403016` fixes a native mismatch with LLVM: `{ i24, i8 }` previously
placed the second field at byte 3 instead of 4. Nested structs/arrays and 80-bit
floating allocation padding are covered by a permanent all-mode canary. The
1,662 units, focused ABI/native checks and all 17 integration gates pass on a
verified 2,615-file source snapshot. Candidate, execution and bypass counts stay fixed.

The [scalar startup acceptance](evidence/scalar_startup_acceptance_20261103.json)
at `1f92385e` completes exact named i64-to-pointer conversion and signed i32/i64
nonnegative comparisons through the existing value-use authorities. The preceding
[frame-store checkpoint](evidence/scalar_frame_acceptance_20261103.json) remains
accepted. A serial distribution run passes all 17 subgates against a frozen
2,589-file source snapshot. Three authenticated AIR exports are reused; execution
checks run again. The source pin remains
`1c08b09d1c847f4f02c8216e3b62df323861a437`.

The compiler-core selection remains the same 100-row selector-v3 prefix. Every
row lowers, emits an object and links in each release mode; five source-bound
functions execute per mode. The four constant methods remain in the cohort.
`ascii.isAscii` adds all 256 byte inputs per mode, compared with an independent
high-bit oracle and exact ordered output: 768 paired observations. Six native
constant-result negative controls reject. These input observations do not turn
100 links into 100 executions.

Production AIR publication writes schema-4 metadata atomically and transfers
ownership of the verified payload. Same-filesystem publication renames the
original file; cross-filesystem publication removes raw only after commit.
Readers support schemas 3 and 4, including the parent's cache-pin verifier.
The earlier fresh/cache proof identifies the same inode as raw and cached in all
three modes, with one complete payload per mode and no manual cleanup wrapper.
Rollback, legacy migration, reuse and actual cross-filesystem tests pass.

The unchanged upstream `hello_libc.zig` still executes in all three release
modes. Zig's unchanged [C compiler fixture](evidence/upstream_c_program_20261102.json)
adds an input-dependent branch, heap stores/loads and stdio. Its two argument
paths pass against LLVM in each local release pipeline: six paired case
executions. A separate native canary adds 48 integer-varargs and 18 heap-call
observations, checking AL, pointer identities, argument permutations, live
values and integer boundaries. C assertions stay enabled and C sanitizers are
disabled; these mode labels do not establish Zig safety behavior. Pinned
Zig/Clang IR construction, libc, the system linker and CRT remain dependencies.

The ABI cohort retains ten functions and passes 60 cases plus its negative
controls. The frozen FMA canary still passes its 29 exact-result cases and
8,192 LLVM-paired observations with unchanged identities. The scalar checkpoint
checks passed 1,649 compiler unit tests, 11 structural tests and seven Python
policy tests. Standalone, compiler-core and compiler-rt populations remain
separate; the compiler-rt bypass ratchet remains 130.

The [current cleanup](evidence/scalar_startup_cleanup_20261103.json) retires idle
owned caches, superseded non-performance executables and resolved exploratory
hello captures. A redundant 2,465-file source copy exactly matches Git commit
`56e66794` and is removed with its reconstruction proof retained. The preceding
[frame-store cleanup](evidence/scalar_frame_cleanup_20261103.json) preserves all
228 paths and hashes of deduplicated immutable evidence. Current exports, frozen
inputs, performance baselines and 13 original source probes remain. The subsequent
[audit input migration](evidence/candidate_facts_retention_20261103.json) retains
74 MB of verified semantic facts and retires the old raw descriptors, reducing
input allocation by 3.85 GB. All 21,117 rows, selected mode facts and rejection
identities replay unchanged; 15 offline policy tests pass. That migration left
the production AIR and compiler checkpoint unchanged. No archives are created.
Follow the [current keep-list](evidence/tmp_retention_pins.tsv).

The earlier [disk calibration](evidence/headroom_calibration_20261102.json) is accepted:
an 8 GiB forecast covers the sampled 6.10 GB fresh and 1.60 GB cached decreases.
The original serial admission is inherited by nested row workers, whose reserve
stays enforced and whose transient minimum enters the serial report. Allocated
disk telemetry covers all seven owned roots, including retained exports. The
earlier 49 runner/policy and 39 comparison tests passed. Filesystem noise and sampled,
non-atomic observations remain measurement limits.
The allocation-padding cached run reported a 3.37 GB decrease under the previous
reserve. The accepted headroom policy schema 2 used a fixed
32 GiB reserve plus the unchanged 8 GiB working budget: 40 GiB (about 42.95 GB)
free at admission. Runtime reserve checks and stronger caller floors remain.
That pair reports 5.86 GB fresh and 2.16 GB cached decreases; reported minima
are 44.09 GB and 43.31 GB, above the 34.36 GB reserve. The 51 runner/policy and
41 comparison tests pass. These filesystem observations do not establish a speedup.
The user subsequently lowered both admission and reserve by 10 decimal GB.
At that checkpoint, policy schema 3 required 32.95 GB at admission and a 24.36 GB
runtime reserve, with the same 8 GiB working budget. Its accepted fresh/cached
pair reports 7.09 GB and 1.97 GB decreases. Independent sampled minima are
30.71 GB and 33.65 GB, above the reduced reserve; all 1,406 canonical records match.
The [generation cleanup](evidence/global_memory_cleanup_20261103.json) retires
3.92 GB of superseded AIR after both full runs and replacement hash verification.
That checkpoint used `global-memory-headroom-20261103`. The later
[IR generation cleanup](evidence/ir_headroom_cleanup_20261103.json) retires those
payloads after the complete fresh replacement proof and before cached validation
to meet its admission threshold. Both replacement runs pass. That checkpoint's
exports and paired work selection used `ir-headroom-20261103`; the later
execution-breadth checkpoint supersedes them. The [project cleanup](evidence/project_space_cleanup_20261106.json)
retires the old payloads while retaining their metadata, hashes, proofs and
source probes, with no archives.

The [bounded memory slice](evidence/startup_word_pair_memory_20261102.json)
reuses existing 128-bit frame storage for an exact 16-byte pointer/length object
and transparent wrappers. Constructor stores, field extraction and bounded memcpy
pass 384 local observations through direct/release routes in three modes, against
192 LLVM-reference observations reused across routes. This does not establish
general aggregate memory or ABI support.

Runtime pointer values from registers, spills and returned RAX now store through
the existing authority into typed 64-bit frame slots, with 768 local observations
against 384 references. Scalar frame stores, eight full-width constants through
frame and ordinary-pointer destinations, and literal null add 486 local
observations against 243 references. References are reused across direct/release
routes in all three modes. The C fixture's six paired cases/66 call observations,
the existing word-pair canary and accepted compiler counters stay separate.

The new cast and comparison canaries each contribute 1,536 local observations
against 768 LLVM references across direct/release routes in three modes, with
references reused across routes. They check full-width bit preservation, signed
extrema, live values, spills, returned values and output guards. Other cast widths,
immediate sources, cast flags, pointer targets and unproved compare forms retain
explicit boundaries; frozen residual fingerprints and the bypass ratchet stay
unchanged.

The [numeric SSA serialization repair](evidence/numeric_ssa_focused_20261103.json)
now has a [focused integration follow-up](evidence/ir_blockaddress_focused_20261103.json).
The first full run failed after six stages on a retained jump-table initializer;
its sampled minimum stayed above the reduced reserve. Printing now binds each
`blockaddress` to its function before renumbering. CFG passes preserve functions
whose block addresses escape, while opaque reference coverage stays conservative.
SimplifyCFG generates valid names without collisions, and the parser preserves
quoted parameter names with spaces. The earlier allocation-ownership fixes remain.
All 1,718 units, readiness and 13 structural checks pass, including the previously
failing mixed C/Zig native case. Ten regression functions supply 480 observations
of locally optimized IR executed by Clang-22 against 160 reused LLVM references.
Complete optimized panic-module IR and the unchanged repaired Fibonacci IR verify.
These IR checks add no local whole-program execution. The accepted fresh/cached
pair passes all 17 stages with matching canonical records and an unchanged source
snapshot. The isolated retry had passed nine stages before exposing the export
worker's fixed checkout path; the accepted pair ran from the primary checkout
after merging the focused commits. Failed logs and frozen snapshots remain.
The follow-up fixes have separate printing, parser and optimizer source commits;
the fixed candidate and execution cohorts remain unchanged.

The accepted [symbol identity prerequisite](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes 1,727 units, 13 structural tests, readiness and full
integration. It fixes GlobalOpt ignoring escaped stores and GlobalDCE deleting
differently spelled live globals; constant merging uses the same identity. Five entries pass
240 observations of locally optimized IR via Clang against 80 reused references.
The local verifier still rejects differently spelled direct callees, alias
targets and global-initializer targets; graph-only tests do not establish their
CLI admission. Unsupported symbol spellings and opaque regions stay conservative.
The frozen cached run passes all 17 stages; its exact command and reuse rationale
are recorded in the evidence. Only the idle project build cache was retired for
admission, preserving sources, current exports and all 13 original probes.
No shared caches were deleted, and no archives were created.

The earlier [attribute-group slice](evidence/reference_attributes_focused_20261103.json)
at `fa85a805` recognizes bounded enum, alignment, memory-effect and string
attributes through one module context. Missing/duplicate groups and unfamiliar
strings such as `probe-stack` remain conservative. It passes 1,739 units,
13 structural tests, 19 focused tests in each of ReleaseFast and ReleaseSafe,
readiness and 400 observations of optimized IR executed by Clang against
80 reused LLVM references. The subsequent checkpoint accepts the family.

The [dependency-coverage checkpoint](evidence/dependency_coverage_acceptance_20261104.json)
accepts `dad027d9`, the attribute-ordering repair `85e892f3` and the corrected
negative fixture `811aa4ba`. The first full attempt was stopped after a narrow
check confirmed that its opaque-coverage control used now-supported metadata.
The control now uses unknown named metadata. All 330 local module observations,
30 rejection controls and three environment checks pass, and the frozen retry
passes all 17 stages. The original and retry logs remain retained.

The dependency checkpoint established complete coverage for the unchanged
Fibonacci input: 34 functions and 15 globals plus one alias. Its selected names
match LLVM GlobalDCE after serialization-only numeric SSA normalization. At that
checkpoint, nine functions emitted and 25 rejected, first at aggregate allocation.

The [bounded frame checkpoint](evidence/bounded_frame_acceptance_20261104.json)
accepted exact 16-byte integer pairs and the capture's padded 16-byte and
24-byte wrappers. The existing allocator and typed address authority own storage
and access; private views preserve source records and borrowed call arguments.
Mixed pair/wrapper copies retain their proven literal length through both views.
All-mode native proof and all 17 integration stages passed. At that checkpoint,
Fibonacci emitted ten functions and rejected 24, first at the 56-byte array stride
in `start.expandStackSize`; local whole-program execution remained zero.

The [general array stride checkpoint](evidence/general_stride_acceptance_20261104.json)
accepted bounded allocation strides from 1 to 255 bytes, including `[56 x i8]`,
with all-mode native proof and all 17 integration stages. At that checkpoint, the
unchanged capture emitted ten functions and rejected 24; its first boundary moved to
`start.expandStackSize composed-block-load-ptr`. Read-only debugger inspection
identifies a 64-bit pointer in RAX rejected during transaction seal for an i32
load. The [focused evidence](evidence/general_stride_focused_20261104.json) retains
a small loop reproducer and its successful Clang compile. This is a codegen
boundary, with zero local whole-program executions.

The [RAX pointer-load checkpoint](evidence/rax_load_acceptance_20261104.json)
accepts that ordinary-load address through shared RAX-to-RCX staging and
accumulator ownership. Both retained load reproducers now emit objects, and
all-mode native checks and all 17 integration stages pass. The unchanged capture
still emits ten functions and rejects 24; it now reaches `urem i64` by 4096,
reported as `start.expandStackSize composed-block-binary-imm-rhs`.
The [focused evidence](evidence/rax_load_focused_20261104.json) retains a small
control-flow reproducer with that exact rejection and a successful Clang compile.

The [constant remainder checkpoint](evidence/constant_remainder_acceptance_20261104.json)
accepts that bounded unsigned operation. The unchanged capture now reaches
`composed-block-call-arg-width`; all 24 function failures remain tracked.

The user's latest instruction is to finish the current slice and stop. The
arithmetic/hash slice is finished and recorded above; no further slice is active.
The earlier authorization to continue automatically is superseded. The remaining
plan below is retained for a future user request:

1. Narrow call arguments/returns, boolean parameter handling and the main
   function's call-preservation frame are accepted at the checkpoint above.
2. Bounded stack structures and flat two-word aggregate loads,
   insertion/extraction and call/return values are accepted above. Larger or
   unsupported layouts remain explicit boundaries.
3. Unsigned minimum, signed less-equal, switch PHI edges and bounded stack
   memset are accepted above. Resolve any remaining scalar forms as they emerge
   in the call and Safe paths.
4. Named indirect calls, bounded stack arguments and their result handling are
   accepted above. Fast and Small execute the complete unchanged program.
5. Resolve the remaining Safe scalar, memory, atomic and control-flow forms,
   link the real pinned compiler runtime and execute the unchanged Safe program.
6. Retain matching LLVM exit status/stdout/stderr in all three release modes and
   add a permanent mandatory regression before full integration acceptance.

Rerun the whole captured failure report after each implementation change;
newly exposed failures update the work order. Completion requires all six original
assertions to pass with matching exit status/stdout/stderr through the local
backend. Use the validation tiers for provisional commits and family acceptance.
Keep fixed populations, default legacy selection, the bypass ratchet and agreed
disk limits unchanged. Preserve the original scratch probes and create no archives.

Keep broader optional ABIs and
floating/indirect/aggregate/stack varargs as explicit boundaries. Use the frozen
performance baseline for measured comparisons and the
[validation policy](validation_tiers.md) for matching evidence reuse.

## Completed prerequisites and operating rules

The [project improvement plan](roadmap/project_improvement_plan.md) completed its
six phases, including storage replacement/cleanup, exact summary validation,
compiler selection, behavioral coverage and current documentation. Its
[implementation evidence](evidence/project_improvement/implementation.md) includes
the passing fresh/cached 17-subgate pair and matching canonical records.
Those phases are not reopened by the completed architecture baseline.

The [memset family](evidence/composed_memset_family.md),
[integer/allocation repairs](roadmap/optimizer_boundary_repairs.md), and
[correctness checkpoint](roadmap/correctness_checkpoint.md) are complete.
The checkpoint was committed as `eab54c12`: 1,503 unit/structural/storage tests,
focused ReleaseFast tests, native LLVM comparisons, readiness and all 17
integration subgates passed against an unchanged source snapshot. It does not
establish program performance or claim a full ReleaseFast unit-suite pass.

Use Zig 0.17.0, retain the patched emitter and unique source work, and follow the
[current keep-list](evidence/tmp_retention_pins.tsv). Historical worktree and
artifact-authority requirements retired by the improvement plan remain retired.
Every new cache or failure capture needs a current consumer or bounded diagnostic
reason. The [architecture map](architecture.md) describes implemented routes.
Keep [accepted counters](accepted_status.json) unchanged until an explicit,
evidence-backed migration; passing tests or collecting timings never advances
them automatically.
