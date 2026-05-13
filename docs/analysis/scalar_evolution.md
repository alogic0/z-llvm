# ScalarEvolution

LLVM references:

```text
llvm-project-22/llvm/lib/Analysis/ScalarEvolution.cpp
llvm-project-22/llvm/include/llvm/Analysis/ScalarEvolution.h
```

Upstream entry points to check:

```text
ScalarEvolution::getSCEV
ScalarEvolution::createSimpleAffineAddRec
ScalarEvolution::createAddRecFromPHI
ScalarEvolution::getAddRecExpr
SCEVAddRecExpr::getStepRecurrence
```

LLVM ScalarEvolution models scalar expressions and loop recurrences. Loop
optimizers such as IndVarSimplify use `SCEVAddRecExpr` values like `{Start,+,Step}`
to prove induction-variable relationships and rewrite exit values.

Implemented subset:

```text
recognize affine integer AddRec records from LoopInfo simple induction PHIs
preserve the phi result, initial value, step value, next value, and integer type
recognize constant start/step pairs used by the local indvars slice
feed the local IndVarSimplify pass without exposing a general SCEV expression graph
```

Fixture coverage:

```text
opt-22 equivalent:
  indvars_derived_exit

unit-test coverage:
  LoopInfo reduced Zig corpus loop shape recognizes the underlying IV records
```

Known gaps:

```text
no general SCEV expression uniquing or folding
no trip-count computation
no no-wrap proof
no predicate/runtime-check support
no widening or type-extension modeling
no recurrence evaluation beyond the accepted indvars fixture shape
```
