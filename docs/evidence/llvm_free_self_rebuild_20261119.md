# Rebuilding Zig and z_llvm with the installed provider

The first isolated builds used the installed G1 Zig and helper, empty
caches and each project's ordinary `zig build install`. The first
compiler build stopped before installing Zig. The helper build reached
object emission and stopped before installing `z_llvm`.
[Accepted starting package](llvm_free_zig_toolchain_20261119.md)
· [Normal Zig install](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-zig/build-result.json)
· [Normal helper install](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-helper/build-result.json)

## Nested pointer arguments

Two original optimizer inputs exposed the same parser error. Upstream's
empty-struct method test produced it at line 282,884 of the 46,421,094-byte
behavior module. `InternPool.Key.hash64` produced it at line 845,782 of
the 305,089,486-byte Zig compiler module. Both calls pass an attributed
pointer whose value is an outer `getelementptr` around an `inttoptr`.
The parser took the inner operator as the start of the operand.
[Behavior input and verifier](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-behavior-attribute/diagnosis.json)
· [Compiler input, exact instruction and process results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-zig-original-failure/failure.json)

The primary accepted parser patch `111b1aab` and verified its full diff
against local commit `6a374ec2`. It reads complete top-level tokens
and preserves the outer typed value. The revised
normal install kept Zig `06c09683` and supplied helper `b0ac4145`.
The ten lines of upstream Zig source passed with stock LLVM, native Zig
and the revised installed provider. The original installed provider
had rejected that same test. The package contains the same 19,501 SDK
files and two static executables. [Original source reproduction](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-empty-struct-source/result.json)
· [Three routes on the revised install](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-empty-struct-source-installed/result.json)
· [Revised package inventory](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-package-elf-02/package-inventory.json)

The frozen parser candidate optimized all three original inputs. It
produced 45,448,870 bytes for the behavior suite, 291,591,339 for Zig,
and 80,276,219 for the helper. The helper output exactly matched the
bytes read by the original object emitter. The generation checks use
the installed tools on fresh compilations. [Original behavior module](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-behavior/result.json)
· [Original compiler module](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-zig/result.json)
· [Original helper module](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-helper/result.json)

An additional numerical test found a separate object-emitter limit.
A pointer made by applying `ptrtoint` and `inttoptr` to an array symbol
and then adding a byte offset passed the revised optimizer. LLVM read
the expected value 66 from the array. The local object emitter rejected
that argument. The single-operation control returned 66 locally, the
quoted-symbol control returned 31 and invalid alignment was rejected.
[Native comparisons and exact source](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-behavior-attribute-candidate/cases.json)

A separately compiled observer also received pointer values 1 and 65
from the exact zero-offset expression on both LLVM and the revised
installed helper. With a byte offset of 3, the local optimizer preserved
the expression and the emitter rejected it. LLVM produced 68.
[Numeric pointer observations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-pointer-operand/result.json)

## Wide integer in the installed optimizer

The ordinary G1 behavior compilation used the same 46,421,094-byte
builder module as the trial. Its optimized file had a single differing
line. In a call to `behavior.math.testShl__func_2055` the installed
helper printed `5` for the i256 input `2^128 + 5`. This changed the
value supplied to the shift test. The independent trial preserved the
original integer. Both emitters subsequently reported the same tail
call. The two distinct optimizer outputs remain available for the
correction review. [Ordinary result and both IR identities](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior-02/result.json)

A separate C caller read all 32 bytes for 21 positive and negative i256
constants. Clang compiled each optimizer's output with the same options.
The installed helper lost bit 128 in that same input. The other 20
values matched. The trial and unmodified LLVM input matched all 21.
Both helpers rejected the malformed decimal. Their local object emitters
also rejected the supplemental caller's generic i256 parameter.
[Complete module difference](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-wide-literals/whole-module.json)
· [Native observations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-wide-literals/results.json)

The same error occurred in standalone Zig code using
`std.fmt.parseInt(i128, text, 10)`. Both the installed compiler's
native backend and the pinned stock compiler's native backend
returned 5. The stock LLVM backend reported overflow. In the
implementer's 2,006 observations per route, this was the only mismatch.
[Standalone Zig source and backend observations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/wide-native-origin-01/diagnosis.json)

