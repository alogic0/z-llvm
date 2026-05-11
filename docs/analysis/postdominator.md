# Post-Dominator And Control-Dependence Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/PostDominators.h
llvm-project-22/llvm/lib/Analysis/PostDominators.cpp
llvm-project-22/llvm/include/llvm/Support/GenericDomTree.h
llvm-project-22/llvm/include/llvm/Support/GenericDomTreeConstruction.h
llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
```

Upstream entry points to check:

```text
PostDominatorTree
PostDominatorTree::dominates
PostDominatorTree::getNode / getIDom
ADCE control-dependence marking
```

A block `A` postdominates block `B` if every path from `B` to a function exit
passes through `A`. LLVM ADCE uses post-dominance and control dependence to
avoid keeping branch terminators unless they control live work.

Implemented subset:

```text
per-function iterative postdominator computation
reachable-block filtering
postdominates(A, B) query by block index
immediate postdominator query by block index
simple control-dependence query for multi-successor branch controllers
```

Upstream mapping:

```text
This reproduces the semantic postdominates(A, B) and immediate-postdominator
queries for the accepted CFG surface with a simple fixed-point algorithm.
The control-dependence helper follows the ADCE need: a block is considered
dependent on a controller when it postdominates one successor, does not
postdominate the controller, and the controller has multiple successors.
LLVM uses a full postdominator tree, virtual-root handling, and update-aware CFG
utilities for larger and more complex control flow.
```

Fixture coverage:

```text
src/tests.zig:
  postdominator analysis answers postdominance queries
  control dependence reports branch-controlled blocks
```

Known gaps:

```text
no explicit postdominator tree nodes
no virtual-root model exposed to callers
no incremental updates
no exceptional control flow
no switch terminators
no edge-specific control dependence
no integration with full ADCE liveness yet
```
