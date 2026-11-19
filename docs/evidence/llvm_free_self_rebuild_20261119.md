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

## Object emission

The repaired parser's trial behavior build emitted 7,458 of 7,459
functions. The remaining function calls a sibling through a zero-offset
pointer expression with `musttail`. The original source requires the
transfer to reuse the caller's stack. The sibling's separate call through
a loaded function pointer already emitted. [Per-function behavior diagnostics](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-behavior/object.stderr)

The ordinary helper self-build emitted 14,816 of 14,820 functions.
The four remaining functions compute ELF alignment, convert a signed
timestamp difference to nanoseconds, or perform checked addition and
multiplication on unsigned 80-bit integers. The unchanged helper module
gave the same four failures when replayed with the parser correction.
[Ordinary helper build output](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-helper/build.stderr)
· [Complete helper replay](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/attribute-replay-01-helper/result.json)
