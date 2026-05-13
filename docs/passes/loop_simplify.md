# Loop Simplify, LoopSimplifyCFG, LoopRotate, And LoopDeletion

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Utils/LoopSimplify.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopRotation.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopDeletion.cpp
llvm-project-22/llvm/lib/Transforms/Utils/LCSSA.cpp
```

These passes prepare loops for later optimization by moving them toward
canonical shape, then performing loop-local CFG cleanup, rotation, or deletion
when legality is proven.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Utils/LoopSimplify.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopRotation.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopDeletion.cpp

LLVM entry points/classes:
  LoopSimplifyPass::run
  simplifyLoop
  LoopSimplifyCFGPass::run
  simplifyLoopCFG
  constantFoldTerminators
  ConstantTerminatorFoldingImpl::run
  ConstantTerminatorFoldingImpl::foldTerminators
  LoopRotatePass::run
  LoopRotate.cpp
  LoopRotationUtils
  LoopDeletionPass::run
  deleteDeadLoop
  isLoopDead
  formLCSSA

Required analyses:
  LoopInfo.
  DominatorTree.
  ScalarEvolution for deletion and some rotation profitability checks.
  MemorySSA or side-effect facts for deletion legality.

Required IR invariants:
  CFG rewrites must preserve SSA dominance, phi predecessor lists, and loop
  membership.
  Loop deletion requires proving the loop has no observable side effects.
  LCSSA requires every loop-defined value used outside the loop to flow
  through exit phis.

Core LLVM algorithm data structures:
  Loop forest and loop block sets.
  Dedicated exit and preheader queries.
  Dominator updates after CFG mutation.
  Side-effect and trip-count facts for deletion.

Local target status:
  LoopInfo foundation plus LLVM-shaped LoopSimplifyCFG, LoopRotate, and
  LoopDeletion subsets.
```

Implemented subset:

```text
LoopInfo exposes headers, latches, preheaders, exiting blocks, exit blocks,
dedicated-exit checks, containment, backedges, parent indexes, loop depth, and
loop-invariant value classification.
loop-simplifycfg folds a constant conditional branch in a non-header,
non-latch loop block when the loop has a preheader, dedicated exits, and
existing LCSSA form. It removes newly unreachable blocks and then applies the
same LLVM-shaped block-into-predecessor cleanup used by
`simplifyLoopCFG`/`mergeBlocksIntoPredecessors` for the accepted loop-local
surface.
loop-rotate rotates the accepted single-latch counted while-loop shape into the
LLVM-compatible guarded do-while form: a preheader guard, a `.lr.ph` block, a
rotated body PHI, a latch condition on the incremented induction value, a split
exit critical edge, and repaired LCSSA exit PHIs.
loop-deletion deletes the accepted `mustprogress` side-effect-free counted loop
when no loop-defined value is used outside the loop. It retargets the preheader
to the dedicated exit and removes the now-unreachable loop blocks.
Cycle 17 added LoopInfo-side recognition for simple induction variables and
side-effect-free loop-deletion candidates, but it still does not rotate loops,
insert LCSSA PHIs, or delete loop blocks.
Cycle 17 also added a simple scalar LCSSA formation helper for one-exit accepted
loops with dedicated exits. This is a targeted utility, not full LLVM
`formLCSSA`.
LCSSA form can also be checked for existing exit phis outside the helper's
narrow formation shape.
```

Intentional divergences:

```text
no preheader creation
no latch canonicalization
no dedicated-exit splitting
no LCSSA formation for non-dedicated exits or multi-exit loops
no LoopSimplifyCFG support for current-loop deletion, dead exit deletion,
switch folding, indirect entries, irreducible CFG, nested-loop LoopInfo
updates, MemorySSA updates, or ScalarEvolution invalidation
no loop rotation beyond the accepted single-latch counted while-loop shape
no loop deletion when loop-defined values are live outside the loop, when the
loop may access memory, or when the loop has calls, multiple exits,
non-dedicated exits, unknown progress, or general ScalarEvolution requirements
```

Fixture coverage:

```text
opt-22 equivalent:
  LICM fixtures exercise the current accepted canonical loop shape.
  loop_simplifycfg_const_body_branch
  loop_rotate_counted
  loop_deletion_dead_counted

local-only conservative:
  LICM negative fixtures document no-preheader and multi-latch rejection.

unit-test only:
  LoopInfo natural-loop queries, simple LCSSA formation, non-dedicated-exit
  LCSSA rejection, and release-o3 loop dispatch
```
