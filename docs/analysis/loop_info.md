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
```

LLVM LoopInfo identifies natural loops from a dominator tree and records loop
nests, headers, latches, blocks, exits, and relationships used by loop passes.

Implemented subset:

```text
build CFG and dominator analysis for one function
recognize a backedge when successor dominates predecessor
construct the natural loop for each backedge by walking predecessors from latch
record loop header, latch, and member block indexes
lookup a loop by header block index
```

Known gaps:

```text
no nested loop forest
no block-to-innermost-loop map
no preheader, exit, exiting, or dedicated-exit queries
no loop verification
no LoopSimplify or LCSSA integration
no irreducible control-flow handling beyond natural-loop backedges
```
