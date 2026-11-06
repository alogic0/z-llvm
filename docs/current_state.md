# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `f68ab145d3f5efc4f4a4f01d30012dc3e4db0eac`; tree: `06d222b29524f157950e80b6e4dd0c1dafdc0462`.

Population: compiler-core candidate prefix (100 rows), selector `real-candidate-selector-v3`.
Modes: ReleaseFast, ReleaseSafe, ReleaseSmall. Source pin: `1c08b09d1c847f4f02c8216e3b62df323861a437`.
Candidate SHA-256: `847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31`.

| Metric | Accepted value per mode | Scope |
| --- | ---: | --- |
| Functions lowered | 100 | Compiler-core prefix |
| Objects emitted | 100 | Compiler-core prefix |
| Native links | 100 | Compiler-core prefix |
| Functions executed | 9 | Fixed execution cohort |
| Paired harnesses accepted | 9 | Legacy real_programs_ok cohort metric |
| Local failures | 0 | Compiler-core gate |

Compiler-rt bypass ratchet: 130 (separate 285-function population).

<!-- accepted-status:end -->

The accepted [execution-breadth checkpoint](evidence/execution_breadth_acceptance_20261106.json)
at `f68ab145` passes all 17 integration gates. The fixed compiler-core prefix
remains 100 lowered/emitted/linked functions, with nine functions executed per
mode. Fresh and cached execution match all 36 canonical records. Fibonacci,
optionals, global tagged storage, anonymous aggregate arrays and runtime loops
execute unchanged in Fast, Safe and Small with LLVM-equivalent status and output.
Fibonacci retains all six assertions and 1,568 emitted Safe definitions.

All 45 native populations pass 1,767,660 local observations against 883,830 LLVM
observations. Shared parallel transfers preserve call arguments, scalar register
PHIs, aliases and widths under pressure. The added compiler-core tests exposed
and fixed 32-bit atomic exchange lowering for an 8-bit mutex. Twelve added
function/mode checks and 27 negative controls verify values, linkage and guarded
memory effects. Validation includes 1,901 unit tests in Debug and ReleaseSafe,
36 policy tests per mode, 19 structural checks, 60 ABI comparisons, compilation
route checks and readiness. Free space remains above the unchanged 24.36 GB reserve.

The [implementation and timing evidence](evidence/execution_breadth.md) separates
compiler throughput from generated-code quality. On the same Safe Fibonacci IR,
emission plus ownership replay took about 650 seconds with a Debug compiler and
65 seconds with ReleaseFast, with byte-identical outputs. These are single samples
concurrent with validation; host policy blocks sampling-based profiling.
The [completed plan](plans/2026-11-06-execution-breadth.md) records the order and
remaining work: optional legalization, explicit register effects and larger state
and memory programs. This checkpoint does not establish self-hosting or release
optimization quality. Original scratch probes, diagnostic worktrees and the old
authenticated AIR cache remain intact; no archives were created.

The entries below are historical. Their counts and remaining failures describe
those checkpoints, not the current frontier.

The earlier [Fibonacci completion checkpoint](evidence/fibonacci_completion_acceptance_20261106.json)
at `7e1c8bd7` passes all 17 integration gates. Unchanged pinned Fibonacci executes
all six assertions in Fast, Safe and Small with LLVM-equivalent status and output.
Safe emits all 1,568 selected definitions. The permanent three-mode regression
is part of full integration.

All 44 native populations pass 1,718,508 local observations against 859,254 LLVM
observations. The compiler-core cohort remains 100 lowered/emitted/linked and
five executed functions per mode; its 24 canonical records match the preceding
accepted checkpoint. Validation includes 1,897 unit tests in both Debug and
ReleaseSafe, 26 policy tests in each mode, 19 structural checks, 60 ABI
comparisons and readiness checks. Minimum free space is 47.94 GB, above the
unchanged 24.36 GB reserve.

The [implementation evidence](evidence/fibonacci_completion.md) records mandatory
normalization before generic selection, shared compilation preparation, register
repairs, bounded lowering and the corrected Debug compilation deadline. Optional
legalizers still use recursive selection. This checkpoint does not establish
self-hosting or release optimization quality. The next
[execution-breadth milestone](plans/2026-11-06-execution-breadth.md) adds diverse
unchanged programs and more callable compiler-core functions. Original scratch
files and the diagnostic worktree remain intact; no archives were created.

