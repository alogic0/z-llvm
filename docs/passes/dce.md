# dce

LLVM references:

```text
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/DCE.cpp
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
```

Upstream entry points to check:

```text
DCEPass::run
eliminateDeadCode
isInstructionTriviallyDead
ADCEPass::run
```

This pass removes instructions whose results are unused and whose execution has no side effects.

Implemented subset:

```text
mark values used by live instructions and terminators
remove unused pure add/sub/mul instructions
iterate until no newly unused instructions remain
```

Upstream mapping:

```text
This reproduces local trivially-dead pure-instruction removal.
LLVM's DCE uses richer side-effect and liveness checks through instruction semantics, memory effects, debug-info salvage, and ADCE for control-flow-sensitive removal.
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
