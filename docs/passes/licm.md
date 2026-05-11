# LICM

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Transforms/Scalar/LICM.h
llvm-project-22/llvm/lib/Transforms/Scalar/LICM.cpp
llvm-project-22/llvm/include/llvm/Analysis/LoopInfo.h
```

Upstream entry points to check:

```text
LICMPass::run
LoopInvariantCodeMotion::runOnLoop
hoistRegion
canSinkOrHoistInst
Loop::getLoopPreheader
Loop::hasLoopInvariantOperands
Loop::makeLoopInvariant
Instruction::mayReadOrWriteMemory
```

LLVM LICM hoists loop-invariant computations to a loop preheader and sinks
computations out of loops when legal. Full LLVM LICM relies on LoopInfo,
DominatorTree, AliasAnalysis, MemorySSA, safety checks for trapping behavior,
and metadata updates.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/Scalar/LICM.cpp

LLVM entry points/classes:
  LICMPass::run
  LoopInvariantCodeMotion::runOnLoop
  hoistRegion
  sinkRegion
  canSinkOrHoistInst

Required analyses:
  LoopInfo.
  DominatorTree.
  AliasAnalysis and MemorySSA for memory LICM.
  AssumptionCache and TargetLibraryInfo for broader legality checks.

Required IR invariants:
  Hoist destination must dominate all loop blocks and all rewritten uses.
  Moved instructions must be safe to execute at the preheader.
  Memory operations require alias/mod-ref proof before movement.

Core LLVM algorithm data structures:
  Loop block traversal.
  Loop preheader and exit queries.
  MemorySSA updater for memory motion.
  Worklists for hoist and sink candidates.

Local target status:
  LLVM-shaped algorithm subset.
```

Implemented subset:

```text
use LoopInfo natural loops
require an existing unique unconditional preheader
require the loop header to map to one current NaturalLoop record
use shared memory-effect classification for legality
use shared safe-to-speculate checks so trapping scalar instructions are not hoisted
hoist pure binary, integer cast, icmp, and select instructions
require every operand to be constant, undef, a function parameter, or defined outside the loop
move hoisted instructions to the preheader instruction list
preserve SSA validity by moving only to the preheader, which dominates the loop header in the supported canonical shape
```

Current legality boundary:

```text
hoistable: side-effect-free scalar binary, integer cast, icmp, and select instructions
not hoistable: freeze, phi, alloca, load, store, getelementptr, volatile or atomic barriers, trapping division
not represented yet and therefore not hoistable: calls and unknown memory effects
```

LLVM's full LICM uses `canSinkOrHoistInst`, alias analysis, MemorySSA, and
speculation-safety checks to decide whether memory operations can move. This
project deliberately keeps memory LICM disabled until the required alias/mod-ref
or MemorySSA foundation exists.

Fixture coverage:

```text
opt-22 compared: invariant scalar hoist, variant-operand rejection, dominance-preserving scalar-chain hoist
opt-22 compared memory legality: scalar hoisting beside volatile memory
local only: no-preheader rejection, side-effecting store rejection, memory-load rejection, aligned-load rejection, trapping-division rejection, atomic barrier rejection, multi-latch rejection
```

The local-only cases are intentional current-scope boundaries. LLVM's LICM
pipeline can create preheaders and can promote or sink some memory operations
through MemorySSA. LLVM also represents multi-latch loops as one loop, while
the current LoopInfo model records one natural loop per backedge. Matching those
behaviors belongs to later LoopSimplify, LoopInfo nesting/canonicalization, and
memory LICM slices.

Known gaps:

```text
no load/store/call hoisting or sinking
no MemorySSA or alias analysis integration
no poison or freeze speculation safety checks beyond the current trapping-division guard
no loop nest ordering beyond current natural-loop list
no multi-latch loop hoisting
no preheader creation
no LCSSA, metadata, debug-info, or analysis preservation updates
```