The [Python-to-Zig tooling migration](evidence/python_tools_migration_20261105.json)
is separately validated at `978ffaf9`. The maintained program, native, candidate,
fact and benchmark tools now use Zig with pinned process and test-support sources.
All 22 policy/provider tests pass in Debug and ReleaseSafe; all 17 integration
gates pass with Python blocked. The full log matches all 1,430 canonical records
from the preceding Python-backed run, and fresh/cache replay matches all 24
records across three modes. That tooling migration left compiler source and
the accepted population unchanged. [Tooling documentation](validation_tools.md) records the commands
and historical-evidence boundary. This tooling checkpoint preceded the compiler
work above.

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
The first is `debug.writeCurrentStackTrace` / `inline-asm-call`.
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

The earlier accepted [symbol identity repair](evidence/symbol_identity_acceptance_20261103.json)
at `b3be3512` passes all 17 integration stages on a frozen 2,691-file snapshot.
Shared reference analysis recognizes supported quoted and hexadecimal global
spellings, preserving stores and live definitions that GlobalOpt and GlobalDCE
previously missed. Constant merging uses the same identity; numeric slots remain
distinct from quoted numeric names. All 1,727 units, 13 structural tests and
readiness pass. Five entries pass 240 observations of locally optimized IR
executed by Clang against 80 reused LLVM references. This adds no local
machine-code or whole-program execution credit. The three current AIR exports
are authenticated and reused while execution checks run again. The recorded
minimum is 31.92 GB free, above the 24.36 GB runtime floor; the reported decrease
is 1.71 GB. Opaque coverage, the legacy selection default, all fixed populations
and the bypass ratchet remain unchanged.

The earlier accepted [IR and headroom checkpoint](evidence/ir_headroom_acceptance_20261103.json)
at `abd0bae6` passes both full 17-stage fresh/cached runs. All 1,406 canonical
records match on one unchanged 2,681-file snapshot in the primary checkout.
Numeric local names follow definition order, and printing binds each
`blockaddress` to its function before renumbering. CFG passes preserve functions
whose block addresses escape, while opaque reference coverage stays conservative.
SimplifyCFG generates valid names without collisions; the parser preserves
quoted parameter names with spaces and releases owned values on failed publication.
All 1,718 units, readiness and 13 structural checks pass, including the previously
failing mixed C/Zig native case. Ten regression functions supply 480 observations
of locally optimized IR executed by Clang-22 against 160 reused LLVM references.
Complete optimized panic-module IR and the unchanged repaired Fibonacci IR verify.
These IR checks add no local whole-program execution. Candidate counts, all eleven
native populations and the bypass ratchet remain unchanged. The two failed
attempts, their inputs and frozen snapshots remain retained; full validation uses
the canonical checkout required by the export/execution cohort.

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

The earlier [integer array-stride checkpoint](evidence/array_stride_acceptance_20261103.json)
at `4f69c581`, with correctness repairs `d1fe039a` and `e2fb5841`, passes
all 17 integration stages on a frozen 2,635-file snapshot. Named i64 indexes now
form runtime addresses for bounded literal integer arrays using allocation
strides, including padding and nesting. Live values receive preservation space;
in-place address operands survive scratch writes, and stores consume their value
before staging a spilled destination pointer. Four functions pass 1,536 local
observations against 768 LLVM references across direct/release routes in three
modes. Six negative controls are rejected. All 1,685 units, focused checks and
60 ABI cases pass; prior populations and the bypass ratchet remain fixed.

The earlier [boolean call-return checkpoint](evidence/boolean_call_acceptance_20261103.json)
passes all 17 integration stages on a frozen 2,630-file source snapshot. Exact
i1 direct calls use the existing typed call action, normalize the low bit before
publishing the result, and preserve live values and transaction rollback. Four
native functions pass 1,536 local observations against 768 LLVM references across
direct/release routes in three modes. Three controls reject missing normalization.
All 1,679 unit tests, focused checks and 60 ABI cases pass; compiler-core counts,
previous native populations and the bypass ratchet remain unchanged.

The earlier [global-memory checkpoint](evidence/global_memory_acceptance_20261103.json)
passes a fresh/cached pair of all 17 integration stages, with all 1,403 canonical
records matching on an unchanged 2,624-file snapshot. Symbolic byte addresses,
reachable integer/pointer global storage and ELF data relocations now share the
existing transactional memory consumers. Four address functions pass 192 local
observations against 96 LLVM references; seven copy/store functions pass 240
against 120, through direct/release routes in three modes. All 1,675 unit tests,
focused checks and the 60-case ABI gate pass. Compiler-core counts stay fixed.

