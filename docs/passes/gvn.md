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
GVNPass::processLoad
GVNPass::PerformLoadPRE
AvailableValueInBlock
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
  GVNPass::processLoad
  GVNPass::PerformLoadPRE
  AvailableValueInBlock
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
  AvailableValueInBlock records for non-local load elimination and load PRE.

Local target status:
  fixture-equivalent for listed fixtures.
```

Implemented subset:

```text
local ValueTable for pure integer binary, integer cast, icmp, select, phi, readnone call, and simple load expressions
expression identity shared with EarlyCSE through `src/analysis/expression_key.zig`
leader table scoped by dominator traversal
shared memory-effect API rejects memory-writing, volatile/atomic, and unknown instructions from value numbering
equivalence by opcode, supported non-FP flags, type, and operands
scalar non-constrained FP binary ops and `fcmp` ignore fast-math flags for
expression identity and intersect retained leader flags on replacement
simple load equivalence only when alias/mod-ref sees no clobber
load availability is routed through the shared MemorySSA-like clobber helper
load availability queries use the persisted local MemorySSA walker-shaped API
cross-block load availability is path-aware for the accepted access-list slice:
endpoint instruction order is used, and interior clobbers must be reachable on a
CFG path between the leader load and the later load
simple load PRE for one two-predecessor join shape:
  one predecessor has an available must-alias load
  one direct predecessor can receive one inserted load before its terminator
  the join load is replaced by a PHI with incoming available/inserted values
same-block and cross-block availability through scoped leaders
replacement of dominated redundant expression uses
scalar, load, and readnone-call expression equivalence shared with EarlyCSE
FP binary ops and fcmp use the shared fast-math legality helper and are admitted
for scalar non-constrained FP expressions
same-arm select cleanup is applied after local value replacements expose an
InstSimplify-equivalent select
```

This is intentionally closer to a small value-table seed than to full LLVM GVN.
It is enough to prove the project can move beyond same-block `early-cse` while
still relying on the existing dominator analysis.

Scalar PRE is still deferred. Load PRE is implemented only for the accepted
two-predecessor diamond surface and does not split critical edges or perform
general PHI translation.

Fixture coverage:

```text
opt-22 equivalent:
  gvn_dominating_expr
  gvn_nonlocal_scalar
  gvn_scalar_with_memory
  gvn_phi
  gvn_load_call_clobber_reject
  gvn_readonly_call_no_clobber
  gvn_argmemonly_call_no_clobber
  gvn_load_pre_diamond
  gvn_unknown_call_clobber_reject
  gvn_atomic_load_barrier_reject
  gvn_vector_lane_not_clobber
  fp_gvn_no_cse
  fp_extended_gvn_no_cse
  fp_gvn_flags

local-only conservative:
  gvn_load_branch_clobber_reject keeps the later load because a store in a
  different CFG block may reach the join. LLVM GVN can perform a stronger PRE
  transform for this shape, so this fixture checks the local safety boundary.
  gvn_side_exit_store_not_clobber proves the path-aware local MemorySSA query can
  ignore a side-exit store outside the queried path. `opt-22` preserves this
  shape, so full load-placement parity remains future work.
  gvn_scalar_pre_reject keeps partially available scalar expressions unchanged
  because scalar PRE insertion is not implemented.
  gvn_diamond_load_no_memory_phi is local-conservative because local leader
  naming differs from opt-22 while MemorySSA proves the same load redundancy.
  readnone call GVN is unit-tested locally. Readonly calls and accepted
  argmem-only noalias calls are trusted as non-clobbering memory accesses for
  repeated loads, matching the local `memory(read)` and `memory(argmem: write)`
  fixtures.
  fp_fast_gvn admits repeated `fadd fast` expressions and matches opt-22 for
  the accepted dominator-tree value-numbering shape.
  debug_gvn_dbg_preserve preserves the leader instruction location and drops
  the removed redundant instruction location. Variable-location salvage remains
  out of scope.

unit-test only:
  phi-aware redundancy
  simple load redundancy with no clobber
  readnone call redundancy
```

The volatile operation in `gvn_scalar_with_memory` is not value-numbered; it
only checks that unrelated scalar expressions still use the normal GVN path.

Known gaps:

```text
load PRE is limited to one direct two-predecessor diamond shape
no MemorySSA-backed memory value numbering beyond the accepted path-aware
walker query
no general PHI translation beyond exact phi expression matching and the simple
load-PRE PHI insertion
no congruence-class iteration
linear local ValueTable lookup instead of LLVM's richer hashing
no dead-leader replacement beyond same-block redundant loads
no critical-edge splitting or general partial redundancy handling
no assume, readonly call return-value numbering, GEP, freeze, constrained FP,
vector, or memory value numbering
no FP commutative operand canonicalization
no debug-info salvage beyond preserving the leader instruction location
```
