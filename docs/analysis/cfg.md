# CFG Analysis

LLVM references:

```text
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/CFG.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/Support/CFGUpdate.h
```

LLVM exposes helpers for walking successors and predecessors of basic blocks. Many scalar passes use this as basic infrastructure.

Implemented subset:

```text
per-function successor lists
per-function predecessor lists
entry-block reachability
duplicate edge suppression
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
