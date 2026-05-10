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
first i32 parameter in %edi
second i32 parameter in %esi
leaf functions only
no stack frame for register-only leaf functions
```

Upstream mapping:

```text
LLVM models x86_64 SysV calling conventions with target lowering tables and call-lowering code.
This project only models the register assignments needed by the first straight-line assembly fixtures.
```

Known gaps:

```text
no stack parameters
no callee-saved register saves
no caller-saved clobber model beyond the tiny leaf subset
no varargs
no aggregate returns
no floating-point or vector registers
no calls
```
