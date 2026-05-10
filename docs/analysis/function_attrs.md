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
  Raw attribute parsing plus conservative call memory classification.
```

Implemented subset:

```text
recognize readnone, readonly, nounwind, noinline, alwaysinline, and cold in raw function/declaration attributes
classify direct calls to readnone callees as no memory effect
classify direct calls to readonly callees as readonly memory
classify all other calls as unknown
```

Intentional divergences:

```text
no attribute group resolution for #N groups
no inference pass yet
no parameter attribute semantics beyond parser/printer preservation
no call-site attributes
no CGSCC propagation
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  readnone, readonly, and unknown direct-call memory effect unit test

unit-test only:
  raw attribute classification and call mod/ref boundary
```
