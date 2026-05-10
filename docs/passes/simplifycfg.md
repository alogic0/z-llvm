# simplifycfg

LLVM reference:

```text
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Utils/SimplifyCFG.cpp
```

Upstream entry points to check:

```text
SimplifyCFGPass::run
simplifyFunctionCFG
simplifyCFG
removeUnreachableBlocks
FoldBranchToCommonDest
```

This pass simplifies control-flow graph structure.

Implemented subset:

```text
br i1 1, label %a, label %b -> br label %a
br i1 0, label %a, label %b -> br label %b
br i1 %cond, label %a, label %a -> br label %a
remove blocks unreachable from the entry block
remove phi incoming values from unreachable predecessor blocks
replace trivial phi nodes whose remaining incoming values are all identical
```

Upstream mapping:

```text
This reproduces constant branch folding, same-destination conditional branch folding, unreachable block removal, and a small phi cleanup subset.
LLVM's implementation covers many more CFG folds, preserves analyses, updates metadata/profile data, and handles complex terminators.
```

Example:

```text
before:
entry:
  br i1 1, label %then, label %else
then:
  ret i32 %a
else:
  ret i32 0

after:
entry:
  br label %then
then:
  ret i32 %a
```

Known gaps:

```text
no non-trivial phi-node rewrites
no branch threading
no block merging
no switch support
no invoke/landingpad support
no unreachable terminator support
no metadata/profile preservation
```
