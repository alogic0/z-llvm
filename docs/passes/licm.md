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
```

LLVM LICM hoists loop-invariant computations to a loop preheader and sinks
computations out of loops when legal. Full LLVM LICM relies on LoopInfo,
DominatorTree, AliasAnalysis, MemorySSA, safety checks for trapping behavior,
and metadata updates.

Implemented subset:

```text
use LoopInfo natural loops
require an existing unique unconditional preheader
hoist pure binary, icmp, and select instructions
require every operand to be constant, undef, a function parameter, or defined outside the loop
move hoisted instructions to the preheader instruction list
```

Known gaps:

```text
no load/store/call hoisting or sinking
no MemorySSA or alias analysis integration
no trapping, poison, or speculation safety checks
no loop nest ordering beyond current natural-loop list
no preheader creation
no LCSSA, metadata, debug-info, or analysis preservation updates
```
