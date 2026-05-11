# Dominator Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Dominators.h
llvm-project-22/llvm/lib/IR/Dominators.cpp
llvm-project-22/llvm/include/llvm/Analysis/IteratedDominanceFrontier.h
llvm-project-22/llvm/lib/Analysis/IteratedDominanceFrontier.cpp
```

Upstream entry points to check:

```text
DominatorTree
DominatorTreeBase
DomTreeBuilder
dominates
getNode / getIDom
IDFCalculator
```

A block `A` dominates block `B` if every path from the function entry to `B` passes through `A`. LLVM uses dominator trees throughout scalar optimization, CFG simplification, CSE, loop analysis, and LICM.

Implemented subset:

```text
per-function iterative dominator computation
reachable-block filtering
dominates(A, B) query by block index
immediate dominator query by block index
dominance-frontier sets for CFG joins
```

Upstream mapping:

```text
This reproduces the semantic dominates(A, B), immediate-dominator, and dominance-frontier queries with simple iterative algorithms.
LLVM uses an efficient dominator tree implementation, incremental updates, and iterated dominance-frontier calculation for large functions.
```

Known gaps:

```text
no explicit dominator tree nodes
no iterated dominance-frontier calculator
no incremental updates
no edge dominance
no unreachable-block tree policy beyond filtering
```

Post-dominator and control-dependence queries live separately in
`docs/analysis/postdominator.md` and `src/analysis/postdominator.zig`.
