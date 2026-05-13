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
current optimizer replacement. Target-cost requirements for vector work are
tracked in `docs/target/target_cost_model.md`.

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
  Vectorizers are placeholders. vector-combine has one lane-identity slice.
```

Implemented subset:

```text
loop-vectorize, slp-vectorizer, coro-early, coro-split, coro-elide,
coro-cleanup, coro-annotation-elide, openmp-opt, and openmp-opt-cgscc are
executable placeholders.
vector-combine has a narrow lane-identity slice for extract-after-insert only.
accepted Zig corpus pipelines intentionally exclude loop-vectorize,
slp-vectorizer, and broader vector-combine until target costs and vector
transform legality exist.
```

Intentional divergences:

```text
fixed-vector and lane-operation parser/verifier support plus one vector-combine
lane identity only; no vectorizer optimizer input
no transform consumes the target vector cost skeleton yet
no coroutine IR or lowering
no OpenMP representation
vector transform semantics beyond the extract-after-insert identity
```

Fixture coverage:

```text
opt-22 equivalent:
  vector_lane_preserve
  vector_combine_extract_insert_same

local-only conservative:
  vector_combine_extract_insert_mismatch
  future vector fixture classified as parse/verify/future
  accepted corpus pipeline test excludes vector placeholders

unit-test only:
  placeholder pass dispatch for remaining vector/coroutine/OpenMP passes
  parser/verifier tests for lane operations, scalable vectors, and malformed
  lane-operation boundary forms
```
