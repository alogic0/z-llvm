# mem2reg

LLVM references:

```text
llvm-project-22/llvm/lib/Passes/PassRegistry.def
llvm-project-22/llvm/include/llvm/Transforms/Utils/PromoteMemToReg.h
llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
```

Upstream entry points to check:

```text
FUNCTION_PASS("mem2reg", PromotePass())
isAllocaPromotable
PromoteMemToReg
PromoteMem2Reg::run
PromoteMem2Reg::RenamePass
```

This pass promotes simple stack slots to SSA values.

Implemented subset:

```text
single-basic-block alloca promotion
only direct load/store users of the alloca pointer are promotable
loads before the first store keep the slot unpromoted
store instructions update the current SSA value for the slot
load results are replaced with the current SSA value
promoted alloca/load/store instructions are removed from printed IR
```

Upstream mapping:

```text
This reproduces LLVM mem2reg's same-block scalar replacement idea before phi insertion is needed.
LLVM's PromoteMemToReg handles many blocks with dominance-frontier phi placement, rename stacks, debug-info assignment tracking, lifetime intrinsics, unreachable uses, and poison/undef details for uninitialized loads.
```

Example:

```text
before:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load i32, ptr %slot
  ret i32 %v

after mem2reg:
  ret i32 %a
```

Known gaps:

```text
no multi-block promotion
no phi insertion
no dominance-frontier placement
no alloca arrays
no lifetime intrinsics
no debug-info salvage
no undef/poison modeling for uninitialized loads
```
