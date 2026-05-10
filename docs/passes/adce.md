# ADCE

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
```

LLVM ADCE assumes instructions are dead until proven live, marks side effects,
terminators, required control dependence, and operand chains as live, then
removes everything else.

Implemented subset:

```text
start from current def-use counts
walk instructions backward
remove unused side-effect-free instructions
repeat until dependent dead instruction chains disappear
preserve stores and terminators
```

This overlaps with the current DCE subset, but it is kept as a separate pass
because LLVM's ADCE becomes control-dependence aware later. The current slice is
the data-dependence foundation.

Known gaps:

```text
no post-dominator tree
no control-dependence marking
no branch rewriting
no debug info salvage
no musttail, EH, calls, or volatile/atomic handling
```
