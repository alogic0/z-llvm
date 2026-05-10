# SROA

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Transforms/Scalar/SROA.h
llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp
```

Upstream entry points to check:

```text
SROAPass::run
SROA::splitAlloca
SROA::rewritePartition
SROA::propagateStoredValuesToLoads
AllocaSlices
PromoteMemToReg
```

LLVM SROA rewrites aggregate and sliced stack objects into smaller scalar
allocas and promotes simple scalar stack slots when possible.

Implemented subset:

```text
recognize getelementptr instructions whose base pointer is an alloca
require every GEP index to be integer constant zero
replace uses of that zero-offset GEP result with the base alloca pointer
run the existing mem2reg promotion after forwarding
```

This matches the first useful alloca-forwarding case needed before real slice
partitioning. It lets a trivial zero-offset GEP stop blocking stack promotion.

Known gaps:

```text
no aggregate type model
no byte-offset slice builder
no splitting into new allocas
no partial load/store rewriting
no memcpy/memmove rewriting
no padding, integer widening, vector, or packed-aggregate handling
no target DataLayout use
```
