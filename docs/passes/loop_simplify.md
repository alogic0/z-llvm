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
  LoopRotatePass::run
  LoopDeletionPass::run
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
  LoopInfo foundation plus explicit placeholders.
```

Implemented subset:

```text
LoopInfo exposes headers, latches, preheaders, exiting blocks, exit blocks,
dedicated-exit checks, containment, backedges, parent indexes, loop depth, and
loop-invariant value classification.
loop-simplifycfg, loop-rotate, and loop-deletion are executable placeholders.
Cycle 17 added LoopInfo-side recognition for simple induction variables and
side-effect-free loop-deletion candidates, but it still does not rotate loops,
insert LCSSA PHIs, or delete loop blocks.
Cycle 17 also added a simple scalar LCSSA formation helper for one-exit accepted
loops. This is a targeted utility, not full LLVM `formLCSSA`.
LCSSA form can be checked for existing exit phis but is not formed yet.
```

Intentional divergences:

```text
no preheader creation
no latch canonicalization
no dedicated-exit splitting
no LCSSA formation
no loop rotation
no side-effect-free loop deletion
```

Fixture coverage:

```text
opt-22 equivalent:
  LICM fixtures exercise the current accepted canonical loop shape.

local-only conservative:
  LICM negative fixtures document no-preheader and multi-latch rejection.

unit-test only:
  LoopInfo natural-loop queries and release-o3 loop placeholder dispatch
```
