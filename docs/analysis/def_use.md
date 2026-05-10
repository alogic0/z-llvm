# Def-Use Analysis

LLVM reference:

```text
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/Use.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/User.h
/home/oleg/prog/llvm-project-22/llvm/include/llvm/IR/Value.h
```

Upstream entry points to check:

```text
Value::users
Value::uses
Value::replaceAllUsesWith
User::op_begin / op_end
Use
```

LLVM IR keeps explicit use lists through `Value`, `User`, and `Use`. Many LLVM passes, including DCE-style passes, depend on cheap "is this value used?" queries.

Implemented subset:

```text
per-function named value use counts
instruction operand use collection
terminator operand use collection
decrement use counts when DCE removes an instruction
```

Upstream mapping:

```text
This reproduces only the "is this value still used?" capability through per-function use counts.
LLVM keeps explicit Use/User links and supports replacement, mutation, metadata uses, and cross-function/global uses.
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
