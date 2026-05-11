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
```

This is a parser/verifier boundary only. Vector instructions are not
optimizer-input corpus rows yet, and scalar InstSimplify, GVN, and EarlyCSE do
not fold or value-number vector binary operations as scalar expressions.

Unsupported:

```text
scalable vectors
vector element types outside integer, float, double, and ptr
shufflevector, insertelement, extractelement
vector select and vector comparisons beyond current parser boundaries
TargetTransformInfo-like cost modeling
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
  lane operations rejected

source-backed reduced fixture:
  test/zig/expected/vector_future.reduced.ll
```
