# Expression Keys

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/NewGVN.cpp
```

Upstream entry points to check:

```text
EarlyCSE::SimpleValue
GVNPass::ValueTable::createExpr
NewGVN::Expression
```

The local expression-key helper centralizes the identity rules shared by
EarlyCSE and GVN. It is not a full hash-consed LLVM expression table yet.

Implemented subset:

```text
scalar binary keys with opcode, flags, type, and operands
integer cast keys with opcode, source type, value, and destination type
icmp keys with predicate, operand type, and operands
select keys with condition type, condition, result type, and arms
exact PHI keys with type and incoming value/block pairs
load keys only when both loads are non-volatile, non-atomic, same type, and
must-alias under the local alias helper
readnone direct-call keys with callee, calling convention, return type, and
argument type/value pairs
```

Current users:

```text
src/passes/early_cse.zig
src/passes/gvn.zig
```

Known gaps:

```text
no stable hash table yet
no commutative operand normalization beyond InstCombine's local canonicalizer
no MemorySSA value numbering for memory expressions
no readonly call value numbering
no GEP, freeze, vector, aggregate, or poison-aware expression keys
```
