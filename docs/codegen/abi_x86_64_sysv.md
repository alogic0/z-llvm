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
X86TargetLowering::LowerReturn
```

Implemented subset:

```text
i32 return value in %eax
first six integer/pointer-class register arguments are recognized as %edi, %esi, %edx, %ecx, %r8d, and %r9d for i32 values
i1 branch conditions use the matching low 8-bit argument registers
leaf functions only
no stack frame for register-only leaf functions
```

Upstream mapping:

```text
LLVM models x86_64 SysV calling conventions with target lowering tables and call-lowering code.
This project only models the register assignments needed by the first straight-line assembly fixtures.
Stack-passed parameters are rejected explicitly until frame layout and stack access lowering exist.
```

Known gaps:

```text
no stack parameters; functions needing them fail with an unsupported ABI diagnostic
no callee-saved register saves
no caller-saved clobber model beyond the tiny leaf subset
no varargs
no aggregate returns
no floating-point or vector registers
no calls
```