The failing decimal step multiplies `0x1999999999999999999999999999999a`
by ten. The low 128 bits are 4 and the multiplication overflows. The
pinned stock and installed Zig native backends returned the right low
bits and a clear overflow flag. On 91 focused checks, the shipped Zig
compiler with the explicit local provider and the stock LLVM route
both matched the reference. The shipped native route missed eight.
[Overflow threshold observations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/wide-native-thresholds/diagnosis.json)
· [Ordinary Zig provider and native executions](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/wide-user-selected/results.json)

The decimal correction landed at `e524d2e3`. It checks the magnitude
against the signed i128 limit before multiplying by ten. The reviewer
compared the full 45,448,870-byte output from the G1-native-built
trial to the reference and compared all 32 bytes of each of the 21
values. Both comparisons were exact. The published three-file diff
matches the tested patch.
[Full-module replay and native numerical output](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/wide-source-native-02/observed.json)
· [Published source comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/wide-publication/report.json)

## Object emission

The frozen parser trial emitted all 65,078 selected functions from the
original Zig compiler module. Its x86_64 relocatable object contains
102,792,984 bytes, SHA-256 `b4ce4d6b…a8566c33`. The ordinary install
will establish which object Zig actually links into the second generation.
[Full compiler replay](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-zig/result.json)

The repaired parser's trial behavior build emitted 7,458 of 7,459
functions. The remaining function calls a sibling through a zero-offset
pointer expression with `musttail`. The original source requires the
transfer to reuse the caller's stack. The sibling's separate call through
a loaded function pointer already emitted. [Per-function behavior diagnostics](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-behavior/object.stderr)

On the tail-call correction, both LLVM and the local emitter ran the
original two-function example and a one-million-transfer variant with a
128 KiB stack. Both produced 1,000,001 visits and the expected final
byte, 36. The local object restored each original 280-byte stack frame
before the direct jump to the sibling and its indirect jump back.
The local emitter rejected the nonzero function offset and the
nonterminal instruction. The reviewer verified identical production
sources across both trial snapshots. The second snapshot corrected and
extended the unit tests.
[Bounded stack and negative cases](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-tail-candidate/result.json)
· [Machine instructions and relocations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-tail-candidate/original-local-disasm.stdout)

The reviewed tail change landed at `864af769`. Its committed diff
matches the tested patch `2e3a6230`. The original optimized behavior
module then produced a 20,748,816-byte object containing all 7,459
selected functions. [Complete behavior object](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/tail-behavior-replay-01/result.json)

The reviewer linked that trial object with the compiler-runtime archive
from the original G1 behavior build and the system C runtime. All
2,097 test names ran in the empty root. One differed from the ordered
reference. Row 866, `optimized float mode`, failed, 2,062 passed and
34 skipped. The input includes both fast and strict versions of
`(x + 2^40) - 2^40`. Its legacy debug-variable calls caused the
optimizer to skip five passes, including the existing cancellation
rule. On input 0.001, upstream expects 0.001 for the optimized form
and exactly `2^-10` for the strict form.
[Runtime results and input hashes](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-tail-linked-behavior/result.json)
· [All numbered outcomes](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-tail-linked-behavior/execute.stderr)

The same 21 upstream source lines passed on stock LLVM and failed at
runtime with the installed G1-03 provider. Upstream explicitly skips
the native Zig backend. In the original full module the revised
floating trial changes exactly two lines. One reports four skipped
passes. The other retains the fast result's SSA name and debug
location and selects the original argument. The strict function's
instructions are identical.
[Ordinary source executions](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-source/result.json)
· [Revised full optimizer output identity](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/float-behavior-01/result.json)

The ordinary helper self-build emitted 14,816 of 14,820 functions.
The four remaining functions compute ELF alignment, convert a signed
timestamp difference to nanoseconds, or perform checked addition and
multiplication on unsigned 80-bit integers. The unchanged helper module
gave the same four failures when replayed with the parser correction.
[Ordinary helper build output](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-helper/build.stderr)
· [Complete helper replay](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-helper/result.json)

The reviewer extracted all four original functions. LLVM and independent
integer expectations agreed on 1,196 native results, including 34
addition overflows and 76 multiplication overflows. The tests check the
error tag and read the payload only on successful operations. Each
original helper function independently reproduced its whole-module
emission diagnostic. [Inputs, object results and arithmetic comparisons](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-functions/results.json)

