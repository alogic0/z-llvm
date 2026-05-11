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
load availability queries use the persisted local MemorySSA access list
cross-block load CSE treats memory accesses in non-endpoint blocks as possible
clobbers until a path-aware MemorySSA walker exists
store-to-load forwarding for must-alias non-volatile stack/pointer locations
readnone call CSE when callee attributes prove no memory effects
unknown calls and volatile/atomic accesses clear local memory availability
candidate legality goes through the shared memory-effect safe-to-delete helper
later dominated uses are rewritten to the earlier value
scalar, load, and readnone-call expression equivalence shared with GVN
FP binary ops and fcmp use the shared fast-math legality helper and are admitted
only under the local `fast` boundary
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
  early_cse_load_branch_clobber_reject
  early_cse_param_gep_partial_alias_reject
  early_cse_unreachable_store_not_clobber
  early_cse_unknown_call_reject
  early_cse_ambiguous_alias_reject

local-only conservative:
  readnone call CSE is unit-tested locally. `opt-22` rewrites readnone
  declaration attributes into attribute groups that the current parser rejects,
  so this case is not in `fixtures.tsv` yet.
  fp_early_cse_no_cse preserves repeated FP expressions locally. LLVM may CSE
  more FP expressions once exact FP legality is modeled.
  fp_extended_early_cse_no_cse applies the same conservative boundary to scalar
  `fsub`, `fdiv`, and `frem`.
  fp_fast_early_cse admits repeated `fadd fast` expressions. The local result
  name differs from opt-22, so the fixture is local-conservative.
  fp_fast_cse_reject documents that non-fast FP expressions stay outside the
  local CSE boundary.
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
no full MemorySSA walker/updater
no full MemorySSA-backed load CSE beyond the accepted path-aware access-list
query
readonly calls are modeled only as non-clobbering memory accesses; no readonly
call return-value CSE
no freeze CSE because undef/poison semantics need more modeling first
no strict FP CSE; FP CSE is limited to the local `fast` boundary
no commutative operand canonicalization
no target-library knowledge
no debug-info salvage beyond preserving the leader instruction location
```
