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
  MemorySSAWalker
  MemorySSA::getWalker
  MemorySSAWalker::getClobberingMemoryAccess
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
  LLVM-shaped access-list and walker-query subset

Implemented subset:
  InstRef identifies a memory access by block and instruction index.
  MemorySSA.build records accepted MemoryUse, MemoryDef, barrier, and narrow
  MemoryPhi-like join facts in deterministic function order.
  getWalker returns a MemorySSAWalker-shaped query object.
  Walker.getClobberingMemoryAccess returns either live-on-entry or a
  clobbering MemoryUse/MemoryDef/MemoryPhi-style access for accepted local IR.
  Walker.getClobberBetween answers the existing GVN and EarlyCSE load
  availability query using the same access-clobber logic.
  hasClobberBetween routes through the walker API; the old direct
  block/instruction scan is removed.
  alias.modRefInModule decides whether an intervening instruction is a
  def/barrier for the queried pointer using module DataLayout and globals.
  readnone and readonly direct calls are treated as non-clobbering for load
  availability through function attribute classification.
  Direct calls with resolved `memory(argmem: ...)` attributes use alias ModRef
  refinement, so a write through a noalias stack pointer argument does not
  clobber an unrelated queried location.
  Direct calls with resolved `memory(inaccessiblemem: ...)` attributes are
  ignored for ordinary LLVM IR-accessible memory queries.
  Fixed-vector extractelement, insertelement, and shufflevector instructions are
  pure non-accesses, so they do not create MemoryUse, MemoryDef, or barrier
  entries.
  unknown calls, volatile memory, atomic memory, may-alias stores, and
  same-pointer stores are clobbers.
  Cross-block clobber queries are path-aware for the accepted access-list slice:
  endpoint blocks use instruction order, while interior accesses are considered
  only when CFG reachability places them on a path from the defining access to
  the queried access.
  MemoryPhi-like join facts are placed only when reachable predecessor paths
  contain memory accesses; pure predecessor diamonds do not create a phi barrier
  solely because the join block itself contains a load.
  GVN load availability uses this shared helper.
  EarlyCSE load CSE uses this helper before replacing an available load.
  DSE uses a MemorySSA-owned same-block overwrite query when direction and
  dominance are explicit.
  deleteAccess and replaceInstructionAccess provide the first local updater
  operations for simple instruction deletion/replacement.
  verifyConsistent rebuilds the access list and checks that updater-maintained
  state still matches the function.
  dump prints deterministic MemoryUse/MemoryDef/MemoryPhi-style expectations
  for unit tests.

Intentional divergences:
  MemoryPhi support is conservative: join facts are barriers for accepted
  queries, not full per-location phi operands.
  Cross-block queries still reject more cases than LLVM. LLVM's walker follows
  defining accesses and caches optimized defs; the local walker scans the
  access list and uses CFG reachability to reject impossible paths.
  LICM has one local stack-slot promotion shape, but does not maintain a general
  MemorySSA updater for arbitrary memory motion.
  EarlyCSE still uses scoped local availability for store-to-load forwarding.
  The access list is still usually rebuilt per function; updater support covers
  only simple access deletion/replacement.
  No optimized access cache or clobber-walk skipping exists.
  The walker is shape-compatible with LLVM query clients but not performance- or
  precision-equivalent to LLVM's optimized walker.

Analysis preservation/invalidation:
  The local access list is built per pass invocation. Mutating passes normally
  rebuild it before querying. DSE verifies MemorySSA consistency after deleting
  stores; complex CFG rewrites still rebuild rather than update in place.

Fixture coverage:
  unit test: memory ssa walker reports clobbering access or live-on-entry
  unit test: memory ssa walker reports memory phi as clobber
  unit test: memory ssa clobber helper covers accepted memory-dependence cases
  unit test: memory ssa records narrow phi facts at joins
  unit test: memory ssa updater deletes accesses and dumps expectations
  opt fixture: early_cse_readonly_call_no_clobber
  opt fixtures: early_cse_load_call_clobber_reject, gvn_load_call_clobber_reject
  opt fixture: gvn_load_pre_diamond
  opt fixture: gvn_argmemonly_call_no_clobber
  opt fixtures: early_cse_load_branch_clobber_reject
  opt fixture: early_cse_unreachable_store_not_clobber
  opt fixture: early_cse_diamond_no_memory_phi
  opt fixtures: gvn_vector_lane_not_clobber,
    early_cse_vector_lane_store_forward, dse_vector_lane_not_barrier
  local-only opt fixture: early_cse_param_gep_noalias_forward
  local-only opt fixture: gvn_load_branch_clobber_reject
  opt fixtures: dse_overwrite, dse_load_barrier, dse_volatile_barrier
  opt fixture: dse_partial_overwrite_lattice

opt-22 comparison command:
  covered indirectly through GVN and EarlyCSE memory fixtures in
  `bash scripts/compare_opt.sh`

Local-only fixture command:
  zig build test
  bash scripts/compare_opt.sh
```
