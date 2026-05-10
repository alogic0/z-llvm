# MemoryLocation

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h
llvm-project-22/llvm/lib/Analysis/MemoryLocation.cpp
llvm-project-22/llvm/lib/Analysis/BasicAliasAnalysis.cpp
```

Upstream entry points to check:

```text
MemoryLocation
MemoryLocation::get
LocationSize
BasicAAResult::aliasGEP
AAResults::alias
AAResults::getModRefInfo
```

Implemented subset:

```text
pointer value
stack-slot root name
optional byte offset
optional byte size
direct alloca locations when the allocated integer type has byte size
simple getelementptr offsets computed as constant index * scalar integer element size
load/store access locations using the load/store value type as the access size
```

The GEP rule above is deliberately narrow. It is valid only for current
scalar-integer stack fixtures where each constant index steps over the same
known scalar element size. It is not a general LLVM GEP layout algorithm.

Upstream mapping:

```text
LLVM MemoryLocation represents a memory access by pointer, size, and metadata-like tags.
BasicAA combines MemoryLocation with GEP decomposition, object identity, DataLayout, captures, globals, and recursive AA queries.
This project only models stack-slot roots plus byte offsets/sizes for scalar integer allocas and simple constant GEPs.
Anything needing structured aggregate layout, nested element types, target
alignment, or DataLayout-driven offset decomposition must currently remain
unknown/conservative.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; this is currently analysis-only infrastructure

local-only conservative:
  none currently

unit-test only:
  same stack slot
  distinct stack slots
  zero-offset GEP must-alias
  known disjoint GEP offset no-alias
  unknown GEP offset may-alias
  mod/ref no_mod_ref for known disjoint stack location
  volatile/atomic barrier remains unknown
```

Known gaps:

```text
no target DataLayout
no address spaces
no globals
no calls or captures
no partial_alias result
no aggregate, struct, or vector layout
no LLVM-equivalent structured GEP decomposition
no metadata such as TBAA, alias.scope, or invariant.group
```
