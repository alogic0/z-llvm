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
store iN %value, ptr %slot
%derived = getelementptr iN, ptr %slot, iN <index>
verification that load/store pointer operands have ptr type
verification that store value operands match the stored type
verification that getelementptr base operands have ptr type and at least one typed index
```

Upstream mapping:

```text
This reproduces the basic IR shape and verifier checks needed before memory optimization passes can run, plus a first opaque-pointer GEP form for pointer-derived memory operands.
LLVM's memory instructions carry much more state: alignment, volatile and atomic ordering, address spaces, metadata, attributes, and target datalayout-sensitive rules.
```

Known gaps:

```text
no typed pointer or address-space modeling
no alignment
no volatile or atomic memory operations
no datalayout-aware getelementptr offset computation
no lifetime intrinsics
no datalayout checks
```
