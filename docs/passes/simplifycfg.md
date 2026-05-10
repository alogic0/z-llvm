# simplifycfg

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp
llvm-project-22/llvm/lib/Transforms/Utils/SimplifyCFG.cpp
```

Upstream entry points to check:

```text
SimplifyCFGPass::run
simplifyFunctionCFG
simplifyCFG
removeUnreachableBlocks
FoldBranchToCommonDest
TryToSimplifyUncondBranchFromEmptyBlock
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
merge a block ending in an unconditional branch into its single-predecessor successor when the successor has no live phi nodes
thread an empty unconditional branch block to its successor when the successor has no live phi nodes
```

Upstream mapping:

```text
This reproduces constant branch folding, same-destination conditional branch folding, unreachable block removal, a small phi cleanup subset, a simple unconditional branch block merge, and a phi-free empty-block threading subset.
LLVM's implementation covers many more CFG folds, preserves analyses, updates metadata/profile data, and handles complex terminators.
```

Fixture coverage:

```text
opt-22 equivalent:
  simplifycfg
  simplifycfg_thread_empty
  unreachable_simplifycfg
  mem2reg_unreachable

local-only conservative:
  none currently

unit-test only:
  phi incoming cleanup after unreachable predecessor removal
  trivial phi replacement
  same-target conditional branch folding
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
  ret i32 %a
```

Known gaps:

```text
no non-trivial phi-node rewrites
no phi-aware branch threading
no general block merging
no switch support
no invoke/landingpad support
no unreachable terminator support
no metadata/profile preservation
```
