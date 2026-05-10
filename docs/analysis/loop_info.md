# LoopInfo

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/LoopInfo.h
llvm-project-22/llvm/lib/Analysis/LoopInfo.cpp
llvm-project-22/llvm/include/llvm/Support/GenericLoopInfo.h
llvm-project-22/llvm/include/llvm/Support/GenericLoopInfoImpl.h
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
```

Implemented subset:

```text
build CFG and dominator analysis for one function
recognize a backedge when successor dominates predecessor
construct the natural loop for each backedge by walking predecessors from latch
query loop header, latch, and member block indexes
lookup a loop by header block index
test whether a block index is inside a loop
query a unique unconditional preheader
collect unique exiting block indexes
collect unique exit block indexes
query whether exit blocks are dedicated
record parent loop index and nesting depth for natural loops
lookup the innermost known loop for a block index
```

Known gaps:

```text
no full LLVM loop forest mutation API
no loop verification
no LoopSimplify or LCSSA integration
no irreducible control-flow handling beyond natural-loop backedges
```
