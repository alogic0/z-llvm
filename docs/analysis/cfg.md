# CFG Analysis

LLVM references:

```text
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/CFG.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/Support/CFGUpdate.h
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
```

Upstream mapping:

```text
This reproduces explicit successor/predecessor collection for the current terminator subset.
LLVM computes these views directly from full IR terminators and also supports incremental CFG updates.
```

Current user:

```text
src/passes/simplifycfg.zig
```

Known gaps:

```text
no incremental CFG updates
no critical-edge splitting
no exceptional control flow
no switch terminators
no unreachable terminators
no edge-specific phi helper APIs
```
