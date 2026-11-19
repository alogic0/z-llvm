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
