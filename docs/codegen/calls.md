# Direct Calls and Stack-Frame Codegen

This document tracks the call-codegen epic from the IR surface upward. The first
implemented slice is an LLVM-compatible IR contract only: declarations and direct
calls can be parsed, printed, verified, and carried conservatively through
existing analysis and optimizer passes. Machine call lowering is intentionally
not implemented yet.

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

bootstrap-only:
  Machine IR direct-call representation supports assembly and ELF call relocations only
  x86_64 argument move lowering only accepts already-matching i32 argument registers
  no general stack-frame emission yet
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
i32 direct call arguments already in their ABI argument registers
i32 call return in %eax
void calls with no result
one straight-line basic block
at most one live i32 caller argument across one call
```

The local stack-alignment sequence is:

```asm
subq $8, %rsp
callq callee
addq $8, %rsp
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

LLVM `llc-22 -O0` commonly emits `pushq %rax` / `popq` for the same tiny
alignment need. This project uses `subq` / `addq` so the spill slot is explicit
and easy to inspect.

## Rejected Surface

The first slice rejects:

```text
indirect calls
inline assembly calls
varargs
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
call_internal assembly and objdump fixture
unsupported non-default calling convention diagnostic
unsupported stack-passed call argument diagnostic
unsupported multiple-live-value call pressure diagnostic
```

Object relocation fixtures cover the current direct external call subset with
`R_X86_64_PLT32` and addend `-4`. Internal direct calls use the same relocation
path instead of resolving local displacements during object emission. Later
slices must add broader readelf checks.
