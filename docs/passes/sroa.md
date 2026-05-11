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

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Transforms/Scalar/SROA.h
  llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp

LLVM entry points/classes:
  SROAPass::run
  SROA::splitAlloca
  SROA::rewritePartition
  AllocaSlices
  PromoteMemToReg

Required analyses:
  DataLayout for real slice offsets
  Local mem2reg promotion after rewrites

Required IR invariants:
  Verified alloca, GEP, load, and store uses for the accepted memory subset.

Core LLVM algorithm data structures:
  Alloca slice collection
  Slice partitioning
  Rewrite decisions
  PromoteMemToReg handoff for scalarized slots

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  AllocaSlice records for GEP users rooted in an alloca
  SlicePartition lookup by GEP result
  DataLayout-like offset/size facts through `src/analysis/memory_location.zig`
  Zero-offset partition forwarding to the base alloca
  Nested zero-offset partition forwarding to the base alloca
  mem2reg handoff after forwarding

Intentional divergences:
  Non-zero known offsets are not rewritten yet because the local IR has no
  aggregate/vector type model to split into replacement allocas.
  DataLayout-backed offset facts are currently used by alias/memory-location
  analysis, not by SROA rewriting.

Analysis preservation/invalidation:
  SROA mutates pointer uses and then runs mem2reg, so it invalidates analyses
  under the local pass-manager policy. The pass manager verifies after
  execution.

Fixture coverage:
  sroa_zero_gep
  sroa_nested_zero_gep

Zig-emitted aggregate coverage:
  The current accepted parser surface does not yet include LLVM aggregate types,
  insertvalue/extractvalue, or aggregate allocas from the Zig corpus. Those
  inputs remain explicit unsupported SROA cases until the IR surface lands.

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

LLVM SROA rewrites aggregate and sliced stack objects into smaller scalar
allocas and promotes simple scalar stack slots when possible.

Implemented subset:

```text
recognize getelementptr instructions whose base pointer is an alloca
recognize nested zero-offset getelementptr chains whose root is an alloca
collect alloca-rooted GEPs as slices with offset, size, and compatibility state
look up the rewrite partition for each GEP result
require every GEP index to be integer constant zero
replace uses of that zero-offset GEP result with the base alloca pointer
run the existing mem2reg promotion after forwarding
```

This matches the first useful alloca-forwarding case needed before real slice
partitioning. It lets a trivial zero-offset GEP stop blocking stack promotion.

Fixture coverage:

```text
opt-22 equivalent:
  sroa_zero_gep
  sroa_nested_zero_gep

local-only conservative:
  none currently

unit-test only:
  none currently
```

Known gaps:

```text
no aggregate type model
no byte-offset slice builder
no splitting into new allocas
no partial load/store rewriting
no memcpy/memmove rewriting
no padding, integer widening, vector, or packed-aggregate handling
no module-level target DataLayout parser; current offset facts use the local
memory-location type-size subset
```
