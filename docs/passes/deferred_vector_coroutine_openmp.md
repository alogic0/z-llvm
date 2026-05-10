# Deferred Vector, Coroutine, And OpenMP Surface

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/VectorCombine.cpp
llvm-project-22/llvm/lib/Transforms/Coroutines/CoroEarly.cpp
llvm-project-22/llvm/lib/Transforms/Coroutines/CoroSplit.cpp
llvm-project-22/llvm/lib/Transforms/Coroutines/CoroElide.cpp
llvm-project-22/llvm/lib/Transforms/Coroutines/CoroCleanup.cpp
llvm-project-22/llvm/lib/Transforms/IPO/OpenMPOpt.cpp
```

These domains require major IR surfaces that are intentionally absent from the
current optimizer replacement.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
  llvm-project-22/llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp
  llvm-project-22/llvm/lib/Transforms/Vectorize/VectorCombine.cpp
  llvm-project-22/llvm/lib/Transforms/Coroutines/
  llvm-project-22/llvm/lib/Transforms/IPO/OpenMPOpt.cpp

LLVM entry points/classes:
  LoopVectorizePass::run
  SLPVectorizerPass::run
  VectorCombinePass::run
  CoroEarlyPass::run
  CoroSplitPass::run
  CoroElidePass::run
  CoroCleanupPass::run
  OpenMPOptPass::run

Required analyses:
  Vector IR, target legality, and TargetTransformInfo for vectorization.
  Coroutine intrinsic representation and lowering state for coroutine passes.
  OpenMP runtime and IR representation for OpenMP optimization.

Required IR invariants:
  Vectorization requires vector types, lane semantics, cost model, and legality.
  Coroutine passes require coroutine intrinsics and frame/state-machine lowering.
  OpenMP passes require OpenMP runtime call and metadata modeling.

Core LLVM algorithm data structures:
  VPlan and vectorization legality/profitability state.
  Coroutine frame and suspend/resume lowering state.
  OpenMP runtime call graph and kernel metadata.

Local target status:
  Placeholder only.
```

Implemented subset:

```text
loop-vectorize, slp-vectorizer, vector-combine, coro-early, coro-split,
coro-elide, coro-cleanup, coro-annotation-elide, openmp-opt, and
openmp-opt-cgscc are executable placeholders.
```

Intentional divergences:

```text
no vector IR
no target vector cost model
no coroutine IR or lowering
no OpenMP representation
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  placeholder pass dispatch
```
