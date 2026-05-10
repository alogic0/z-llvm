# Scalar ABI Classification

LLVM references:

```text
llvm-project-22/llvm/include/llvm/CodeGen/TargetLowering.h
llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/AArch64/AArch64CallingConvention.td
llvm-project-22/llvm/lib/Target/WebAssembly/WebAssemblyISelLowering.cpp
```

Upstream entry points to check:

```text
TargetLowering::LowerFormalArguments
TargetLowering::LowerReturn
CallingConvLower
CCState
DataLayout::getPointerSizeInBits
```

Implemented subset:

```text
classify void returns as ignored
classify integer returns and parameters as integer values with their IR bit width
classify pointer returns and parameters as pointer values using DataLayout pointer size
classify whole project IR function signatures into return and parameter ABI slots
reject void parameters
require one of the initial supported targets:
  x86_64-linux-gnu
  x86_64-linux-musl
  aarch64-linux-gnu
  wasm32-wasi
```

Upstream mapping:

```text
LLVM ABI lowering is target-specific and assigns values to registers, stack slots, or indirect ABI locations.
This project currently implements only the first target-aware classification layer needed before AIR-like lowering and codegen can share the same signature facts.
It does not assign physical registers, stack offsets, byval/sret storage, or aggregate layouts yet.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; ABI classification is codegen/target infrastructure, not an opt pass

local-only conservative:
  none currently

unit-test only:
  void return classification
  i32 return classification
  pointer parameter classification for the initial target matrix
  whole-function signature classification for pointer, integer, and void signatures
  void parameter rejection
```

Known gaps:

```text
no aggregate ABI classification
no floating-point or vector classes
no varargs
no byval, sret, inreg, noalias, nocapture, or alignment attribute effects
no register assignment
no stack argument layout
no target feature or calling-convention-specific variation
```
