# Memory And Side-Effect Semantics

This document records the Epic 5 legality contract shared by memory-moving,
memory-deleting, and value-numbering passes. The goal is a single conservative
model that all passes use before they claim LLVM fixture equivalence.

## Upstream Mapping

LLVM source areas:

```text
llvm-project-22/llvm/include/llvm/IR/Instruction.h
llvm-project-22/llvm/lib/IR/Instruction.cpp
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h
llvm-project-22/llvm/include/llvm/Analysis/MemorySSA.h
llvm-project-22/llvm/lib/Analysis/BasicAliasAnalysis.cpp
llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/LICM.cpp
```

LLVM concepts approximated locally:

```text
Instruction::mayReadOrWriteMemory
Instruction::mayHaveSideEffects
LoadInst::isVolatile / StoreInst::isVolatile
LoadInst::isAtomic / StoreInst::isAtomic
AAResults::alias
AAResults::getModRefInfo
MemoryLocation
MemorySSA / MemoryUse / MemoryDef / MemoryPhi
```

## Local API

The shared code lives in:

```text
src/analysis/memory_effect.zig
src/analysis/memory_location.zig
src/analysis/alias.zig
docs/analysis/memory_ssa.md
```

`memory_effect.zig` classifies instructions as:

```text
none
readonly_load
memory_write
volatile_or_atomic_barrier
unknown
```

The API exposes:

```text
mayReadMemory
mayWriteMemory
mayReadOrWriteMemory
mayThrow
mayTrap
hasSideEffects
isSafeToDelete
isSafeToSpeculativelyExecute
barrierKind: none, volatile, atomic
```

The current `Effect` enum keeps volatile and atomic memory under one hard
barrier class because no pass is allowed to optimize either form yet. Passes
that need diagnostics or future split behavior can use `barrierKind`.

## Local Alias And Mod/Ref

`alias.zig` deliberately answers only conservative questions:

```text
must_alias for identical pointer values and zero-offset stack GEPs
no_alias for distinct stack slots
no_alias for known disjoint same-root scalar byte ranges
may_alias for unknown roots, unknown offsets, parameters, globals, and unsupported values
mod/ref for direct load/store when alias facts are known
unknown for calls, volatile memory, atomic memory, or unsupported memory effects
```

`memory_location.zig` models stack roots, scalar byte offsets, and scalar access
sizes. It is DataLayout-shaped for the accepted scalar integer/GEP surface, but
it is not a full LLVM `DataLayout` implementation. Aggregate, vector,
address-space, global, metadata, and target-specific layout facts remain
unsupported.

## Pass Integrations

| Pass | Integration |
| --- | --- |
| DCE | Uses `isSafeToDelete` so stores, calls, volatile, and atomic memory are preserved. |
| ADCE | Uses the same safe-to-delete rule as the current conservative data-dependence foundation. |
| LICM | Uses `isSafeToSpeculativelyExecute`; selected invariant loads and one stack-slot load/store promotion shape can move, while calls, volatile/atomic memory, and trapping division stay in the loop. |
| GVN | Uses memory-effect classification to reject writing/unknown/barrier instructions and alias/mod-ref to protect load value numbering. |
| EarlyCSE | Uses `isSafeToDelete` and alias/mod-ref guarded load availability. |
| DSE | Uses MemoryLocation plus alias/mod-ref-style barrier rules for single-block overwritten store removal. |

## Fixture Coverage

`opt-22` equivalent fixtures:

```text
memory_dce
dce_scalar_with_memory
dce_volatile_load_reject
gvn_scalar_with_memory
licm_scalar_with_memory
licm_promote_stack
dse_overwrite
dse_load_barrier
mem2reg_volatile_load
mem2reg_volatile_store
```

Local conservative unit coverage:

```text
volatile and atomic barrier classification
barrier kind split for volatile versus atomic spelling
unknown call may-throw behavior
division may-trap behavior
LICM trapping-division rejection
LICM aligned-load rejection outside the accepted one-slot promotion shape
DCE atomic barrier preservation
known stack-slot alias, no-alias, and may-alias queries
known scalar GEP offset and disjoint range queries
unknown pointer mod/ref conservatism
```

Run:

```sh
zig build test
bash scripts/compare_opt.sh
```

## Conservative Gaps

These are intentional Epic 5 boundaries, not accidental mismatches:

- no MemorySSA graph or updater;
- no general memory LICM, load PRE, store sinking, or cross-block DSE;
- no readonly/readnone call deletion in DCE yet, even though call attributes are
  parsed for function-attribute analysis;
- no target-library call mod/ref modeling;
- no full atomic ordering or syncscope semantics; narrow `fence`, `cmpxchg`,
  `atomicrmw`, and syncscope forms are accepted only as hard barriers;
- no address spaces, globals, captures, TBAA, alias scopes, noalias, invariant
  metadata, or target-specific DataLayout facts;
- no partial alias result or partial-overwrite DSE.

Future memory optimizations must either prove legality through this shared API
or extend this document and the matching analysis code in the same slice.
