# Memory IR Subset

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/include/llvm/IR/Operator.h
```

Upstream entry points to check:

```text
AllocaInst
LoadInst
StoreInst
GetElementPtrInst
GEPOperator
Instruction::mayReadOrWriteMemory
Instruction::isAtomic
Instruction::isVolatile
Verifier::visitAllocaInst
Verifier::visitLoadInst
Verifier::visitStoreInst
Verifier::visitGetElementPtrInst
```

Implemented subset:

```text
opaque ptr type parsing and printing
%slot = alloca iN
%value = load iN, ptr %slot
%value = load volatile iN, ptr %slot, align N
%value = load atomic iN, ptr %slot, <ordering>, align N
store iN %value, ptr %slot
store volatile iN %value, ptr %slot, align N
store atomic iN %value, ptr %slot, <ordering>, align N
%derived = getelementptr iN, ptr %slot, iN <index>
verification that load/store pointer operands have ptr type
verification that store value operands match the stored type
verification that parsed memory alignment is nonzero
verification that getelementptr base operands have ptr type and at least one typed index
```

Upstream mapping:

```text
This reproduces the basic IR shape and verifier checks needed before memory optimization passes can run, plus a first opaque-pointer GEP form for pointer-derived memory operands.
LLVM's memory instructions carry much more state: alignment, volatile and atomic ordering, address spaces, metadata, attributes, and target datalayout-sensitive rules.
This subset preserves align and volatile spelling on load/store and recognizes narrow atomic load/store spelling only as a conservative memory barrier.
It deliberately rejects unsupported atomic operations such as cmpxchg and atomicrmw instead of modeling LLVM's full atomic ordering rules.
```

Known gaps:

```text
no typed pointer or address-space modeling
no semantic use of alignment for optimization
no full volatile or atomic memory model
no cmpxchg, atomicrmw, fence, syncscope, or atomic ordering semantics
no datalayout-aware getelementptr offset computation
no lifetime intrinsics
no datalayout checks
```
