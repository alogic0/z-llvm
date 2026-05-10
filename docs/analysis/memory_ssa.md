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
  placeholder

Implemented subset:
  None. Current memory passes use local MemoryLocation and alias/mod-ref
  queries directly.

Intentional divergences:
  DSE uses a single-block reverse scan instead of MemorySSA.
  LICM does not move memory instructions.

Analysis preservation/invalidation:
  No local MemorySSA analysis exists yet.

Fixture coverage:
  none

opt-22 comparison command:
  not applicable yet

Local-only fixture command:
  zig build test
```
