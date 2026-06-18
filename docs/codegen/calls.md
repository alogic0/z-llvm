# Direct Calls and Stack-Frame Codegen

This document tracks the call-codegen epic from the IR surface upward. The first
implemented slice began as an LLVM-compatible IR contract. Declarations and
direct calls can be parsed, printed, verified, and carried conservatively
through existing analysis and optimizer passes. Machine call lowering is now
implemented for the selected x86_64 SysV release subset and remains fail-closed
outside that subset.

## Upstream Mapping

Primary LLVM source references:

```text
llvm-project-22/llvm/include/llvm/IR/Function.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86FrameLowering.cpp
```

Implemented classification:

```text
LLVM-aligned subset:
  direct function declarations
  direct call instruction spelling
  scalar integer/pointer call argument and return type verification
  void-call no-result rule

local-only conservative:
  calls are memory-effect unknown barriers for optimization legality
  only direct named callees are accepted
  call attributes beyond the tiny preserved calling-convention subset are rejected

selected backend subset:
  Machine IR direct-call representation supports assembly and ELF call relocations only
  x86_64 argument lowering supports selected i32/i64/pointer GPR args and f32/f64 SSE args
  up to three constant i32 stack call arguments are accepted
  one to three live i32 caller arguments can be spilled across one direct call
  selected small INTEGER/INTEGER aggregate return and argument-field reads are accepted
  selected nested INTEGER aggregate field add-chain reads are accepted
  selected array-in-struct INTEGER aggregate sums are accepted
  selected mixed INTEGER/SSE aggregate argument-field reads are accepted through the reusable aggregate classifier
  selected reversed mixed SSE/INTEGER aggregate argument-field reads are accepted through the reusable aggregate classifier
  selected SSE/SSE aggregate argument-field reads and register returns are accepted through the reusable aggregate classifier
```

## Accepted IR Contract

Accepted declarations:

```llvm
declare i32 @callee(i32)
declare void @sink(i32)
```

Accepted calls:

```llvm
%r = call i32 @callee(i32 %a)
call void @sink(i32 %r)
```

The verifier requires the callee to be either a direct declaration or a direct
definition in the same module. Argument count and argument types must match the
callee signature. Non-void calls require a result name; void calls must not have
one.

## Current Codegen Slice

The x86_64 backend now lowers tiny direct-call assembly fixtures:

```llvm
%r = call i32 @callee(i32 %a)
ret i32 %r
```

Accepted call-codegen shape:

```text
x86_64-linux SysV only
i32/i64/pointer direct call arguments in the SysV integer stream
f32/f64 direct call arguments in the independent SysV SSE stream
i32 return in %eax, i64/pointer return in %rax, f32/f64 return in %xmm0
selected small INTEGER/INTEGER aggregate return in %rax/%rdx
selected SSE/SSE aggregate return in %xmm0/%xmm1
void calls with no result
one straight-line basic block or accepted generic CFG wrapper shape
up to three live i32 caller arguments across one direct call
one fixed i32 stack slot can feed the first direct-call argument
```

The local stack-alignment sequence is:

```asm
subq $8, %rsp
callq callee
addq $8, %rsp
```

For the first broader SysV closure wave, the selected live-i32 frame uses a
24-byte aligned frame and spills up to three live integer parameters before
argument setup:

```asm
subq $24, %rsp
movl %edi, (%rsp)
movl %esi, 4(%rsp)
movl %edx, 8(%rsp)
callq callee
movl (%rsp), %edi
movl 4(%rsp), %esi
movl 8(%rsp), %edx
addq $24, %rsp
```

For one live caller argument, the same 8-byte alignment slot is used as a
deterministic spill slot:

```asm
subq $8, %rsp
movl %edi, (%rsp)
callq callee
movl (%rsp), %edi
addq $8, %rsp
```

For the bounded stack-memory-to-call handoff proof, the same slot can hold a
single i32 alloca value that is loaded into `%edi` before the call:

```asm
subq $8, %rsp
movl %edi, (%rsp)
movl (%rsp), %edi
callq callee
addq $8, %rsp
```

LLVM `llc-22 -O0` commonly emits `pushq %rax` / `popq` for the same tiny
alignment need. This project uses `subq` / `addq` so the spill slot is explicit
and easy to inspect.

