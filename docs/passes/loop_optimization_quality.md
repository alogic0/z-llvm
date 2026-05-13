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
  IndVarSimplify::rewriteLoopExitValues
  IndVarSimplify::simplifyAndExtend
  SCEVAddRecExpr
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
  LICM foundation plus an LLVM-shaped IndVarSimplify exit-value rewrite slice.
  The remaining loop quality passes are explicit placeholders.
```

Implemented subset:

```text
LICM remains the broadest implemented loop optimization subset.
indvars rewrites one accepted self-latch affine-IV exit-value shape by using a
small ScalarEvolution-like AddRec record: canonical `{0,+,1}` IV, derived
`{3,+,2}` IV, equality exit on the canonical post-inc value, and an exit `ret`
of the derived post-inc value. The pass replaces the exit use with the same
closed form produced by opt-22 for the fixture.
simple-loop-unswitch, loop-idiom, loop-sink, loop-unroll, loop-unroll-full,
loop-distribute, loop-load-elim, and extra-simple-loop-unswitch-passes are
executable placeholders.
```

Intentional divergences:

```text
only a narrow AddRec recognition helper, not full ScalarEvolution
no target transform information or code-size profitability model
no loop memory optimization beyond the current conservative LICM scalar subset
no IV widening, exit-count generality, non-self-latch rewrite, unrolling,
unswitching, idiom recognition, or sinking
```

Fixture coverage:

```text
opt-22 equivalent:
  LICM fixtures cover the implemented loop optimization subset.
  indvars_derived_exit

local-only conservative:
  LICM memory and canonical-shape rejection fixtures.

unit-test only:
  placeholder pass dispatch through named pass parsing for the remaining loop
  quality passes.
```
