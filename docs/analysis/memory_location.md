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

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h
  llvm-project-22/llvm/lib/Analysis/MemoryLocation.cpp
  llvm-project-22/llvm/lib/Analysis/BasicAliasAnalysis.cpp

LLVM entry points/classes:
  MemoryLocation
  MemoryLocation::get
  LocationSize
  BasicAAResult::aliasGEP

Required analyses:
  Local scalar type-size query.

Required IR invariants:
  Verified alloca/GEP/load/store spelling for the accepted memory subset.

Core LLVM algorithm data structures:
  Pointer value
  Root object identity
  Byte offset
  Byte size

Local target status:
  LLVM-shaped algorithm subset

Implemented subset:
  Direct stack-slot locations
  Simple scalar GEP offsets
  Load/store access sizes

Intentional divergences:
  The offset calculation is scalar-only and not a general LLVM GEP/DataLayout
  implementation.

Analysis preservation/invalidation:
  Memory locations are rebuilt on demand and have no preserved state.

Fixture coverage:
  unit tests in src/tests.zig

opt-22 comparison command:
  not applicable; currently analysis-only

Local-only fixture command:
  zig build test
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
