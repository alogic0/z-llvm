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
LoadValue
AvailableLoads
EarlyCSE::isSameMemGeneration
MemorySSA::getWalker
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
  LoadValue
  EarlyCSE::isSameMemGeneration

Required analyses:
  DominatorTree for LLVM's scoped traversal.
  AssumptionCache, TargetLibraryInfo, and MemorySSA-backed memory facts for the
  broader LLVM implementation.

Required IR invariants:
  Verified SSA.
  Values recorded in the scoped table must dominate all replacement uses.

Core LLVM algorithm data structures:
  ScopedHashTable of available expressions and values.
  Available-load tracking for memory cases through LoadValue records.
  MemorySSA walker queries when generation counters alone are insufficient.
  Store-to-load forwarding through memory availability.

Local target status:
  fixture-equivalent for listed memory and scalar fixtures, with local-only
  unit coverage for readnone call CSE.
```

Implemented subset:

```text
scoped dominator-tree traversal with an available-expression stack
expression identity shared with GVN through `src/analysis/expression_key.zig`
same-basic-block and dominating-block common subexpression elimination
pure integer binary expression matching
pure integer cast expression matching
pure icmp expression matching
safe load CSE only when alias/mod-ref proves no clobber in the supported local region
load equality always runs through the shared MemorySSA-like clobber helper
load availability queries call the persisted local MemorySSA walker-shaped API
through an `isSameMemoryGeneration` helper modeled after LLVM
cross-block load CSE treats MemoryPhi, volatile/atomic, unknown calls, and
aliasing stores as clobbers through that walker
store-to-load forwarding for must-alias non-volatile stack/pointer locations
store-to-load forwarding still uses the local scoped store table; LLVM's store
generation model is not reproduced in this slice
readnone call CSE when callee attributes prove no memory effects
unknown calls and volatile/atomic accesses clear local memory availability
candidate legality goes through the shared memory-effect safe-to-delete helper
later dominated uses are rewritten to the earlier value
scalar, load, and readnone-call expression equivalence shared with GVN
FP binary ops and fcmp use the shared fast-math legality helper and are admitted
for scalar non-constrained FP expressions
retained FP leaders intersect fast-math flags with the removed instruction,
matching LLVM's `combineIRFlags` category for CSE
same-arm select cleanup is applied after local value replacements expose an
InstSimplify-equivalent select
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
  early_cse_readonly_call_no_clobber
  early_cse_volatile_load_reject
  early_cse_load_call_clobber_reject
  early_cse_load_branch_clobber_reject
  early_cse_atomic_load_barrier_reject
  early_cse_param_gep_partial_alias_reject
  early_cse_unreachable_store_not_clobber
  early_cse_unknown_call_reject
  early_cse_ambiguous_alias_reject
  fp_early_cse_flags
  fp_early_cse_no_cse
  fp_extended_early_cse_no_cse
  fp_fast_early_cse
  fp_fast_cse_reject

local-only conservative:
  readnone call CSE is unit-tested locally. `opt-22` rewrites readnone
  declaration attributes into attribute groups that the current parser rejects,
  so this case is not in `fixtures.tsv` yet.
  early_cse_unreachable_store_not_clobber proves the path-aware local
  MemorySSA query can ignore a side-exit store. `opt-22` preserves this shape,
  so the fixture documents a local precision boundary rather than full EarlyCSE
  parity.
  early_cse_diamond_no_memory_phi proves MemorySSA avoids a join phi for pure
  predecessor diamonds; local leader naming differs from opt-22.
  early_cse_param_gep_partial_alias_reject keeps overlapping parameter GEP
  ranges as aliasing barriers.
  debug_early_cse_dbg_preserve preserves the leader instruction location and
  drops the removed redundant instruction location. This is a local
  debug-location-only rule, not LLVM debug-info salvage parity.

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
no full optimized MemorySSA walker/updater
no full MemorySSA-backed load CSE beyond the accepted path-aware walker query
store-to-load forwarding is not yet routed through LLVM's LoadValue generation
model
readonly calls are modeled only as non-clobbering memory accesses; no readonly
call return-value CSE
no freeze CSE because undef/poison semantics need more modeling first
no constrained-FP CSE for dynamic rounding or strict exceptions
no FP commutative operand canonicalization
no target-library knowledge
no debug-info salvage beyond preserving the leader instruction location
```
