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
multiple independent stack slots promoted until no promotable alloca remains
only direct load/store users of the alloca pointer are promotable
loads before the first store keep the slot unpromoted
uninitialized promoted loads are replaced with undef
dominance-frontier phi placement for join blocks
dominator-tree rename walk for promoted stack-slot values
phi incoming updates for CFG predecessors
store instructions update the current SSA value for the slot
load results are replaced with the current SSA value
promoted alloca/load/store instructions are removed from printed IR
```

Rejected stack slots:

```text
alloca result returned or used by a terminator
alloca result used by arithmetic, icmp, phi, or another non-memory instruction
alloca result stored as a value into memory
alloca result used by any memory instruction other than direct load/store of that exact pointer
alloca forms with array counts, alignment, address spaces, or non-parsed type syntax
```

Upstream mapping:

```text
This reproduces LLVM mem2reg's same-block scalar replacement and the first dominance-frontier phi-placement plus rename-walk shape.
The promotability filter maps to LLVM's `isAllocaPromotable`: this subset accepts only direct non-volatile load/store users and rejects escapes conservatively.
LLVM's PromoteMemToReg promotes many allocas per run and supports precise debug-info assignment tracking, lifetime intrinsics, unreachable uses, and poison/undef details for uninitialized loads.
This subset models the basic uninitialized-load result as `undef`, but does not yet implement LLVM's full poison/undef semantics.
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
multi-block allocas are currently promoted one at a time in a loop rather than batched like LLVM
generated phi names follow the first LLVM-compatible stack-slot form: %slot.0, %slot.1, ...
no alloca arrays
no lifetime intrinsics
no debug-info salvage
no undef/poison modeling for uninitialized loads
```
