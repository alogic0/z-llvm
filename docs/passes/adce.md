# ADCE Foundation

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
start from current def-use counts
walk instructions backward
remove unused side-effect-free instructions
repeat until dependent dead instruction chains disappear
preserve stores, volatile/atomic memory barriers, unknown memory effects, and terminators
use the shared `isSafeToDelete` helper for the local removal boundary
```

This overlaps with the current DCE subset, but it is kept as a separate pass
because LLVM's ADCE becomes control-dependence aware later. The current slice is
the data-dependence foundation.

Do not treat this as a faithful LLVM ADCE implementation yet. It should keep
the foundation label until post-dominator analysis, control-dependence liveness,
and branch rewriting are implemented.

Fixture coverage:

```text
opt-22 equivalent:
  adce_chain

local-only conservative:
  none currently

unit-test only:
  none currently
```

Known gaps:

```text
no post-dominator tree
no control-dependence marking
no branch rewriting
no debug info salvage
no musttail, EH, calls, or volatile/atomic removal
```
