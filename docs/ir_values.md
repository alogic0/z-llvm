# IR Values

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Value.h
llvm-project-22/llvm/include/llvm/IR/Constants.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Constants.cpp
llvm-project-22/llvm/lib/IR/AsmWriter.cpp
llvm-project-22/llvm/lib/IR/Verifier.cpp
```

Upstream entry points to check:

```text
Value
Constant
UndefValue
UndefValue::get
PoisonValue
FreezeInst
ExtractValueInst
InsertValueInst
CallInst
AsmWriter support for undef
AsmWriter support for i1 true/false constants
Verifier::visitExtractValueInst
Verifier::visitCallBase
```

Implemented subset:

```text
named SSA values: %name
integer constants
i1 boolean constants parsed as integer 1/0 for normalization
undef constants
extractvalue over aggregate values with integer index lists
insertvalue over aggregate values with integer index lists
aggregate-typed PHI values and aggregate constants in PHI incoming values
aggregate call result type spelling for direct calls, including LLVM overflow intrinsic result shapes such as `{ i8, i1 }`
freeze instruction syntax is documented separately in [ir_scalar.md](ir_scalar.md)
```

Upstream mapping:

```text
This reproduces the printed `undef` constant form and treats it as type-compatible with the expected operand type.
LLVM models `undef` as a typed constant, distinguishes it from poison, and has much richer constant folding rules around undefined values.
LLVM uses `freeze` to turn undef/poison-sensitive values into a stable value before transforms that require that guarantee.
The local `extractvalue` support reproduces the parser, verifier, printer, and def-use behavior needed for Zig stage4 cmpxchg result values such as `extractvalue { i32, i1 } %pair, 1`; aggregate layout and optimization semantics remain outside this slice.
The local `insertvalue` support preserves source-backed aggregate construction such as `insertvalue { ptr, i64 } poison, ptr %p, 0` without modeling aggregate optimization semantics.
Aggregate PHI parsing preserves source-backed aggregate values and aggregate constant incoming values without folding or layout interpretation.
The local call parser consumes full leading return types for direct calls, matching the LLVM assembly parser shape needed for Zig stage4 overflow intrinsic calls such as `call { i8, i1 } @llvm.umul.with.overflow.i8(...)`.
```

Known gaps:

```text
no poison value
no typed constant objects
aggregate constants are preserved only in the currently observed PHI boundary
extractvalue is parse/verify/print only; no aggregate folding or aggregate layout reasoning beyond selecting the indexed result type
insertvalue is parse/verify/print only; no aggregate folding or aggregate layout reasoning beyond checking the indexed inserted value type
aggregate-valued calls are preserved only; no overflow intrinsic semantics, aggregate return lowering, or intrinsic folding is modeled
narrow typed vector constants parse and verify only for the fixed-vector
boundary in `docs/ir_vectors.md`
no constant expressions
no undef-specific instruction folding rules beyond preserving `freeze`
```
