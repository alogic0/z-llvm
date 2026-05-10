# dce

LLVM references:

```text
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/DCE.cpp
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
```

This pass removes instructions whose results are unused and whose execution has no side effects.

Implemented subset:

```text
mark values used by live instructions and terminators
remove unused pure add/sub/mul instructions
iterate until no newly unused instructions remain
```

Example:

```text
before:
  %x = add i32 %a, 0
  %dead = mul i32 %x, 4
  ret i32 %x

after dce:
  %x = add i32 %a, 0
  ret i32 %x
```

Known gaps:

```text
no control-flow-sensitive liveness
no side-effecting instructions yet beyond the implicit terminator rule
no memory operations
no calls
no debug-info salvage
no aggressive DCE for unreachable control-flow
```
