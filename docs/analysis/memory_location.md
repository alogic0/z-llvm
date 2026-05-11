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
  DataLayout for supported aggregate struct/array offsets when available.

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
  Constant-index struct-field and fixed-array element offsets for the accepted
  textual aggregate subset
  Load/store access sizes

Intentional divergences:
  The offset calculation is still not a general LLVM GEP/DataLayout
  implementation. It accepts only the scalar and simple aggregate shapes needed
  by current optimizer fixtures.

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
constant struct-field getelementptr offsets for textual `{ ... }` aggregates
constant fixed-array getelementptr offsets for textual `[N x T]` aggregates
pointer-typed function parameters as conservative root objects only for
same-parameter aggregate pointer GEP offsets
load/store access locations using the load/store value type as the access size
```

The GEP rule above is deliberately narrow. It is valid only for current
scalar-integer and simple aggregate stack fixtures where each constant index
can be mapped through the local type-size subset or the parsed module
DataLayout. It is not a general LLVM GEP layout algorithm.

Upstream mapping:

```text
LLVM MemoryLocation represents a memory access by pointer, size, and metadata-like tags.
BasicAA combines MemoryLocation with GEP decomposition, object identity, DataLayout, captures, globals, and recursive AA queries.
This project only models stack-slot and pointer-parameter roots plus byte
offsets/sizes for scalar integer allocas, simple aggregate allocas, and simple
constant GEPs. Anything needing nested aggregate slicing, vector layout,
address spaces, or metadata-sensitive decomposition must currently remain
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
  known disjoint same-parameter GEP access range no_mod_ref
  unknown GEP offset may-alias
  mod/ref no_mod_ref for known disjoint stack location
  volatile/atomic barrier remains unknown
  memory location aggregate helpers classify array elements as fields
```

Known gaps:

```text
no address spaces
no globals
no capture-sensitive disambiguation between distinct parameters
no calls
partial_alias is represented by alias analysis when two MemoryLocation ranges
overlap but are not identical
disjoint byte ranges are used by DSE to skip unrelated field stores while
looking for a complete overwrite
no general aggregate, nested struct, or vector layout
no LLVM-equivalent structured GEP decomposition
no metadata such as TBAA, alias.scope, or invariant.group
```
