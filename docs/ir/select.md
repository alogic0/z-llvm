# Select IR

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
llvm-project-22/llvm/lib/IR/Verifier.cpp
```

Upstream entry points to check:

```text
SelectInst
SelectInst::Create
Verifier::visitSelectInst
```

Implemented subset:

```text
%v = select i1 %cond, iN %if_true, iN %if_false
%v = select i1 %cond, ptr %if_true, ptr %if_false
```

Upstream mapping:

```text
This reproduces scalar select syntax and verifier checks for an i1 condition and matching result arms.
LLVM also supports vector conditions, fast-math flags, poison-specific semantics, and metadata.
```

Known gaps:

```text
no vector select
no fast-math flags
no poison-aware folds
no metadata
```
