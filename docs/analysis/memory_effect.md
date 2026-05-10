# Memory Effect Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instruction.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Instruction.cpp
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h
```

Upstream entry points to check:

```text
Instruction::mayReadOrWriteMemory
Instruction::mayReadFromMemory
Instruction::mayWriteToMemory
Instruction::mayHaveSideEffects
LoadInst::isVolatile
StoreInst::isVolatile
LoadInst::isAtomic
StoreInst::isAtomic
AtomicOrdering
AAResults::getModRefInfo
ModRefInfo
MemoryLocation
```

LLVM exposes memory behavior through instruction predicates, volatile/atomic
state on memory instructions, and alias/mod-ref queries over `MemoryLocation`.
Scalar passes use those queries to decide whether an instruction can be removed,
value-numbered, hoisted, sunk, or reordered.

Implemented subset:

```text
classify scalar binary, icmp, select, phi, alloca, and getelementptr as no memory access
classify nonvolatile nonatomic load as readonly_load
classify nonvolatile nonatomic store as memory_write
classify volatile or atomic load/store as volatile_or_atomic_barrier
expose mayReadMemory, mayWriteMemory, and hasSideEffects helpers over that classification
feed DCE, ADCE, GVN, and LICM legality through the shared classification
pair with alias.modRef for conservative load/store mod-ref answers
```

Fixture coverage:

```text
opt-22 equivalent:
  dce_scalar_with_memory
  dce_volatile_load_reject
  gvn_scalar_with_memory
  licm_scalar_with_memory

local-only conservative:
  licm_aligned_load_reject
  memory_atomic_barrier_reject

unit-test only:
  memory effect classification for pure instruction, readonly load, volatile load, store, and atomic store
  conservative unknown-pointer mod/ref behavior
```

Upstream mapping:

```text
This reproduces the first shared legality layer behind LLVM's instruction memory predicates and mod/ref queries.
LLVM has richer behavior for calls, intrinsics, fences, atomics, target library calls, MemorySSA, MemoryLocation sizes, and metadata-driven memory facts.
This project currently treats volatile/atomic memory as a hard barrier and leaves all memory motion disabled unless a later pass proves safety explicitly.
```

Known gaps:

```text
no call, intrinsic, fence, cmpxchg, or atomicrmw classification
no target-library or readonly/readnone call handling
MemoryLocation size and offset model is limited to scalar stack-slot accesses
no MemoryLocation metadata model
no MemorySSA integration
no alias-aware instruction reordering
no distinction between acquire/release/monotonic/etc ordering semantics
no address spaces, globals, captures, or target DataLayout
```
