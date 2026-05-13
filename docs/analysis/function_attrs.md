# Function Attributes And Call Mod/Ref

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/IPO/FunctionAttrs.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp
llvm-project-22/llvm/include/llvm/IR/Attributes.h
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
```

Function attributes describe call memory behavior and inlining constraints that
later scalar, memory, and IPO passes need.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/FunctionAttrs.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp

LLVM entry points/classes:
  PostOrderFunctionAttrsPass::run
  ReversePostOrderFunctionAttrsPass::run
  addMemoryAttrs
  checkFunctionMemoryAccess
  addNoRecurseAttrs
  mayHaveRecursiveCallee
  ForceFunctionAttrsPass::run
  AttributeList
  AAResults::getModRefInfo

Required analyses:
  Call graph or CGSCC traversal for inferred interprocedural attributes.
  Alias/mod-ref analysis for memory effect use.

Required IR invariants:
  Attribute interpretation must be conservative when raw attributes are unknown.
  Unknown direct calls must remain mod/ref barriers.

Core LLVM algorithm data structures:
  Attribute sets on declarations, definitions, and parameters.
  Call graph propagation.
  Mod/ref classification for calls.

Local target status:
  Raw and attribute-group parsing plus conservative call memory classification.
  function-attrs is an LLVM-shaped direct-call inference subset.
```

Implemented subset:

```text
recognize readnone, readonly, writeonly, argmemonly, nofree, norecurse, nosync,
nounwind, noinline, alwaysinline, and cold in raw function/declaration
attributes
resolve #N attribute groups for definitions and declarations
preserve target-cpu, target-features, frame-pointer, uwtable, size, and target
memory attributes textually without using them as optimization facts
classify direct calls to readnone callees as no memory effect
classify direct calls to readonly callees as readonly memory
classify direct calls to writeonly callees as memory writes
classify memory(none), memory(read), and memory(argmem: read) from Zig-emitted
attribute groups for local mod/ref legality
classify memory(write) and memory(argmem: write) as write-only memory effects
feed call memory classification into alias/mod-ref and MemorySSA clobber checks
infer memory(none), memory(read), and norecurse for acyclic direct-call
function definitions
classify all other calls as unknown
```

Intentional divergences:

```text
inference is limited to direct calls over local definitions and annotated
declarations
no parameter attribute semantics beyond parser/printer preservation
no call-site attributes
no full CGSCC propagation or LazyCallGraph RefSCC traversal
no writeonly inference
no inference through indirect calls, operand bundles, inline asm, recursive SCCs,
unknown external calls, volatile/atomic memory, or unknown memory effects
no target feature, CPU model, frame-pointer, unwind-table, or size-attribute
semantics beyond textual preservation
```

Fixture coverage:

```text
opt-22 equivalent:
  gvn_readonly_call_no_clobber
  gvn_unknown_call_clobber_reject

local-only conservative:
  function_attrs_direct_calls
  function_attrs_reject
  readnone, readonly, writeonly, and unknown direct-call memory effect unit test
  function/declaration IPO attribute group resolution test

unit-test only:
  raw attribute classification and call mod/ref boundary
  Zig-emitted memory(read, ...), memory(argmem: write), memory(readwrite, ...),
  target-cpu, and target-features preservation boundary
```
