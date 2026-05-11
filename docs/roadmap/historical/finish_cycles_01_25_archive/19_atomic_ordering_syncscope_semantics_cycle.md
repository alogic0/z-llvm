# Cycle 19: Atomic Ordering and SyncScope Semantics

## Goal

Model atomic ordering and syncscope enough to accept Zig atomic rows honestly
and keep optimizers correct.

## Plan

- [x] Inventory atomic orderings, syncscopes, fences, cmpxchg, and atomicrmw
      forms emitted by Zig.
- [x] Parse and preserve ordering and syncscope operands for supported atomic
      instructions.
- [x] Add verifier checks for valid ordering combinations and supported atomic
      instruction forms.
- [x] Classify atomics as barriers for existing scalar passes unless a precise
      transform is explicitly implemented.
- [x] Add fixtures for monotonic, acquire, release, acq_rel, seq_cst, weak
      cmpxchg, fences, and unsupported forms.
- [x] Document differences from LLVM's concurrency model.
- [x] Compare parse/verify preservation with `opt-22 -S` where useful.

## Exit Criteria

- [x] Atomic rows preserve ordering and syncscope text.
- [x] Invalid atomic forms fail closed.
- [x] Optimizer treatment remains conservative and explicit.

## Completed Slice

- Added `syncscope("...")` preservation for atomic load/store, `atomicrmw`,
  `cmpxchg`, and `fence`.
- Added weak `cmpxchg` parsing/printing and verifier checks for load, store,
  RMW, cmpxchg, and fence ordering combinations.
- Added `atomic_ordering_syncscope_preserve` as an `opt-22` equivalent DCE
  fixture while keeping accepted atomics as hard memory barriers.
