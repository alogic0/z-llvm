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
PromoteMem2Reg::QueuePhiNode
PromoteMem2Reg::RenamePass
```

This pass promotes simple stack slots to SSA values.

Implemented subset:

```text
single-basic-block alloca promotion
one multi-block stack slot per pass invocation
only direct load/store users of the alloca pointer are promotable
loads before the first store keep the slot unpromoted
dominance-frontier phi placement for join blocks
dominator-tree rename walk for promoted stack-slot values
phi incoming updates for CFG predecessors
store instructions update the current SSA value for the slot
load results are replaced with the current SSA value
promoted alloca/load/store instructions are removed from printed IR
```

Upstream mapping:

```text
This reproduces LLVM mem2reg's same-block scalar replacement and the first dominance-frontier phi-placement plus rename-walk shape.
LLVM's PromoteMemToReg supports many allocas per run, precise debug-info assignment tracking, lifetime intrinsics, unreachable uses, and poison/undef details for uninitialized loads.
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

Multi-block example:

```text
before:
left:
  store i32 %a, ptr %slot
  br label %merge
right:
  store i32 %b, ptr %slot
  br label %merge
merge:
  %v = load i32, ptr %slot
  ret i32 %v

after mem2reg:
merge:
  %merge = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %merge
```

Known gaps:

```text
only one multi-block alloca is promoted per pass invocation
generated phi names use the destination block name
no alloca arrays
no lifetime intrinsics
no debug-info salvage
no undef/poison modeling for uninitialized loads
```
