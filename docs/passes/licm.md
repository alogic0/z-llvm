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
Instruction::isSafeToSpeculativelyExecute
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
  collectPromotionCandidates
  isOnlyMemoryAccess
  promoteLoopAccessesToScalars
  LoopPromoter

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
  LLVM-shaped subset for listed scalar, invariant-load, and one stack-slot
  promotion fixture.
```

Implemented subset:

```text
use LoopInfo natural loops
require an existing unique unconditional preheader
require the loop header to map to one current NaturalLoop record
require the preheader to dominate the loop header
use shared memory-effect classification for legality
use shared safe-to-speculate checks so trapping scalar instructions are not hoisted
hoist pure binary, integer cast, icmp, and select instructions
require every operand to be constant, undef, a function parameter, or defined outside the loop
require the preheader definition to dominate every use after the move
move hoisted instructions to the preheader instruction list
preserve SSA validity by moving only to the preheader, which dominates the loop header in the supported canonical shape
nested loop legality is still driven by LoopInfo membership and dominance; the
new induction-variable recognition is reserved for later loop passes and is not
used to justify LICM movement
hoist selected memory-free scalar chains out through nested loop preheaders when
dominance and invariant operands allow it
hoist nonvolatile loads in the loop header when the pointer is loop-invariant,
the loop has no clobber for that access, and an existing preheader dominates
the header
reject memory LICM when the load pointer is defined inside the loop
promote one stack-slot memory location to a scalar loop-carried value when the
loop has exactly one nonvolatile load and one nonvolatile store to that pointer,
one self-latch, one dedicated exit, and no other memory effects
insert the promoted preheader load, loop PHI, exit LCSSA PHI, and exit writeback
store in the same shape as LLVM's `LoopPromoter` for the accepted fixture
```

Current legality boundary:

```text
hoistable: side-effect-free scalar binary, integer cast, icmp, select, and the
narrow header-load case described above
promotable: one alloca-backed integer slot with a single loop load/store pair,
no aliasing memory operations, a self-latch loop, and a dedicated exit
not hoistable: freeze, phi, alloca, store, getelementptr, volatile or atomic
barriers, trapping division, non-header loads, variant-pointer loads, and loads
with loop clobbers
not represented yet and therefore not hoistable: calls and unknown memory effects
```

LLVM's full LICM uses `canSinkOrHoistInst`, alias analysis, MemorySSA, and
speculation-safety checks to decide whether memory operations can move. This
project implements only one promotion shape from `promoteLoopAccessesToScalars`;
general promotion, sinking, and MemorySSA updater precision remain missing.

Fixture coverage:

```text
opt-22 compared: invariant scalar hoist, variant-operand rejection,
dominance-preserving scalar-chain hoist, nested memory-free scalar-chain hoist,
header load hoist, stack-slot memory promotion
local only: may-alias store rejection for memory LICM because opt-22 may still
perform other loop rewrites around that shape
local only: variant load-pointer rejection because opt-22 may sink/LCSSA-rewrite
the load while the local pass simply refuses to move it
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
no store/call hoisting or sinking
no general MemorySSA updater use in LICM or memory promotion
no memory promotion beyond the accepted one-load/one-store alloca-backed
self-latch fixture
no poison or freeze speculation safety checks beyond the current trapping-division guard
no multi-latch loop hoisting
no preheader creation
no LCSSA, metadata, debug-info, or analysis preservation updates
```
