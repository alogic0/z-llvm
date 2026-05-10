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

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/SimplifyCFG.cpp

LLVM entry points/classes:
  SimplifyCFGPass::run
  simplifyFunctionCFG
  simplifyCFG
  FoldBranchToCommonDest
  TryToSimplifyUncondBranchFromEmptyBlock
  removeUnreachableBlocks

Required analyses:
  Local CFG predecessor and reachability graph rebuilt inside the pass.

Required IR invariants:
  Verified terminators, branch targets, phi incoming predecessor validity, and
  SSA dominance for the accepted IR subset.

Core LLVM algorithm data structures:
  CFG predecessor/successor graph
  Reachability set from function entry
  Phi incoming lists
  Terminator rewrite decisions

Local target status:
  LLVM-shaped algorithm subset

Implemented subset:
  Constant and same-target conditional branch folding
  Empty branch block threading
  Unreachable block removal
  Phi incoming pruning and trivial phi replacement
  Single-predecessor branch block merge
  Matching return block merge

Intentional divergences:
  No speculation, sinking, hoisting, switch lowering, invoke/EH handling,
  profile metadata, or target transform info.
  JumpThreading, CorrelatedValuePropagation, and TailCallElim are explicit
  placeholders until their algorithms are implemented.

Analysis preservation/invalidation:
  SimplifyCFG mutates CFG and invalidates analyses under the local pass-manager
  policy. The pass manager verifies after execution.

Fixture coverage:
  simplifycfg
  simplifycfg_thread_empty
  simplifycfg_common_ret
  unreachable_simplifycfg
  mem2reg_unreachable

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
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
merge matching return blocks into the predecessor conditional block
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
no metadata/profile preservation
```
