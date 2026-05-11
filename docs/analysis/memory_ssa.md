# MemorySSA Design Note

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/MemorySSA.h
llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp
llvm-project-22/llvm/lib/Analysis/MemorySSAUpdater.cpp
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/MemorySSA.h
  llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp

LLVM entry points/classes:
  MemorySSA
  MemoryDef
  MemoryUse
  MemoryPhi
  MemorySSAUpdater

Required analyses:
  CFG
  DominatorTree
  AliasAnalysis
  MemoryLocation

Required IR invariants:
  Verified memory instructions and CFG.

Core LLVM algorithm data structures:
  Def/use chain for memory state
  MemoryPhi nodes at CFG joins
  Walker queries for clobbering memory accesses

Local target status:
  LLVM-shaped clobber-query subset

Implemented subset:
  InstRef identifies a memory access by block and instruction index.
  hasClobberBetween scans the accepted IR region between two accesses.
  alias.modRef decides whether an intervening instruction is a def/barrier for
  the queried pointer.
  readnone and readonly direct calls are treated as non-clobbering for load
  availability through function attribute classification.
  unknown calls, volatile memory, atomic memory, may-alias stores, and
  same-pointer stores are clobbers.
  GVN load availability uses this shared helper.
  EarlyCSE load CSE uses this helper before replacing an available load.

Intentional divergences:
  DSE uses a single-block reverse scan instead of MemorySSA.
  LICM does not move memory instructions.
  EarlyCSE still uses scoped local availability for store-to-load forwarding.
  The helper is a linear conservative scan, not a MemorySSA def/use graph with
  MemoryPhi placement.

Analysis preservation/invalidation:
  No persisted local MemorySSA analysis exists yet; callers rebuild/query the
  accepted function directly.

Fixture coverage:
  unit test: memory ssa clobber helper covers accepted memory-dependence cases
  opt fixtures: early_cse_load_call_clobber_reject, gvn_load_call_clobber_reject

opt-22 comparison command:
  covered indirectly through GVN and EarlyCSE memory fixtures in
  `bash scripts/compare_opt.sh`

Local-only fixture command:
  zig build test
```
