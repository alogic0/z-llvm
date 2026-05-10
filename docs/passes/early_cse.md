# early-cse

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp
```

Upstream entry points to check:

```text
EarlyCSEPass::run
EarlyCSE
SimpleValue
ScopedHashTable used for available values
```

Early CSE removes redundant computations early in the scalar optimization pipeline.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp

LLVM entry points/classes:
  EarlyCSEPass::run
  EarlyCSE
  SimpleValue

Required analyses:
  DominatorTree for LLVM's scoped traversal.
  AssumptionCache, TargetLibraryInfo, and MemorySSA-backed memory facts for the
  broader LLVM implementation.

Required IR invariants:
  Verified SSA.
  Values recorded in the scoped table must dominate all replacement uses.

Core LLVM algorithm data structures:
  ScopedHashTable of available expressions and values.
  Available-load tracking for memory cases.

Local target status:
  LLVM-shaped foundation.
```

Implemented subset:

```text
same-basic-block common subexpression elimination
pure add/sub/mul expression matching
pure integer cast expression matching
pure icmp eq/ne expression matching
later uses in the same block are rewritten to the earlier value
scalar expression equivalence shared with the InstSimplify helper
```

Upstream mapping:

```text
This reproduces only the available-value lookup idea from EarlyCSE.
LLVM's implementation walks with dominator/tree scoped tables and also handles memory, loads, calls, and target/library knowledge.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  same-block repeated pure expression elimination
```

Example:

```text
before:
  %x = add i32 %a, 1
  %y = add i32 %a, 1
  ret i32 %y

after early-cse:
  %x = add i32 %a, 1
  ret i32 %x
```

Known gaps:

```text
no dominator-tree walk yet
no memory value numbering
no load CSE
no freeze CSE because undef/poison semantics need more modeling first
no commutative operand canonicalization
no control-flow-aware replacement
no target-library knowledge
no debug-info salvage
```
