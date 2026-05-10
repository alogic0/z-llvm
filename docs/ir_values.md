# IR Values

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Value.h
llvm-project-22/llvm/include/llvm/IR/Constants.h
llvm-project-22/llvm/lib/IR/Constants.cpp
llvm-project-22/llvm/lib/IR/AsmWriter.cpp
```

Upstream entry points to check:

```text
Value
Constant
UndefValue
UndefValue::get
PoisonValue
AsmWriter support for undef
```

Implemented subset:

```text
named SSA values: %name
integer constants
undef constants
```

Upstream mapping:

```text
This reproduces the printed `undef` constant form and treats it as type-compatible with the expected operand type.
LLVM models `undef` as a typed constant, distinguishes it from poison, and has much richer constant folding rules around undefined values.
```

Known gaps:

```text
no poison value
no typed constant objects
no aggregate/vector constants
no constant expressions
no undef-specific instruction folding rules
```
