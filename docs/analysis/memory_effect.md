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
classify fixed-vector lane operations as no memory access
classify nonvolatile nonatomic load as readonly_load
classify nonvolatile nonatomic store as memory_write
classify volatile or atomic load/store as volatile_or_atomic_barrier
classify side-effecting inline asm as volatile_or_atomic_barrier
classify atomicrmw, cmpxchg, and fence as volatile_or_atomic_barrier
expose mayReadMemory, mayWriteMemory, and hasSideEffects helpers over that classification
expose mayReadOrWriteMemory, mayThrow, mayTrap, isSafeToDelete, and isSafeToSpeculativelyExecute helpers
split volatile and atomic spelling through barrierKind while keeping both as hard barriers
feed DCE, ADCE, GVN, and LICM legality through the shared classification
feed EarlyCSE candidate legality through the shared safe-to-delete helper
pair with alias.modRef for conservative load/store mod-ref answers
partial-alias ranges from alias analysis remain mod/ref barriers
pair with the MemorySSA-like clobber helper for GVN load availability
```

Fixture coverage:

```text
opt-22 equivalent:
  dce_scalar_with_memory
  dce_volatile_load_reject
  gvn_scalar_with_memory
  licm_scalar_with_memory
  vector_lane_dead_dce

local-only conservative:
  licm_aligned_load_reject
  memory_atomic_barrier_reject
  inline_asm_barrier_preserve
  atomic_rmw_cmpxchg_fence_barrier

unit-test only:
  memory effect classification for pure instruction, vector lane instruction,
  readonly load, volatile load, store, atomic store, inline asm, atomicrmw,
  cmpxchg, and fence
  volatile, atomic, and inline asm barrier kind classification
  may-throw call and may-trap division classification
  safe-to-delete and safe-to-speculate predicates
  conservative unknown-pointer mod/ref behavior
```

Upstream mapping:

```text
This reproduces the first shared legality layer behind LLVM's instruction memory predicates and mod/ref queries.
LLVM has richer behavior for calls, intrinsics, atomic ordering, target library calls, MemorySSA, MemoryLocation sizes, and metadata-driven memory facts.
This project currently treats volatile, atomic, and inline-asm memory as hard barriers and leaves all memory motion disabled unless a later pass proves safety explicitly. Fixed-vector lane operations are pure instructions, not memory barriers.
Direct calls use preserved callee attributes only for the local `memory(none)`,
`memory(read)`, `memory(write)`, `readnone`, `readonly`, and `writeonly`
classification boundary.
LICM also rejects locally trapping scalar operations such as division by an unknown denominator through the shared speculation helper.
```

Known gaps:

```text
inline asm constraints and full atomic ordering are not interpreted
syncscope remains rejected
no intrinsic classification beyond explicit parser rejection
no target-library handling and no inferred call attributes
MemoryLocation size and offset model is limited to accepted scalar stack,
global, and parameter GEP accesses
no MemoryLocation metadata model
MemorySSA-like integration is limited to a linear clobber helper for accepted
load/store/call checks
no alias-aware instruction reordering
no distinction between acquire/release/monotonic/etc ordering semantics
no address spaces, globals, captures, or target DataLayout
no target-cost interpretation for vector lane operations
```
