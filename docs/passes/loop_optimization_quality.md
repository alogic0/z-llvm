# Loop Optimization Quality Placeholders

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/IndVarSimplify.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopSink.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopDistribute.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LoopLoadElimination.cpp
```

These passes improve loop quality after loops have canonical shape and the
compiler has enough target, memory, and scalar-evolution facts to prove each
rewrite legal.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/IndVarSimplify.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopSink.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp

LLVM entry points/classes:
  IndVarSimplifyPass::run
  SimpleLoopUnswitchPass::run
  LoopIdiomRecognizePass::run
  LoopSinkPass::run
  LoopUnrollPass::run

Required analyses:
  LoopInfo and DominatorTree.
  ScalarEvolution for induction variables, trip counts, and unroll legality.
  AliasAnalysis and MemorySSA for memory idioms and load elimination.
  TargetTransformInfo for profitability and code-size decisions.

Required IR invariants:
  Loops must preserve SSA dominance and phi predecessor correctness.
  Memory-affecting transformations require conservative alias/mod-ref proof.
  Unrolling and unswitching must respect mode-specific code-size gates.

Core LLVM algorithm data structures:
  Loop forest and canonical loop form.
  ScalarEvolution recurrence and trip-count expressions.
  Target cost model queries.
  MemorySSA or alias result sets for memory loop transforms.

Local target status:
  LICM foundation plus explicit placeholders for the remaining passes.
```

Implemented subset:

```text
LICM remains the implemented loop optimization subset.
indvars, simple-loop-unswitch, loop-idiom, loop-sink, loop-unroll,
loop-unroll-full, loop-distribute, loop-load-elim, and
extra-simple-loop-unswitch-passes are executable placeholders.
```

Intentional divergences:

```text
no ScalarEvolution yet
no target transform information or code-size profitability model
no loop memory optimization beyond the current conservative LICM scalar subset
no unrolling, unswitching, idiom recognition, sinking, or induction variable rewrite
```

Fixture coverage:

```text
opt-22 equivalent:
  LICM fixtures cover the implemented loop optimization subset.

local-only conservative:
  LICM memory and canonical-shape rejection fixtures.

unit-test only:
  placeholder pass dispatch through named pass parsing.
```
