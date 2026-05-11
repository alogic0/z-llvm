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

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Utils/Mem2Reg.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp
  llvm-project-22/llvm/include/llvm/Transforms/Utils/PromoteMemToReg.h

LLVM entry points/classes:
  PromotePass::run
  isAllocaPromotable
  PromoteMemToReg
  PromoteMem2Reg::QueuePhiNode
  PromoteMem2Reg::RenamePass

Required analyses:
  Dominator tree
  Dominance frontier
  CFG predecessor/successor graph

Required IR invariants:
  Entry-block alloca discovery
  Verified direct load/store uses
  Verified phi and SSA dominance

Core LLVM algorithm data structures:
  Entry-block alloca worklist
  Promotability checks
  Dominance-frontier phi placement
  Rename stacks/current-value state

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Entry-block scalar allocas
  Direct non-volatile non-atomic loads/stores
  Single-store fast path when the store dominates every load
  Single-block and multi-block promotion
  Live-in block pruning before dominance-frontier PHI placement
  Multi-slot promotion by repeated local promotion
  Undef replacement for promoted uninitialized loads

Intentional divergences:
  Atomic local alloca users are rejected conservatively.
  Debug-info salvage, lifetime intrinsics, and batched alloca promotion are not
  implemented yet.

Analysis preservation/invalidation:
  mem2reg mutates IR and invalidates analyses under the local pass-manager
  policy. The pass manager verifies after execution.

Fixture coverage:
  mem2reg
  mem2reg_single_store
  mem2reg_undef
  mem2reg_if
  mem2reg_loop
  mem2reg_two_slots
  mem2reg_unreachable
  mem2reg_escape
  mem2reg_store_slot
  mem2reg_non_entry_alloca
  mem2reg_volatile_load
  mem2reg_volatile_store
  gep_memory

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

This pass promotes simple stack slots to SSA values.

Implemented subset:

```text
single-basic-block alloca promotion
single-store promotion when one store dominates every load
one multi-block stack slot per pass invocation
multiple independent stack slots promoted until no promotable alloca remains
alloca discovery restricted to the function entry block
only direct load/store users of the alloca pointer are promotable
volatile and atomic load/store users are rejected as memory barriers
loads before the first store keep the slot unpromoted
uninitialized promoted loads are replaced with undef
dominance-frontier phi placement for join blocks
live-in pruning to avoid PHIs in blocks where the promoted value is not live on entry
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
alloca outside the function entry block
volatile load/store through the alloca
atomic load/store through the alloca
alloca forms with array counts, alignment, address spaces, or non-parsed type syntax
```

Upstream mapping:

```text
This reproduces LLVM mem2reg's same-block scalar replacement, single-store rewrite, live-in filtered dominance-frontier phi-placement, and rename-walk shape.
LLVM's `Mem2Reg.cpp` pass wrapper finds promotable allocas by scanning only `Function::getEntryBlock`; this project follows that entry-block discovery rule.
The promotability filter maps to LLVM's `isAllocaPromotable`: this subset accepts only direct non-volatile load/store users and rejects escapes conservatively.
LLVM rejects volatile load/store users. LLVM permits atomic load/store users on local allocas, but this project currently rejects atomic users too because the shared memory-effect model treats atomic instructions as barriers until a more precise local-alloca exception is implemented.
LLVM's PromoteMemToReg promotes many allocas per run and supports precise debug-info assignment tracking, lifetime intrinsics, unreachable uses, and poison/undef details for uninitialized loads.
This subset models the basic uninitialized-load result as `undef`, but does not yet implement LLVM's full poison/undef semantics.
```

Fixture coverage:

```text
opt-22 equivalent:
  mem2reg
  mem2reg_single_store
  mem2reg_undef
  mem2reg_if
  mem2reg_loop
  mem2reg_two_slots
  mem2reg_unreachable
  mem2reg_escape
  mem2reg_store_slot
  mem2reg_non_entry_alloca
  mem2reg_volatile_load
  mem2reg_volatile_store
  gep_memory

local-only conservative:
  atomic alloca users are rejected by unit tests, while LLVM mem2reg can promote atomic local alloca accesses

unit-test only:
  single-block promotion behavior
  promotability helper edge cases
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
no dynamic or non-entry alloca promotion
no alloca arrays
no lifetime intrinsics
no debug-info salvage
no undef/poison modeling for uninitialized loads
```