The second arithmetic trial ran the original elapsed-time, addition
and multiplication functions correctly on all 933 inputs. The
alignment function still tried to spill a live register without a
stack frame. Additional native comparisons independently checked 512
unsigned additions, 512 unsigned multiplications and 512 signed 96-bit
maxima with two variable inputs. For every overflow, the local and
LLVM results matched on both the wrapped 80-bit value and the flag.
[Original function comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-functions-candidate/summary.json)
· [Complete intrinsic results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-arithmetic-boundaries/results.json)

The third arithmetic trial also preserves the live register during
the subsequent frameless XOR. The reviewer reran all four unmodified
functions with that helper, `7c387128`. Its 1,196 results matched
both LLVM and the independent expectations.
[Four-function correction review](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-functions-03/summary.json)

The complete original helper subsequently emitted all 14,820
functions with that trial. The reviewer verified the 41,481,208-byte
x86-64 relocatable object, SHA-256 `64e5dcaa4e57525e0c77b4efb864da17940b808bbafd6ccd25db48e9b7c5c913`.
The reviewed eight-file change landed at `bb4f4c22`.
[Full helper rebuild input and emission](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/arithmetic-helper-replay-03/result.json)

An ordinary suite run from the tail-only G1 installation compiled
and executed all 2,097 cases. It passed 2,061, skipped the expected
34 and failed the two previously isolated cases, optimized floating
point at row 866 and the i256 shift at row 1098. The first floating
trial changed the intended instruction but its new constant select
stopped native object emission at 7,458 of 7,459 functions.
[Ordinary G1 test output](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior-03/execute.stderr)
· [First floating trial emitter](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/float-behavior-01/object.stderr)

The next floating trial, `3c3de95d`, emitted all 7,459 original
functions. Its 20,748,816-byte object has SHA-256
`92b7946161f9528cd937e5b1ebc8be09975407a17c6983d8df1d7e066c6d3c68`.
The reviewer checked 11 inputs for each of eight variants, including
strict rounding and live debug references to both intermediate values.
All variants produced the expected bits through LLVM, through the
local optimizer followed by LLVM object emission, and through the
local native emitter. In the mixed case with a strict producer and
a fast consumer, LLVM cancels the two operations. The local rule
requires both operations to allow reassociation and preserves the
rounded result. The installed G1-04 optimizer also matched an
LLVM-built helper from its own frozen source on the complete upstream
module and preserved the full i256 shift argument.
[Full floating trial](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/float-behavior-03/result.json)
· [Independent numerical results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-debug-03/results.json)
· [Installed optimizer comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-wide-literals-fixed/installed-full-comparison.json)

The reviewer linked that full object with the actual runtime member
from the original G1 behavior build. All 2,097 names and outcomes
matched the authenticated reference in order. There were 2,063 passes,
34 skips and zero failures. Both the optimized floating test and the
wide shift passed. The ordered digest was
`d2f366d355bce75fc6b8beccb234f92f48cc07b82f4acdd7607940c1103474ba`.
The link used the host C driver. Each installed generation must also
build and run the suite through its own Zig driver and native linker.
[All numbered outcomes](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-linked-behavior-03/execute.stderr)
· [Object, runtime member and exact ordered comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-linked-behavior-03/result.json)

The reviewed floating change landed at `a55b1313`. The reviewer
compared its complete five-file patch and the combined sixteen-file
source change against the frozen inputs. Six operand arrangements
with a live floating argument gave 96 exact native results on the
guarded optimizer expression. Three had failed to emit on the old
helper. A separate, frameless raw select with an unrelated live XMM0
still fails to emit under both helpers. The complete source tree
used for G1-06 is `9c1e8029c37872f50461ca1d9561d47d54bf3fba`.
[Live-argument source comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-live-03/results.json)
· [Six operand arrangements and raw selects](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/live-fp-classification/report.json)

The two earlier diagnostic G1 builds differed in one test expression.
An independent comparison found one changed installed file,
`bin/z_llvm`, across 19,503 files. Its first difference was at byte
6,332,229 in the ELF symbol-name string table. The code section was
identical. G1-06 received its own package and numerical tests.
[Complete installation comparison](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-package-rebind-05/comparison.json)
· [ELF section comparison](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-diagnostic-section-rebind/report.json)

