# Atomics And Inline Assembly

This project treats atomics and inline assembly as fail-closed optimizer
boundaries. The current goal is to avoid unsound motion, deletion, or value
numbering before LLVM's atomic and inline-asm semantics are reproduced.

## Implemented Atomic Surface

```text
load atomic iN, ptr %p, <ordering>, align N
store atomic iN %v, ptr %p, <ordering>, align N
load/store with `syncscope("...")` before the ordering
atomicrmw <op> ptr %p, iN %v [syncscope("...")] <ordering>, align N
cmpxchg [weak] ptr %p, iN %old, iN %new [syncscope("...")] <success> <failure>, align N
fence [syncscope("...")] <ordering>
```

These forms are parsed and printed as conservative memory barriers. The verifier
now checks the LLVM-shaped ordering and operand-type rules for the accepted
surface: load cannot be release/acq_rel, store cannot be acquire/acq_rel,
`atomicrmw` cannot be unordered, fence must be acquire/release/acq_rel/seq_cst,
and `cmpxchg` failure ordering cannot be release/acq_rel or stronger than the
success ordering. It also checks byte-sized power-of-two scalar access sizes,
`atomicrmw` operation/type classes, and integer-or-pointer `cmpxchg` operands.
No transform interprets acquire, release, monotonic, acq_rel, seq_cst, or
syncscope semantics for optimization.

## Explicit Rejections

```text
inline asm lowering and constraint validation
malformed syncscope text
invalid atomic ordering combinations
invalid scalar atomic access sizes such as `i1` and non-power-of-two integers
invalid `atomicrmw` operation/type pairs
non-integer/non-pointer `cmpxchg` operand types
```

`atomicrmw`, `cmpxchg`, and `fence` are accepted only as conservative
side-effecting memory barriers. Ordering text and optional alignment are
preserved, but no pass interprets atomic ordering or performs atomic-specific
optimization.

Inline asm is represented only for the observed source-backed barrier shape:
`call void asm sideeffect "...", "...~{memory}..."()`. The parser preserves the
template and constraint strings, records `sideeffect`, and marks `~{memory}` as
a memory clobber. It does not validate registers, constraints, outputs, native
lowering, or target-specific behavior.

The current source-backed captured row
`atomics_inline_asm_debug_release_fast` is accepted as optimizer input under the
barrier model. The reduced inline-asm and `atomicrmw` fixtures document the two
source-backed shapes from the same Zig source group.

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
  atomic_ordering_syncscope_preserve
  adce_atomic_barrier_reject
  gvn_atomic_load_barrier_reject
  early_cse_atomic_load_barrier_reject
  licm_atomic_store_barrier_reject
  dse_atomic_store_barrier_reject

unit tests:
  atomic load/store parse/print preservation
  atomicrmw/cmpxchg/fence parse/print preservation as side-effecting barriers
  reduced inline asm parse/print preservation as a side-effecting memory barrier
  syncscope preservation and malformed syncscope rejection
  invalid atomic ordering combination rejection
  LLVM verifier-shaped atomic access-size, `atomicrmw` operation/type, and
  `cmpxchg` operand-type rejection
  source-backed reduced inline-asm and atomicrmw fixtures from
  `atomics_inline_asm_debug_release_fast`
  memory-effect barrier classification
  DCE preservation for atomicrmw, cmpxchg, and fence
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
test/zig/expected/atomics_inline_asm_atomicrmw.reduced.ll
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
constraints, and memory clobbers. This project preserves supported ordering and
syncscope text, rejects invalid ordering/type combinations through
`Verifier.cpp`-shaped checks, and still treats accepted atomic forms as hard
optimizer barriers until the memory model and optimizer legality rules can match
LLVM's concurrency semantics. Pointer and vector-pointer atomic access-size
validation remains DataLayout-dependent and is documented as a local boundary.
