# Def-Use Analysis

LLVM reference:

```text
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/Use.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/User.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/Value.h
```

LLVM IR keeps explicit use lists through `Value`, `User`, and `Use`. Many LLVM passes, including DCE-style passes, depend on cheap "is this value used?" queries.

Implemented subset:

```text
per-function named value use counts
instruction operand use collection
terminator operand use collection
decrement use counts when DCE removes an instruction
```

Current user:

```text
src/passes/dce.zig
```

Known gaps:

```text
no explicit Use objects
no user lists
no replacement callbacks
no phi-node edge-sensitive use handling
no metadata/debug uses
no cross-function or global uses
```
