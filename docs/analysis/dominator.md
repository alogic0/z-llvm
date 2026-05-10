# Dominator Analysis

LLVM references:

```text
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/Dominators.h
/home/oleg/prog/llvm-project-22/llvm/lib/IR/Dominators.cpp
```

A block `A` dominates block `B` if every path from the function entry to `B` passes through `A`. LLVM uses dominator trees throughout scalar optimization, CFG simplification, CSE, loop analysis, and LICM.

Implemented subset:

```text
per-function iterative dominator computation
reachable-block filtering
dominates(A, B) query by block index
```

Known gaps:

```text
no immediate dominator tree
no dominance frontier
no incremental updates
no post-dominators
no edge dominance
no unreachable-block tree policy beyond filtering
```