The earlier [allocation-padding repair](evidence/allocation_padding_acceptance_20261103.json)
passes all 17 integration subgates. Struct fields now advance by allocation size: the
field after `i24` starts at byte 4 and the field after `x86_fp80` at byte 16. Four
permanent native regressions pass 768 local observations against 384 LLVM references
across direct/release routes in three modes. The 1,662 unit tests and focused
60-case ABI gate pass. Its layout correction remains part of the current compiler.

The [scalar startup checkpoint](evidence/scalar_startup_acceptance_20261103.json)
passes all 17 integration subgates on its frozen source snapshot. Exact named
i64-to-pointer casts preserve every bit and signed i32/i64 nonnegative comparisons
reuse the existing sign-bit authority. Earlier scalar frame stores and their
full-width immediate repair remain accepted. The new standalone native canaries
each pass 1,536 local observations against 768 LLVM references in three modes.

The [current-pin migration](evidence/real_candidates_release_v3_migration.json)
fixes the 100-row selector-v3 population. Its audit retains 30 previous prefix
entries and replaces 70; 63 former names have no runtime AIR at this pin.
Five source-bound functions execute per mode: four constant methods and
`ascii.isAscii`, which checks all 256 byte inputs. These observations do not
turn 100 native links into 100 executions.

AIR publication atomically writes schema-4 metadata and transfers the verified
payload into the cache. The IR/headroom pair authenticates three fresh exports,
then verifies three cache hits while rerunning execution checks. Current exports
use `local-state/caches/ir-headroom-20261103`. The user reduced serial admission
and its runtime reserve by 10 decimal GB: policy schema 3 requires
32,949,672,960 bytes (about 32.95 GB)
at the start and reserves 24,359,738,368 bytes (about 24.36 GB) during execution.
The working budget remains 8 GiB. Nested workers inherit that admission and
continue enforcing the reserve, including stronger caller floors. The accepted
pair reports 7.09 GB fresh and 1.97 GB cached decreases, within the 8 GiB forecast.
Reported minima are 30.85 GB and 33.65 GB; independent two-second samples reach
30.71 GB and 33.65 GB. Both stay above the 24.36 GB reserve. Filesystem activity
outside the runner and non-atomic samples limit these measurements. Raw AIR
needs no manual cleanup wrapper.

Unchanged upstream `hello_libc.zig` and the C fixture execute in all three modes;
the C fixture's six paired cases and 66 call/heap observations remain separate.
The ABI gate passes 60 cases. The frozen FMA canary retains 29 exact-result
checks and 8,192 LLVM-paired observations. In the accepted legacy route, Fibonacci emits `start.main`
through composed selection, then fails to link because 13 required private
symbols are omitted despite having definitions in the captured IR. The unchanged
program retains one LLVM reference execution and zero local executions. Its
isolated arithmetic body passes 31 local/LLVM observations, which does not prove
whole-program execution. LLVM IR construction, the system linker/CRT and libc
remain external dependencies of that route.

The [scalar cleanup](evidence/scalar_startup_cleanup_20261103.json) retains the
13 original source probes, performance baselines and required evidence. The
[audit input migration](evidence/candidate_facts_retention_20261103.json) replaces
historical raw descriptors with 74 MB of exact checked semantic facts, reducing
retained input allocation by 3.85 GB. Audit replay preserves the entire candidate
table and selected mode facts. Current authenticated production AIR remains
pinned. Obsolete generated copies and a source copy exactly present in Git
history are retired without archives. The latest
[generation cleanup](evidence/ir_headroom_cleanup_20261103.json) retires 3.92 GB
of superseded AIR after the complete fresh replacement proof, making room for
the cached run. Both runs now pass; old metadata and hashes remain. The retired
checkout's dependency links are removed while their target repositories remain.
The Fibonacci foundation, stack-address flow, checked integers, word arithmetic
and larger switches are accepted, including unchanged Fast/Small execution.
Continue the authorized plan through the remaining Safe code-generation forms,
the real compiler runtime link and unchanged Safe execution. Add a permanent
three-mode regression before final full integration acceptance. See
[next steps](next_steps.md) for the full acceptance condition.
