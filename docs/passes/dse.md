# DSE

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp
llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp
  llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp

LLVM entry points/classes:
  DSEPass::run
  eliminateDeadStores
  MemorySSA
  AAResults::getModRefInfo

Required analyses:
  Local MemoryLocation
  Local alias/mod-ref queries

Required IR invariants:
  Verified load/store pointer operands and memory attributes.

Core LLVM algorithm data structures:
  Memory-def/use walk
  MemoryLocation ranges
  Alias/mod-ref queries
  Intervening read/barrier checks

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Single-block overwrite query through the local MemorySSA helper
  Remove a stack store overwritten by a later must-alias store
  Preserve stores when a load, call, volatile/atomic access, unknown pointer, or
  may-alias access intervenes

Intentional divergences:
  No full MemorySSA walker/updater.
  No cross-block DSE.
  No partial-overwrite DSE.
  No memset/memcpy/memmove handling.
  DSE deliberately keeps the query same-block only. Cross-block DSE waits until
  the MemorySSA helper can model overwrite direction across MemoryPhi-like
  joins.

Analysis preservation/invalidation:
  DSE mutates memory instructions and invalidates analyses under the local
  pass-manager policy. The pass manager verifies after execution.

Fixture coverage:
  dse_overwrite
  dse_load_barrier

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

Known gaps:

```text
no full MemorySSA walker/updater
no post-dominator or cross-block reasoning
no partial-overlap handling
no target-library memory intrinsic handling
no debug-info salvage
```
