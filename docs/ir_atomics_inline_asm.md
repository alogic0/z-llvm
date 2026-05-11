# Atomics And Inline Assembly

This project treats atomics and inline assembly as fail-closed optimizer
boundaries. The current goal is to avoid unsound motion, deletion, or value
numbering before LLVM's atomic and inline-asm semantics are reproduced.

## Implemented Atomic Surface

```text
load atomic iN, ptr %p, <ordering>, align N
store atomic iN %v, ptr %p, <ordering>, align N
```

These forms are parsed and printed only as conservative memory barriers. The
ordering text is preserved in the local `MemoryAttrs.atomic_ordering` field,
but no transform interprets acquire, release, monotonic, or seq_cst semantics.

## Explicit Rejections

```text
atomicrmw
cmpxchg
fence
syncscope
inline asm calls
```

Inline asm is rejected explicitly as `UnsupportedInlineAsm` instead of being
treated as an indirect call. This keeps memory clobbers, constraints, and
side-effect flags from being ignored accidentally.

## Optimizer Policy

```text
DCE/ADCE: volatile and atomic memory are live side-effecting barriers.
GVN/EarlyCSE: volatile and atomic memory block memory value reuse.
LICM: volatile, atomic, loads, stores, calls, and inline asm are not hoisted.
DSE: volatile and atomic memory are barriers for store elimination.
Mem2Reg/SROA: local atomic alloca users are rejected conservatively.
```

## Fixture Coverage

```text
local-only conservative opt fixture:
  memory_atomic_barrier_reject
  adce_atomic_barrier_reject
  gvn_atomic_load_barrier_reject
  early_cse_atomic_load_barrier_reject
  licm_atomic_store_barrier_reject
  dse_atomic_store_barrier_reject

unit tests:
  atomic load/store parse/print preservation
  atomicrmw, cmpxchg, fence, and inline asm rejection
  memory-effect barrier classification
  DCE/ADCE/GVN/EarlyCSE/LICM/DSE atomic barrier preservation
  Mem2Reg atomic alloca-user rejection
```

Inline asm has no opt fixture because the parser rejects `call asm` before any
optimizer pass can see it. That is intentional until constraints, side-effect
flags, and memory clobbers are represented.

## Upstream Mapping

LLVM source anchors:

```text
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/lib/Analysis/MemoryLocation.cpp
```

LLVM models atomic ordering, sync scopes, volatile semantics, inline-asm
constraints, and memory clobbers. This project currently preserves or rejects
those constructs until the verifier, memory model, and optimizer legality rules
can match the required semantics.
