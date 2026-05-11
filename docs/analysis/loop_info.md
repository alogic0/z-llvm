# LoopInfo

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/LoopInfo.h
llvm-project-22/llvm/lib/Analysis/LoopInfo.cpp
llvm-project-22/llvm/include/llvm/Support/GenericLoopInfo.h
llvm-project-22/llvm/include/llvm/Support/GenericLoopInfoImpl.h
llvm-project-22/llvm/lib/Transforms/Utils/LCSSA.cpp
```

Upstream entry points to check:

```text
LoopInfo
LoopInfoBase
LoopAnalysis::run
LoopInfo::analyze
LoopInfoWrapperPass
Loop
Loop::getHeader
Loop::getLoopLatch
Loop::getLoopLatches
Loop::contains
Loop::getLoopPreheader
Loop::getExitingBlocks
Loop::getExitBlocks
Loop::hasDedicatedExits
Loop::getLoopDepth
Loop::isLoopInvariant
formLCSSA
```

LLVM LoopInfo identifies natural loops from a dominator tree and records loop
nests, headers, latches, blocks, exits, and relationships used by loop passes.

Loop terminology used here follows LLVM's `Loop` query API:

```text
header: the single loop entry block
latch: a loop block with a backedge to the header
preheader: a non-loop predecessor that branches unconditionally to the header
exiting block: a block inside the loop with at least one successor outside the loop
exit block: a block outside the loop with at least one predecessor inside the loop
dedicated exit: an exit block whose predecessors are all inside the loop
LCSSA: loop-defined values used outside the loop are passed through exit phis
```

Implemented subset:

```text
build CFG and dominator analysis for one function
recognize a backedge when successor dominates predecessor
construct the natural loop for each backedge by walking predecessors from latch
query loop header, latch, and member block indexes
query a single-latch list for current NaturalLoop records
query backedges as latch/header pairs
lookup a loop by header block index
test whether a block index is inside a loop
query a unique unconditional preheader
collect unique exiting block indexes
collect unique exit block indexes
query whether exit blocks are dedicated
check whether outside loop uses satisfy LCSSA form
record parent loop index and nesting depth for natural loops
query loop depth for a block
lookup the innermost known loop for a block index
classify a value as loop invariant from definition-block ownership
recognize simple integer induction PHIs with an add step in source-backed loop
fixtures
insert simple scalar LCSSA PHIs for a single-exit accepted loop shape
classify LoopRotate support status with explicit unsupported reasons
classify side-effect-free loop-deletion candidates without deleting them
classify LoopDeletion support status while requiring a proven exit and no side effects
```

Canonical-form boundary:

```text
accepted for LICM: single current NaturalLoop record for a header, existing
unconditional preheader, and a preheader that dominates the header
queried but not created: dedicated exits
checked but not formed: LCSSA
not canonicalized yet: multi-latch loops, irreducible loops, split exits,
inserted preheaders, rotated loops
recognized but not transformed yet: simple induction variables and
side-effect-free deletion candidates
implemented helper only: simple scalar LCSSA insertion for one exit block
```

Fixture coverage:

```text
unit-test only:
  natural-loop discovery from dominator backedges
  header/latch/latches/preheader/exiting/exit/dedicated-exit queries
  backedge, loop-depth, contains-block, and loop-invariant value helpers
  LCSSA-form check for loop-defined values used outside the loop
  simple scalar LCSSA formation and verifier-clean rewrite
  simple induction variable recognition for the reduced Zig corpus loop shape
  side-effecting loop deletion candidate rejection
  LoopRotate self-latch rejection and LoopDeletion eligible-but-not-implemented status

opt-22 compared indirectly:
  LICM fixtures exercise the currently accepted loop shapes, including a nested
  memory-free scalar chain
```

Known gaps:

```text
no full LLVM loop forest mutation API
no loop verification
no LoopSimplify mutation beyond the simple LCSSA helper
no LoopRotate, IndVarSimplify rewrite, or LoopDeletion mutation
no irreducible control-flow handling beyond natural-loop backedges
```
