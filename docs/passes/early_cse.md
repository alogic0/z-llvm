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
scoped dominator-tree traversal with an available-expression stack
same-basic-block and dominating-block common subexpression elimination
pure binary expression matching
pure integer cast expression matching
pure icmp expression matching
safe load CSE only when alias/mod-ref proves no clobber in the supported local region
later dominated uses are rewritten to the earlier value
scalar expression equivalence shared with the InstSimplify helper
```

Upstream mapping:

```text
This reproduces LLVM EarlyCSE's scoped available-value shape over a dominator
tree, but with a much smaller expression and memory model.
LLVM also handles richer memory, calls, assumptions, target/library knowledge,
and poison-sensitive cases.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  same-block repeated pure expression elimination
  dominating-block expression elimination
  conservative load CSE with alias/mod-ref proof
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
no full MemorySSA-backed load CSE
no freeze CSE because undef/poison semantics need more modeling first
no commutative operand canonicalization
no target-library knowledge
no debug-info salvage
```
