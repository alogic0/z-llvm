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
MemoryLocation
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
%value = load iN, ptr getelementptr inbounds ... (...), align N
store iN %value, ptr %slot
store volatile iN %value, ptr %slot, align N
store atomic iN %value, ptr %slot, <ordering>, align N
store atomic iN %value, ptr getelementptr inbounds ... (...) <ordering>, align N
%derived = getelementptr iN, ptr %slot, iN <index>
%derived = getelementptr <source-ty>, ptr addrspace(N) %base, iN <index>
%old = atomicrmw <op> ptr %slot, iN %value, <ordering>, align N
%old = atomicrmw <op> ptr getelementptr inbounds ... (...), iN %value <ordering>, align N
%pair = cmpxchg ptr %slot, iN %expected, iN %replacement, <success-ordering> <failure-ordering>, align N
%pair = cmpxchg ptr getelementptr inbounds ... (...), iN %expected, iN %replacement <success-ordering> <failure-ordering>, align N
cmpxchg result type is modeled as `{ T, i1 }` for the compared value type `T`,
not as a fixed-width integer pair
fence <ordering>
verification that load/store pointer operands have ptr type
verification that store value operands match the stored type
verification that parsed memory alignment is nonzero
verification that getelementptr base operands have ptr type and at least one typed index
address-space pointer operands on getelementptr are preserved for source-backed
Debug rows
verification that accepted atomicrmw/cmpxchg/fence orderings and alignments are well formed
```

Upstream mapping:

```text
This reproduces the basic IR shape and verifier checks needed before memory optimization passes can run, plus a first opaque-pointer GEP form for pointer-derived memory operands.
LLVM's memory instructions carry much more state: alignment, volatile and atomic ordering, address spaces, metadata, attributes, and target datalayout-sensitive rules.
This subset preserves align and volatile spelling on load/store and recognizes narrow atomic load/store, atomicrmw, cmpxchg, fence, and supported syncscope spelling only as conservative memory barriers.
Source-backed Zig stage4 rows can place constant-expression `getelementptr` pointer operands directly inside load, store, atomicrmw, and cmpxchg instructions; the parser now preserves those operands opaquely as `Value.constant_expr`.
The analysis layer computes simple byte offsets for scalar integer GEPs when the index is constant and the element type has a byte size.
It deliberately rejects invalid atomic ordering combinations instead of modeling LLVM's full atomic ordering rules.
```

Known gaps:

```text
no typed pointer or address-space modeling
no semantic use of alignment for optimization
no full volatile or atomic memory model
no syncscope or atomic ordering semantics beyond parser/verifier preservation
inline asm and broader atomic semantics are tracked in
`docs/ir_atomics_inline_asm.md`
atomic load/store without syncscope currently print the local comma-normalized
ordering form even when source-backed LLVM IR omits that comma
no datalayout-aware getelementptr offset computation beyond scalar integer element sizes
no lifetime intrinsics
no datalayout checks
```