G1-06 installed helper `600cb8c4` and Zig `06c09683`. The installed
helper passed the 1,536 arithmetic and 88 floating-point controls.
The normal repository suite on its source passed 2,470 of 2,472
tests. A selector used a general IR operand routine to load a known
immediate, violating the frozen list of permitted callers. A unit
test dating from June also expected rejection of the legacy
`ptr nocapture` spelling, which the verifier now accepts as
`captures(none)`. The G1-06 installation also compiled and ran
all 2,097 upstream cases through its own native link and matched
every reference outcome.
[Ordinary install](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-helper-06/build-result.json)
· [Full repository test results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/combined-normal-tests-04/output.log)
· [Ordinary G1-06 upstream suite](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior-06/ordered-comparison.json)

The implementer restored the typed immediate move and corrected
the test for pointer capture attributes at `8c91f09e`. All 35
focused checks and all 2,472 normal repository tests passed. The
separate ABI comparison matched 60 cases across three optimization
modes. The reviewer compared the entire commit with its three-file
patch and all 17 changed source files with the actual build tree.
The next ordinary installation produced the 110,539,868-byte helper
`f041c1d52ee2597532c0740f4b6edb45d9fc25f242141d98e4df060161e7bf1d`.
[Focused source and emitter tests](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/gateway-focused/test.stderr)
· [Full repository command and results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/combined-normal-tests-05/output.log)
· [Installed G1-07 helper](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-helper-07/build-result.json)

The actual G1-07 helper matched all 1,196 numerical checks on the
four original functions and emitted byte-identical objects to G1-06
for all four. It also passed the 1,536 intrinsic boundary cases.
Its complete optimized upstream module matched the LLVM-built
helper from the same source on all 45,448,864 bytes.
[Original functions and object comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-functions-installed-07/preceding-emitter-comparison.json)
· [Intrinsic boundary results](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-helper-arithmetic-installed-07/results.json)
· [Whole-module comparison](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-wide-literals-fixed-07/installed-full-comparison.json)

The G1-07 package compiled the pinned upstream suite from an empty
cache. Its executable (`eac0d1e3`) matched all 2,097 ordered
outcomes, with 2,063 passes and 34 skips, and exited successfully
again under tracing. The reviewer matched eight function bodies
between the emitted object and the linked executable. Both the
external-provider and native `cat` passed all six I/O cases. Two
deliberate emitter failures left a missing destination absent and
preserved an existing executable byte for byte. The actual linked
runtime archive passed all 17 numerical cases.
[Upstream compile, link and executions](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior-07/result.json)
· [External-provider cat](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-positive-07/result.json)
· [Native cat](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-native-07/result.json)
· [Missing destination](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-fault-07/result.json)
· [Existing destination](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-fault-existing-07/result.json)
· [Runtime archive](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-runtime-07/result.json)

## Ordinary G2 helper build

G1-07 built and installed `z_llvm` from the frozen source and empty
caches. The ordinary build took 31 minutes. Its 100,034,473-byte static
executable has SHA-256
`771baaa8526d927d5f4b2389ec7086f18f1b017110e72865c1012dec02a670a4`.
It reproduced all 45,448,864 optimized bytes from the upstream suite,
matching G1-07 and the LLVM-built helper from the same source. On
the four original helper functions, it emitted the same four objects
as G1-07 and matched all 1,196 native numerical results.
[Ordinary install](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-helper-04/build-result.json)
· [Independent whole-module and numerical comparisons](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g2-helper-first-use/result.json)

## Native startup of the original compiler and helper objects

The reviewer passed both original trial objects to the installed G1
native ELF linker in an isolated root. The respective failed ordinary
builds supplied their own compiler-runtime archives. For each archive
the reviewer matched the extracted member to the actual logged input
object. The resulting static Zig was 224,077,064 bytes and printed
`0.17.0`. The 99,924,125-byte helper optimized a small module to
`ret i32 %x` and produced the same bytes as the installed helper.
The ordinary G2 builds will establish the origin of the packaged
executables and SDK.
[Link commands, archived members and execution](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-trial-startup/result.json)
· [Actual helper output](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-trial-startup/helper-trial.stdout)
