# GVN

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Transforms/Scalar/GVN.h
llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/NewGVN.cpp
```

Upstream entry points to check:

```text
GVNPass::run
GVNPass::runImpl
GVNPass::ValueTable
GVNPass::ValueTable::createExpr
NewGVNPass::run
NewGVN::CongruenceClass
```

LLVM GVN removes redundant computations by assigning value numbers to equivalent
expressions and proving that an available equivalent value dominates a later
use.

Implemented subset:

```text
per-function scan for pure binary, icmp, and select expressions
equivalence by opcode, type, and operands
dominator check for cross-block availability
same-block availability by instruction order
replacement of dominated redundant expression uses
```

This is intentionally closer to a small value-table seed than to full LLVM GVN.
It is enough to prove the project can move beyond same-block `early-cse` while
still relying on the existing dominator analysis.

Known gaps:

```text
no load PRE or MemorySSA
no phi translation
no congruence-class iteration
no expression hashing
no critical-edge or partial redundancy handling
no assume, call, GEP, cast, vector, or memory value numbering
```
