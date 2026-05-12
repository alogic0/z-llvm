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
LLVM splat vector constants such as `splat (i8 10)`, including instruction
operands and call arguments
integer and FP binary instructions with matching fixed-vector operand types
vector integer and FP comparisons with fixed-vector operands produce `<N x i1>`
mask result types
extractelement with scalar integer lane indices
insertelement with matching vector element value type
shufflevector with matching input vector types and integer vector masks
bitcast from fixed-width integer/FP vectors to equal-width scalar integer/FP types
```

This is mostly a parser/verifier boundary. Cycle 17 enables a narrow optimizer
slice for fixed-vector lane operations:

```text
extractelement, insertelement, and shufflevector are pure, side-effect-free instructions
unused lane operations may be removed by DCE
extractelement (insertelement V, X, C), C -> X when C is the same constant lane
vector lane operations do not clobber MemorySSA, alias ModRef, GVN load
availability, EarlyCSE local store availability, or DSE overwrite scans
```

Cycle 18 enables one target-independent select simplification for vector-valued
selects with a scalar `i1` condition:

```text
select i1 C, <N x T> V, <N x T> V -> V
```

This uses the same identical-arm rule as scalar `select`. It does not require a
vector cost model because it removes an instruction without changing lane
semantics. Scalar InstSimplify, GVN, and EarlyCSE still do not fold or
value-number vector binary operations as scalar expressions. Vectorization and
profitability remain blocked on TargetTransformInfo-style cost modeling.

Cycle 04 keeps `vector_future_release_fast` as `parse,verify,future`, not as an
optimizer-input corpus row. Activating that row requires a selected
TargetTransformInfo-style cost model or native vector-lowering requirement, plus
policy for vector FP semantics, vector-condition legality, and scalable
vectors.

Unsupported:

```text
scalable vectors
vector element types outside integer, float, double, and ptr
vector-condition select and vector comparisons beyond current parser boundaries
vector FP transforms beyond parse/verify preservation for supported binary ops
TargetTransformInfo-like profitability or vectorizer cost modeling
loop-vectorize, slp-vectorizer, vector-combine
native vector lowering
```

Fixture coverage:

```text
unit tests:
  fixed-vector function signature, add, return, print, and verify
  typed vector constant through freeze
  typed vector splat constant through vector icmp
  vector compare mask result type feeding a bitcast
  vector mask bitcast to equal-width integer
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
  vector_select_same_arms
  early_cse_vector_lane_store_forward
  dse_vector_lane_not_barrier

local-only conservative:
  vector_extract_insert_mismatch_reject
  vector_shuffle_undef_mask_preserve
  gvn_vector_lane_not_clobber
```
