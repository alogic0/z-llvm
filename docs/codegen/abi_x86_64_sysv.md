# x86_64 SysV ABI Bootstrap

LLVM references:

```text
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86RegisterInfo.td
```

Upstream entry points to check:

```text
X86_64_SysV calling convention tables
X86TargetLowering::LowerFormalArguments
X86TargetLowering::LowerCall
X86TargetLowering::LowerReturn
X86FrameLowering::emitPrologue
X86FrameLowering::emitEpilogue
```

Implemented subset:

```text
i32 return value in %eax
first six integer/pointer-class register arguments are recognized as %edi, %esi, %edx, %ecx, %r8d, and %r9d for i32 values
i1 branch conditions use the matching low 8-bit argument registers
i32 direct-call operands use the same first-six argument register order
direct calls preserve SysV stack alignment by subtracting 8 from %rsp before callq and adding it back after the call
one live i32 caller argument can be spilled to (%rsp) across one call
leaf functions only
no stack frame for register-only leaf functions
```

Call stack rule:

```text
On x86_64 SysV function entry, %rsp % 16 == 8 because the return address has already been pushed.
Immediately before a nested callq, the caller must make %rsp % 16 == 0.
The current project uses a local-only conservative sequence for tiny call fixtures:
  subq $8, %rsp
  callq callee
  addq $8, %rsp
For one live caller argument, the 8-byte alignment slot is also used as a deterministic spill slot.
```

Register preservation boundary:

```text
Caller-saved set considered clobbered by calls in this slice:
  %rax, %rcx, %rdx, %rsi, %rdi, %r8, %r9, %r10, %r11
Callee-saved registers are not allocated by this project yet.
Only one live i32 argument register across one direct call is accepted.
```

Upstream mapping:

```text
LLVM models x86_64 SysV calling conventions with target lowering tables and call-lowering code.
This project only models the register assignments needed by the first straight-line and direct-call assembly fixtures.
Stack-passed parameters are rejected explicitly until frame layout and stack access lowering exist.
LLVM often emits `pushq %rax`/`popq` around tiny calls at `-O0`; the local `subq`/`addq` sequence has the same stack-alignment purpose for the accepted fixtures.
```

Known gaps:

```text
no stack parameters; functions needing them fail with an unsupported ABI diagnostic
no callee-saved register saves
no general caller-saved clobber model beyond one deterministic i32 spill
no varargs
no aggregate returns
no floating-point or vector registers
no indirect calls, tail calls, stack-passed call arguments, or non-default call conventions
```
