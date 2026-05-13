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
only on vector IR syntax. The local replacement now has an analysis-only
TargetTransformInfo skeleton, but it is not yet used to enable vectorizer-quality
transforms.

Implemented subset:

```text
scalar accepted corpus pipelines exclude vectorizer placeholders
fixed-vector IR forms parse and verify
fixed-vector lane operations may participate in target-independent DCE
same-constant-lane extract-after-insert folds are target-independent
scalar-condition vector selects with identical arms fold target-independently
`src/analysis/target_transform_info.zig` exposes generic, x86_64, and AArch64
cost query objects for scalar/vector arithmetic, shuffle-like operations, and
scalarization overhead
unsupported scalable vectors and malformed lane operations are rejected by parser tests
future vector fixture records the parser/verifier boundary
loop-vectorize remains an executable no-op placeholder in full inventory
pipeline descriptors
slp-vectorizer recognizes one same-op scalar bundle shape, then records that
BoUpSLP tree construction and TTI profitability are unsupported
```

Cycle 04 finish decision: `vector_future_release_fast` remains
`parse,verify,future`. It is not optimizer-input because the fixture contains
vector arithmetic that would need target-cost and native vector-lowering
evidence before it can drive optimization expectations.

Required before enabling vector transforms:

```text
complete target vector register and legal type facts
broader operation cost queries for scalar and vector arithmetic
memory access cost and alignment facts
LoopAccessAnalysis and ScalarEvolution-like loop legality
codegen/backend validation for generated vector IR
```

Unsupported behavior:

```text
no optimizer-input vector corpus rows beyond reduced lane-operation fixtures
no lane-operation profitability model
no vector optimization or scalar fold reuse beyond target-independent
same-value identities
no loop vectorization or SLP vector IR rewriting
no target feature or CPU model cost variation
no transform consumes the TargetTransformInfo skeleton for profitability yet
```

Target feature extraction is documented in `docs/target/features.md`. Those
facts are preserved for future TargetTransformInfo expansion, not consumed by
the current optimizer. The current lane folds are allowed only because they are
target-independent semantic identities, not profitability decisions.

Fixture coverage:

```text
unit tests:
  TargetTransformInfo skeleton exposes x86_64, AArch64, and generic vector
  arithmetic/shuffle/scalarization costs
```

The transform classification policy is tracked in
`docs/target/transform_cost_policy.md`.
