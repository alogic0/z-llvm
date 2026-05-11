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
inline asm lowering and constraint validation
```

Inline asm is represented only for the observed source-backed barrier shape:
`call void asm sideeffect "...", "...~{memory}..."()`. The parser preserves the
template and constraint strings, records `sideeffect`, and marks `~{memory}` as
a memory clobber. It does not validate registers, constraints, outputs, native
lowering, or target-specific behavior.

The current source-backed captured row
`atomics_inline_asm_debug_release_fast` remains future-only because the full row
also contains call-site attributes and `atomicrmw`. The reduced inline-asm
barrier is accepted as optimizer input; a reduced `atomicrmw` fixture documents
the next blocker in the same Zig source group.

## Optimizer Policy

```text
DCE/ADCE: volatile, atomic, and inline asm memory are live side-effecting barriers.
GVN/EarlyCSE: volatile, atomic, and inline asm memory block memory value reuse.
LICM: volatile, atomic, loads, stores, calls, and inline asm are not hoisted.
DSE: volatile, atomic, and inline asm memory are barriers for store elimination.
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
  reduced inline asm parse/print preservation as a side-effecting memory barrier
  atomicrmw, cmpxchg, and fence rejection
  source-backed reduced inline-asm and atomicrmw fixtures from
  `atomics_inline_asm_debug_release_fast`
  memory-effect barrier classification
  DCE/ADCE/GVN/EarlyCSE/LICM/DSE atomic barrier preservation
  Mem2Reg atomic alloca-user rejection
```

Inline asm has an opt fixture for preservation only:

```text
inline_asm_barrier_preserve
```

It proves the local optimizer can remove unrelated dead scalar code while
preserving the side-effecting memory-clobber asm call.

Source-backed reduced rejection fixtures:

```text
test/zig/expected/atomics_inline_asm_inline_asm.reduced.ll
test/zig/expected/atomics_inline_asm_atomicrmw.unsupported.ll
```

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
