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
FoldTwoEntryPHINode
SpeculativelyExecuteBB
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
  Shared CFG update helper for branch retargeting, PHI repair, and unreachable
  block deletion.

Required IR invariants:
  Verified terminators, branch targets, phi incoming predecessor validity, and
  SSA dominance for the accepted IR subset.

Core LLVM algorithm data structures:
  CFG predecessor/successor graph
  CFG update helper
  Reachability set from function entry
  Phi incoming lists
  Terminator rewrite decisions

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Constant and same-target conditional branch folding
  Same-target branch PHI repair for duplicate identical incoming values
  Empty branch block threading
  Single-predecessor empty branch block threading through phi nodes when the
  replacement preserves PHI incoming value consistency
  Unreachable block removal
  Phi incoming pruning and trivial phi replacement
  Single-predecessor branch block merge
  Matching return block merge
  Common return block merge with a PHI for one existing empty `common.ret`
  block and one other same-typed return
  Hoist one identical pure scalar instruction, non-volatile load, or readnone
  call from two unique return successors into the predecessor branch block
  Hoist matching two-instruction integer binary chains from two unique return
  successors and select between the hoisted return values
  Strict empty diamond `phi`/`ret` folding to `select`/`ret`
  `!prof` branch-weight propagation from a folded diamond branch to the new
  select instruction

Intentional divergences:
  No speculation, sinking, broad common-code hoisting, switch lowering,
  invoke/EH handling, broad profile metadata rewriting, or target transform
  info.
  CorrelatedValuePropagation and TailCallElim are explicit placeholders until
  their algorithms are implemented. JumpThreading has a narrow branch-on-PHI
  predecessor-constant slice documented in `docs/passes/jump_threading.md`.

Analysis preservation/invalidation:
  SimplifyCFG mutates CFG and invalidates analyses under the local pass-manager
  policy. The pass manager verifies after execution.

Fixture coverage:
  simplifycfg
  simplifycfg_thread_empty
  simplifycfg_common_ret
  simplifycfg_common_ret_phi
  simplifycfg_hoist_same_add_ret
  simplifycfg_hoist_same_load_ret
  simplifycfg_hoist_same_readnone_call_ret
  simplifycfg_hoist_two_inst_ret
  simplifycfg_diamond_select
  simplifycfg_diamond_select_prof
  simplifycfg_same_target_phi
  simplifycfg_loop_shape_reject
  simplifycfg_side_effect_diamond_reject
  simplifycfg_unlock_instcombine
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
br i1 %cond, label %a, label %a -> br label %a, with duplicate identical PHI incoming entries repaired
remove blocks unreachable from the entry block
remove phi incoming values from unreachable predecessor blocks
replace trivial phi nodes whose remaining incoming values are all identical
merge a block ending in an unconditional branch into its single-predecessor successor when the successor has no live phi nodes
thread an empty unconditional branch block to its successor when the successor
has no live phi nodes, or when the empty block has one predecessor and phi
incoming labels can be rewritten to that predecessor without merging distinct
incoming values
merge matching return blocks into the predecessor conditional block
merge one same-typed return into an existing empty `common.ret` block by
creating a return-value PHI
hoist one identical pure scalar instruction, non-volatile load, or readnone call
from two unique conditional successors when each instruction feeds only that
successor's return
hoist matching two-instruction integer binary chains from two unique conditional
successors and select between the hoisted return values
fold an empty two-arm diamond with a single merge phi returned immediately into
a select returned from the branch block
preserve `!prof` branch-weight metadata on that new select when the source
conditional branch carried profile metadata
```

Upstream mapping:

```text
This reproduces constant branch folding, same-destination conditional branch
folding with PHI edge repair, unreachable block removal, a small phi cleanup
subset, a simple unconditional branch block merge, a PHI-safe empty-block
threading subset, a strict two-arm common-code hoist through
`hoistCommonCodeFromSuccessors`, and a strict empty-diamond select formation
subset with branch-weight metadata propagation.
LLVM's implementation covers many more CFG folds, preserves analyses, updates
broader metadata/profile data, and handles complex terminators.
The local implementation rebuilds graph facts around mutations and centralizes
branch/PHI repair in `src/analysis/cfg_update.zig`.
CFG updates account for duplicate CFG edges: when an edge rewrite reduces
incoming edge multiplicity, duplicate PHI incoming entries are pruned only when
their values are identical; when threading through a PHI target would merge
distinct incoming values for one predecessor, the local transform is rejected.
```

Fixture coverage:

```text
opt-22 equivalent:
  simplifycfg
  simplifycfg_thread_empty
  simplifycfg_common_ret
  simplifycfg_common_ret_phi
  simplifycfg_hoist_same_add_ret
  simplifycfg_hoist_same_load_ret
  simplifycfg_hoist_same_readnone_call_ret
  simplifycfg_hoist_two_inst_ret
  simplifycfg_diamond_select
  simplifycfg_diamond_select_prof
  simplifycfg_same_target_phi
  simplifycfg_loop_shape_reject
  simplifycfg_side_effect_diamond_reject
  simplifycfg_unlock_instcombine
  unreachable_simplifycfg
  mem2reg_unreachable

local-only conservative:
  none currently

unit-test only:
  phi incoming cleanup after unreachable predecessor removal
  trivial phi replacement
  same-target conditional branch folding
  PHI-safe empty block threading across switch duplicate-edge predecessors
  verifier rejection for duplicate same-predecessor PHI values that differ
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
no non-trivial phi-node rewrites; duplicate same-predecessor PHI values that
differ are rejected by the verifier, matching LLVM verifier behavior
no phi-aware branch threading when preserving distinct edge-specific incoming
values would require splitting edges or synthesizing a new control-flow shape
no general block merging
no switch support
no invoke/landingpad support
no metadata/profile preservation
no general return-block tail merging beyond the accepted matching-return and
single-common-ret PHI shapes
no general common-code hoisting beyond one identical metadata-free scalar
instruction, non-volatile load, or readnone call feeding two unique return
successors, plus matching two-instruction integer binary chains with a selected
return value
no speculative diamond folding when either arm has instructions
no select formation for merge blocks with multiple live instructions
```
