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
  Single-block reverse scan
  Remove a stack store overwritten by a later must-alias store
  Preserve stores when a load, call, volatile/atomic access, unknown pointer, or
  may-alias access intervenes

Intentional divergences:
  No MemorySSA graph yet.
  No cross-block DSE.
  No partial-overwrite DSE.
  No memset/memcpy/memmove handling.
  DSE deliberately keeps its single-block reverse scan for this cycle. Moving
  it to the shared clobber helper waits until the helper can model overwrite
  direction and MemoryPhi-like joins rather than only answering load
  availability.

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
no MemorySSA
no post-dominator or cross-block reasoning
no partial-overlap handling
no target-library memory intrinsic handling
no debug-info salvage
```
