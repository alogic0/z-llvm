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
  Store-to-load forwarding through memory availability.

Local target status:
  LLVM-shaped foundation with unit-test-only coverage for the current
  cross-block and load-CSE subset.
```

Implemented subset:

```text
scoped dominator-tree traversal with an available-expression stack
same-basic-block and dominating-block common subexpression elimination
pure binary expression matching
pure integer cast expression matching
pure icmp expression matching
safe load CSE only when alias/mod-ref proves no clobber in the supported local region
load equality always runs through the shared MemorySSA-like clobber helper
store-to-load forwarding for must-alias non-volatile stack/pointer locations
readnone call CSE when callee attributes prove no memory effects
unknown calls and volatile/atomic accesses clear local memory availability
candidate legality goes through the shared memory-effect safe-to-delete helper
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
  early_cse_store_to_load
  early_cse_volatile_load_reject
  early_cse_load_call_clobber_reject
  early_cse_unknown_call_reject
  early_cse_ambiguous_alias_reject

local-only conservative:
  readnone call CSE is unit-tested locally. `opt-22` rewrites readnone
  declaration attributes into attribute groups that the current parser rejects,
  so this case is not in `fixtures.tsv` yet.

unit-test only:
  same-block repeated pure expression elimination
  dominating-block expression elimination
  conservative load CSE with alias/mod-ref proof
  readnone call CSE
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
no full MemorySSA walker/updater
no readonly call load-preservation model beyond conservative no-clobber
no freeze CSE because undef/poison semantics need more modeling first
no commutative operand canonicalization
no target-library knowledge
no debug-info salvage
```
