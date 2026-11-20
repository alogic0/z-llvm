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
IndirectBrInst
UnreachableInst
Verifier::visitTerminator
```

Implemented subset:

```text
ret <type> <value>
br label %target
br i1 <cond>, label %then, label %else
quoted branch labels containing punctuation such as commas
quoted switch case labels containing bracket characters
implicit entry block numbering for source-backed unnamed entry blocks,
including `%0` when the first emitted instruction result has a nonnumeric name
switch <int type> <cond>, label %default [...]
indirectbr ptr <addr>, [label %target, ...]
unreachable
```

Upstream mapping:

```text
This reproduces basic LLVM terminator syntax and CFG successor behavior for returns, branches, conditional branches, integer switches, indirect branches, and unreachable blocks.
LLVM supports many more terminators and attaches richer debug, profile, and exception-handling metadata.
```

Known gaps:

```text
no invoke/callbr
no resume/catchswitch/cleanupret/catchret
limited indirectbr support: parse/verify/print and CFG successors only, no lowering or transformation
limited switch support: integer cases only, no lowering/jump-table construction, no branch-probability semantics
limited metadata/profile-weight handling
```

LLVM exception-handling IR is tracked separately in
`docs/ir/exception_handling.md`. These constructs are rejected explicitly rather
than being normalized into ordinary branches.
