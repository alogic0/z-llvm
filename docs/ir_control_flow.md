# Control Flow IR

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
llvm-project-22/llvm/lib/IR/Verifier.cpp
```

Upstream entry points to check:

```text
ReturnInst
BranchInst
UnreachableInst
Verifier::visitTerminator
```

Implemented subset:

```text
ret <type> <value>
br label %target
br i1 <cond>, label %then, label %else
unreachable
```

Upstream mapping:

```text
This reproduces basic LLVM terminator syntax and CFG successor behavior for returns, branches, conditional branches, and unreachable blocks.
LLVM supports many more terminators and attaches richer debug, profile, and exception-handling metadata.
```

Known gaps:

```text
no switch
no invoke/callbr/indirectbr
no resume/catchswitch/cleanupret/catchret
no metadata or profile weights
```
