# AIR-Like Lowering Bridge

LLVM and Zig references:

```text
ziglang/src/codegen/llvm/FuncGen.zig
ziglang/src/codegen/llvm.zig
llvm-project-22/llvm/include/llvm/IR/IRBuilder.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
```

Upstream entry points to check:

```text
FuncGen.airAdd
FuncGen.airSub
FuncGen.airMul
FuncGen.airShl
FuncGen.airShr
FuncGen.airBitAnd
FuncGen.airBitOr
FuncGen.airBitXor
FuncGen.airIntCast
FuncGen.airRet
FuncGen.airBr
FuncGen.airCondBr
FuncGen.airUnreach
FuncGen.airRetLoad
FuncGen.resolveInst
IRBuilderBase::CreateAdd
IRBuilderBase::CreateRet
```

Implemented subset:

```text
test/helper builder, not a text input language
module source_filename, target triple, and datalayout preservation
one-entry-block functions
explicit basic blocks
scalar integer parameters
scalar integer binary operations
scalar integer casts: trunc, zext, sext
return, branch, conditional branch, and unreachable terminators
```

Upstream mapping:

```text
Zig lowers analyzed AIR instructions through FuncGen into LLVM IRBuilder calls.
This project now has a tiny builder that can construct the same project IR shape for scalar arithmetic examples without invoking the full Zig compiler.
The bridge is deliberately synthetic so optimizer and target tests can reduce failures to small inputs.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  scalar add function with two i32 parameters and an SSA return
  scalar sub/and/shl arithmetic with zext return
  conditional branch to return and unreachable blocks
  target triple and datalayout preservation on lowered modules
```

Known gaps:

```text
no AIR text parser
no full Zig AIR semantics
no stack memory lowering
no loops
no calls
no comparisons, select, overflow operations, or intrinsics
no aggregate, optional, error-union, async, comptime, or debug-info lowering
```
