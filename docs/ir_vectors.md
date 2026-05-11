# Vector IR Boundary

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Type.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Verifier.cpp
```

Implemented subset:

```text
<N x iM>
<N x float>
<N x double>
<N x ptr>
vector function parameters and returns
undef, zeroinitializer, named vector values, and typed vector constants
integer and FP binary instructions with matching fixed-vector operand types
extractelement with scalar integer lane indices
insertelement with matching vector element value type
shufflevector with matching input vector types and integer vector masks
```

This is mostly a parser/verifier boundary. Cycle 17 enables a narrow optimizer
slice for fixed-vector lane operations:

```text
extractelement, insertelement, and shufflevector are pure, side-effect-free instructions
unused lane operations may be removed by DCE
extractelement (insertelement V, X, C), C -> X when C is the same constant lane
```

Scalar InstSimplify, GVN, and EarlyCSE still do not fold or value-number vector
binary operations as scalar expressions. Vectorization and profitability remain
blocked on TargetTransformInfo-style cost modeling.

Unsupported:

```text
scalable vectors
vector element types outside integer, float, double, and ptr
vector select and vector comparisons beyond current parser boundaries
TargetTransformInfo-like profitability or vectorizer cost modeling
loop-vectorize, slp-vectorizer, vector-combine
native vector lowering
```

Fixture coverage:

```text
unit tests:
  fixed-vector function signature, add, return, print, and verify
  typed vector constant through freeze
  scalar value rejected for vector return
  scalable vector rejected
  unsupported vector element rejected
  extractelement, insertelement, and shufflevector accepted
  constant lane index and shuffle mask range rejected when out of bounds

source-backed reduced fixture:
  test/zig/expected/vector_future.reduced.ll

opt-22 equivalent:
  vector_lane_preserve
  vector_lane_dead_dce
  vector_extract_insert_fold

local-only conservative:
  vector_extract_insert_mismatch_reject
  vector_shuffle_undef_mask_preserve
```
