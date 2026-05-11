# CFG Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/CFG.h
llvm-project-22/llvm/include/llvm/Support/CFGUpdate.h
```

Upstream entry points to check:

```text
successors
predecessors
succ_begin / succ_end
pred_begin / pred_end
ApplyUpdates
```

LLVM exposes helpers for walking successors and predecessors of basic blocks. Many scalar passes use this as basic infrastructure.

Implemented subset:

```text
per-function successor lists
per-function predecessor lists
entry-block reachability
duplicate edge suppression
shared CFG update helpers for retargeting branches
shared PHI incoming block replacement
shared PHI pruning after edge deletion or unreachable block deletion
shared unreachable-block deletion helper
strict empty-diamond shape checks for SimplifyCFG select formation
```

Upstream mapping:

```text
This reproduces explicit successor/predecessor collection for the current
terminator subset and a small shared CFG mutation layer shaped after LLVM's
CFG update utilities.
LLVM computes these views directly from full IR terminators and supports richer
incremental updates than the local rebuild-and-repair approach.
```

Current user:

```text
src/passes/simplifycfg.zig
src/passes/adce.zig
src/analysis/postdominator.zig
```

Known gaps:

```text
no full incremental CFG updates or analysis preservation
no critical-edge splitting
no exceptional control flow
no switch terminators
no edge-specific PHI translation
no speculative CFG rewrites; side-effecting blocks must remain explicit
```
