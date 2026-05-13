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
  OverwriteResult
  isOverwrite
  isPartialOverwrite
  InstOverlapIntervalsTy
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
  Partial-overwrite interval tracking
  Alias/mod-ref queries
  Intervening read/barrier checks

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Single-block overwrite query through the local MemorySSA helper
  Remove a stack store overwritten by a later must-alias store
  Require the later store range to fully cover the earlier store range
  Track later partial integer-store byte intervals and remove the earlier store
  when their union covers the full earlier store
  Skip disjoint byte-range stores while searching for a later killing store
  Preserve stores when a load, call, volatile/atomic access, unknown pointer, or
  may-alias access intervenes
  Verify MemorySSA consistency after deleting stores

Intentional divergences:
  No full optimized MemorySSA walker/updater; only the first walker-shaped
  clobber API and simple access deletion/replacement helpers exist in the
  analysis layer.
  No cross-block DSE.
  Partial-overwrite DSE is limited to same-block fixed-size integer stores with
  known byte offsets. The interval set is intentionally small and rejects on
  unknown or excessive overlap complexity.
  No memset/memcpy/memmove handling.
  DSE deliberately keeps the query same-block only. Cross-block DSE waits until
  the MemorySSA helper can model overwrite direction across MemoryPhi-like
  joins.

Analysis preservation/invalidation:
  DSE mutates memory instructions and invalidates analyses under the local
  pass-manager policy. The pass manager verifies IR after execution, and DSE
  verifies rebuilt MemorySSA consistency for changed functions.

Fixture coverage:
  dse_overwrite
  dse_partial_overwrite_reject
  dse_partial_overwrite_lattice
  dse_load_barrier
  dse_volatile_barrier
  dse_disjoint_field_overwrite
  dse_unknown_call_barrier

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

Known gaps:

```text
no full optimized MemorySSA walker/updater
no post-dominator or cross-block reasoning
partial-overlap elimination is limited to same-block fixed-size integer stores
no target-library memory intrinsic handling
no lifetime marker handling
no debug-info salvage
```