Native backend handoff classification:

```text
validation-only: call assembly/object fixtures validate ABI and relocation assumptions for tiny direct-call cases
handoff study: the accepted call shape can be compared against Zig native AIR/MIR call lowering
accepted frontier: selected stack-passed i32 arguments, mixed integer/SSE scalar arguments, selected small INTEGER/INTEGER aggregate return/argument reads, selected mixed INTEGER/SSE aggregate argument field reads and register return, selected reversed mixed SSE/INTEGER aggregate argument field reads and register return, selected SSE/SSE aggregate argument field reads and register return, selected `{ i64, i64, i64 }`/`{ i64, i64, i64, i64 }`/`{ i64, i64, i64, i64, i64 }` hidden-sret return storage, and selected first stack MEMORY aggregate by-value field reads
out of scope: varargs, vectors, arbitrary aggregate ABI classes, arbitrary sret/byval copies, tail calls, unwind, and debug-info call-site handling
handoff doc: docs/codegen/zig_native_backend_handoff.md
```

ABI-shaped attributes:

```text
byval(...) and sret(...) are preserved on pointer parameters and verified
as pointer-only annotations; the frontier additionally lowers the selected
source-backed `{ i64, i64, i64 }`, `{ i64, i64, i64, i64 }`, and
`{ i64, i64, i64, i64, i64 }` hidden-sret returns and first stack by-value
aggregate field-read shape
varargs remain rejected at declarations and call sites
selected small INTEGER/INTEGER aggregate returns are lowered in %rax/%rdx
selected SSE/INTEGER aggregate returns are lowered in %xmm0/%rax
selected SSE/SSE aggregate returns are lowered in %xmm0/%xmm1
the local x86_64 SysV aggregate classifier records INTEGER, SSE, mixed
INTEGER/SSE, and MEMORY decisions; lowering currently accepts selected
INTEGER/INTEGER, mixed INTEGER/SSE, SSE/INTEGER, and SSE/SSE field-read forms
arbitrary hidden sret storage, arbitrary stack-passed byval copies, complete
aggregate lowering for every classified shape, and multi-target ABI parity are not implemented
```

## Rejected Surface

The first slice rejects:

```text
indirect calls
inline assembly calls
varargs
byval/sret lowering beyond the selected frontier MEMORY aggregate shape
operand bundles
invoke
callbr
tail, musttail, and notail markers
unsupported call attributes
unsupported calling conventions
```

## Optimizer Legality

Calls are classified as unknown memory effects. This deliberately blocks DCE,
GVN, EarlyCSE, LICM, SROA, mem2reg, and SimplifyCFG from treating calls as pure
or movable while the project lacks alias/mod-ref and call-graph infrastructure.

This follows LLVM's shape around `CallBase`/`CallInst` and
`Instruction::mayReadOrWriteMemory`, but the local behavior is more
conservative until call attributes, memory effects, and target lowering are
modeled.

## Fixture Coverage

Current unit tests cover:

```text
function declaration parse/print/verify round trip
direct non-void call parse/print/verify round trip
direct void call parse/print/verify round trip
call signature mismatch rejection
indirect call rejection
tail-call marker rejection
invoke rejection
call_no_args assembly fixture
call_one_arg assembly fixture
call_two_args assembly fixture
call_return_used one-spill assembly fixture
call_stack_slot stack-memory-to-call assembly, objdump, and readelf fixture
call_internal assembly and objdump fixture
unsupported non-default calling convention diagnostic
multiple stack-passed i32 call arguments
mixed integer/SSE scalar call streams
selected small INTEGER/INTEGER aggregate return and argument-field reads
selected mixed INTEGER/SSE aggregate argument-field reads
selected reversed mixed SSE/INTEGER aggregate argument-field reads
selected SSE/SSE aggregate argument-field reads and register returns
selected up-to-three-live-i32 spill/reload call frame
unsupported four-or-more-live call pressure diagnostic
unsupported varargs/vector/sret/byval/larger aggregate ABI diagnostics
```

Object relocation fixtures cover the current direct external call subset with
`R_X86_64_PLT32` and addend `-4`. Internal direct calls use the same relocation
path instead of resolving local displacements during object emission. Later
slices must add broader readelf checks.
