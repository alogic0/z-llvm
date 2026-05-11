# MemorySSA Design Note

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/MemorySSA.h
llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp
llvm-project-22/llvm/lib/Analysis/MemorySSAUpdater.cpp
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/MemorySSA.h
  llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp

LLVM entry points/classes:
  MemorySSA
  MemoryDef
  MemoryUse
  MemoryPhi
  MemorySSAUpdater

Required analyses:
  CFG
  DominatorTree
  AliasAnalysis
  MemoryLocation

Required IR invariants:
  Verified memory instructions and CFG.

Core LLVM algorithm data structures:
  Def/use chain for memory state
  MemoryPhi nodes at CFG joins
  Walker queries for clobbering memory accesses

Local target status:
  LLVM-shaped access-list and clobber-query subset

Implemented subset:
  InstRef identifies a memory access by block and instruction index.
  MemorySSA.build records accepted MemoryUse, MemoryDef, barrier, and narrow
  MemoryPhi-like join facts in deterministic function order.
  hasClobberBetween queries the persisted access list for GVN and EarlyCSE load
  availability.
  alias.modRefInModule decides whether an intervening instruction is a
  def/barrier for the queried pointer using module DataLayout and globals.
  readnone and readonly direct calls are treated as non-clobbering for load
  availability through function attribute classification.
  unknown calls, volatile memory, atomic memory, may-alias stores, and
  same-pointer stores are clobbers.
  Cross-block clobber queries are path-safe by construction: endpoint blocks
  use instruction order, while any other memory access in another block is
  treated as potentially between the queried accesses until a real MemorySSA
  walker is implemented.
  GVN load availability uses this shared helper.
  EarlyCSE load CSE uses this helper before replacing an available load.
  DSE uses a MemorySSA-owned same-block overwrite query when direction and
  dominance are explicit.

Intentional divergences:
  MemoryPhi support is conservative: join facts are barriers for accepted
  queries, not full per-location phi operands.
  Cross-block queries deliberately reject more cases than LLVM. LLVM can walk
  MemorySSA and use dominance/path facts; the local access-list helper treats
  unknown intervening blocks as clobbers instead of relying on block order.
  LICM does not move memory instructions.
  EarlyCSE still uses scoped local availability for store-to-load forwarding.
  The access list is rebuilt per function and does not have a MemorySSAUpdater.
  No MemorySSA walker, optimized access cache, or clobber-walk skipping exists.

Analysis preservation/invalidation:
  The local access list is built per pass invocation. Mutating passes rebuild it
  before querying and do not preserve it across transformations.

Fixture coverage:
  unit test: memory ssa clobber helper covers accepted memory-dependence cases
  unit test: memory ssa records narrow phi facts at joins
  opt fixtures: early_cse_load_call_clobber_reject, gvn_load_call_clobber_reject
  opt fixtures: early_cse_load_branch_clobber_reject
  local-only opt fixture: gvn_load_branch_clobber_reject
  opt fixtures: dse_overwrite, dse_load_barrier, dse_volatile_barrier

opt-22 comparison command:
  covered indirectly through GVN and EarlyCSE memory fixtures in
  `bash scripts/compare_opt.sh`

Local-only fixture command:
  zig build test
  bash scripts/compare_opt.sh
```
