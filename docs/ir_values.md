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
AsmWriter support for undef
AsmWriter support for i1 true/false constants
Verifier::visitExtractValueInst
```

Implemented subset:

```text
named SSA values: %name
integer constants
i1 boolean constants parsed as integer 1/0 for normalization
undef constants
extractvalue over aggregate values with integer index lists
freeze instruction syntax is documented separately in [ir_scalar.md](ir_scalar.md)
```

Upstream mapping:

```text
This reproduces the printed `undef` constant form and treats it as type-compatible with the expected operand type.
LLVM models `undef` as a typed constant, distinguishes it from poison, and has much richer constant folding rules around undefined values.
LLVM uses `freeze` to turn undef/poison-sensitive values into a stable value before transforms that require that guarantee.
The local `extractvalue` support reproduces the parser, verifier, printer, and def-use behavior needed for Zig stage4 cmpxchg result values such as `extractvalue { i32, i1 } %pair, 1`; aggregate layout and optimization semantics remain outside this slice.
```

Known gaps:

```text
no poison value
no typed constant objects
no aggregate constants
no insertvalue
extractvalue is parse/verify/print only; no aggregate folding or aggregate layout reasoning beyond selecting the indexed result type
narrow typed vector constants parse and verify only for the fixed-vector
boundary in `docs/ir_vectors.md`
no constant expressions
no undef-specific instruction folding rules beyond preserving `freeze`
```
