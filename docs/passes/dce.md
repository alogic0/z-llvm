# dce

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/DCE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
llvm-project-22/llvm/lib/Analysis/ValueTracking.cpp
```

Upstream entry points to check:

```text
DCEPass::run
eliminateDeadCode
isInstructionTriviallyDead
wouldInstructionBeTriviallyDead
ADCEPass::run
```

This pass removes instructions whose results are unused and whose execution has no side effects.

Implemented subset:

```text
mark values used by live instructions and terminators
remove unused pure add/sub/mul, icmp, phi, alloca, and load instructions
keep store instructions because they write memory
iterate until no newly unused instructions remain
```

Upstream mapping:

```text
This reproduces local trivially-dead pure-instruction removal and the first memory side-effect rule: unused loads can be removed, stores cannot.
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
no MemorySSA or alias-aware memory liveness
no volatile or atomic memory operations
no calls
no debug-info salvage
no aggressive DCE for unreachable control-flow
```
