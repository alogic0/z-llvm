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
SwitchInst
UnreachableInst
Verifier::visitTerminator
```

Implemented subset:

```text
ret <type> <value>
br label %target
br i1 <cond>, label %then, label %else
switch <int type> <cond>, label %default [...]
unreachable
```

Upstream mapping:

```text
This reproduces basic LLVM terminator syntax and CFG successor behavior for returns, branches, conditional branches, integer switches, and unreachable blocks.
LLVM supports many more terminators and attaches richer debug, profile, and exception-handling metadata.
```

Known gaps:

```text
no invoke/callbr/indirectbr
no resume/catchswitch/cleanupret/catchret
limited switch support: integer cases only, no lowering/jump-table construction, no branch-probability semantics
limited metadata/profile-weight handling
```

LLVM exception-handling IR is tracked separately in
`docs/ir_exception_handling.md`. These constructs are rejected explicitly rather
than being normalized into ordinary branches.
