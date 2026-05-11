# ADCE Control-Flow Foundation

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
```

Upstream entry points to check:

```text
ADCEPass::run
AggressiveDeadCodeElimination::performDeadCodeElimination
AggressiveDeadCodeElimination::markLiveInstructions
AggressiveDeadCodeElimination::markLive
AggressiveDeadCodeElimination::removeDeadInstructions
AggressiveDeadCodeElimination::markLiveBranchesFromControlDependences
Instruction::mayReadOrWriteMemory
```

LLVM ADCE assumes instructions are dead until proven live, marks side effects,
terminators, required control dependence, and operand chains as live, then
removes everything else.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp

LLVM entry points/classes:
  ADCEPass::run
  AggressiveDeadCodeElimination::performDeadCodeElimination
  AggressiveDeadCodeElimination::markLiveBranchesFromControlDependences

Required analyses:
  PostDominatorTree for control dependence in LLVM's algorithm.
  DominatorTree is used by the broader pass-manager integration.

Required IR invariants:
  Required side effects, terminators, and control-flow dependencies must remain
  live.
  Removed instructions must have no observable effects.

Core LLVM algorithm data structures:
  Optimistic live/dead state for blocks and instructions.
  Worklist of newly live instructions.
  Control-dependence tracking through postdominators.

Local target status:
  fixture-equivalent for listed fixtures, but still not full LLVM ADCE.
```

Implemented foundation subset:

```text
build accepted-CFG postdominance and control-dependence facts
start from dead branch regions whose successors reconverge at an immediate postdominator
rewrite branch control when all outgoing regions are acyclic and side-effect free
reject phi joins and non-linear regions for now
repair PHI incoming lists through the shared CFG update helper after supported edge deletion
start from current def-use counts
walk instructions backward
remove unused side-effect-free instructions
repeat until dependent dead instruction chains disappear
preserve stores, volatile/atomic memory barriers, unknown memory effects, and terminators
use the shared `isSafeToDelete` helper for the local removal boundary
```

This now covers a small LLVM-equivalent control-flow slice: if a conditional
branch only selects dead, side-effect-free work before reconverging, the branch
condition is not live. The local pass rewrites the conditional branch to the
same live successor shape observed from `opt-22 -passes=adce`, then the
existing instruction cleanup removes the now-dead scalar chain.

Do not treat this as full LLVM ADCE yet. The local implementation is still a
conservative accepted-CFG subset and does not model LLVM's complete optimistic
worklist, block-info lattice, or full CFG update machinery.

Fixture coverage:

```text
opt-22 equivalent:
  adce_chain
  adce_dead_branch
  adce_dead_diamond
  adce_nested_dead_diamond
  adce_store_branch_reject

local-only conservative:
  none currently

unit-test only:
  none currently
```

Known gaps:

```text
no full optimistic block/instruction liveness worklist
no live-terminator propagation through arbitrary control dependence
no PHI-aware deletion beyond shared stale-incoming pruning after supported edge deletion
no loop/cyclic dead-region rewriting
no debug info salvage
no musttail, EH, calls, or volatile/atomic removal
```
