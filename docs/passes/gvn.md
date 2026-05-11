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
Instruction::mayReadOrWriteMemory
```

LLVM GVN removes redundant computations by assigning value numbers to equivalent
expressions and proving that an available equivalent value dominates a later
use.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/NewGVN.cpp

LLVM entry points/classes:
  GVNPass::run
  GVNPass::ValueTable
  NewGVNPass::run
  NewGVN::CongruenceClass

Required analyses:
  DominatorTree.
  AliasAnalysis, MemoryDependence or MemorySSA-like facts for memory values.
  AssumptionCache and TargetLibraryInfo for broader LLVM folds.

Required IR invariants:
  Replacement values must dominate every rewritten use.
  Memory-value replacement requires alias/mod-ref proof.

Core LLVM algorithm data structures:
  Value table / expression numbering.
  Leader tables for available values.
  Memory dependence facts for load and call cases.

Local target status:
  fixture-equivalent for listed fixtures.
```

Implemented subset:

```text
local ValueTable for pure binary, integer cast, icmp, select, phi, readnone call, and simple load expressions
leader table scoped by dominator traversal
shared memory-effect API rejects memory-writing, volatile/atomic, and unknown instructions from value numbering
equivalence by opcode, flags where present, type, and operands
simple load equivalence only when alias/mod-ref sees no clobber
same-block and cross-block availability through scoped leaders
replacement of dominated redundant expression uses
scalar expression equivalence shared with the InstSimplify helper
```

This is intentionally closer to a small value-table seed than to full LLVM GVN.
It is enough to prove the project can move beyond same-block `early-cse` while
still relying on the existing dominator analysis.

PRE is explicitly deferred. The local pass does not insert expressions or split
edges until dominance, critical-edge, and insertion-point rules are documented
for the accepted IR surface.

Fixture coverage:

```text
opt-22 equivalent:
  gvn_dominating_expr
  gvn_scalar_with_memory
  gvn_phi

local-only conservative:
  readnone call GVN is unit-tested locally. `opt-22` emits attribute groups for
  the equivalent fixture, which the current parser rejects.

unit-test only:
  phi-aware redundancy
  simple load redundancy with no clobber
  readnone call redundancy
```

The volatile operation in `gvn_scalar_with_memory` is not value-numbered; it
only checks that unrelated scalar expressions still use the normal GVN path.

Known gaps:

```text
no load PRE or MemorySSA
no MemorySSA-backed memory value numbering
no phi translation beyond exact phi expression matching
no congruence-class iteration
linear local ValueTable lookup instead of LLVM's richer hashing
no critical-edge or partial redundancy handling
no assume, readonly call, GEP, freeze, vector, or memory value numbering
```
