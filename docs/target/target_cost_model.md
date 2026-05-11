# Target Cost Model Boundary

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/TargetTransformInfo.h
llvm-project-22/llvm/lib/Analysis/TargetTransformInfo.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp
llvm-project-22/llvm/lib/Transforms/Vectorize/VectorCombine.cpp
```

LLVM vector transforms depend on target legality and profitability facts, not
only on vector IR syntax. The local replacement has no TargetTransformInfo-like
model yet.

Implemented subset:

```text
scalar accepted corpus pipelines exclude vectorizer placeholders
vector IR forms are rejected deliberately by parser tests
future vector fixture records the syntax boundary
loop-vectorize, slp-vectorizer, and vector-combine remain executable no-op
placeholders only in full inventory pipeline descriptors
```

Required before enabling vector transforms:

```text
vector Type representation and verifier rules
vector constants and lane operations
target vector register and legal type facts
operation cost queries for scalar and vector arithmetic
memory access cost and alignment facts
LoopAccessAnalysis and ScalarEvolution-like loop legality
codegen/backend validation for generated vector IR
```

Unsupported behavior:

```text
no vector type parsing in accepted IR
no shufflevector, insertelement, or extractelement
no vector constants
no loop or SLP vectorization
no target feature or CPU model cost variation
```
