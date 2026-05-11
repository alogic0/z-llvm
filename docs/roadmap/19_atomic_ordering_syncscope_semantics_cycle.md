# Cycle 19: Atomic Ordering and SyncScope Semantics

## Goal

Model atomic ordering and syncscope enough to accept Zig atomic rows honestly
and keep optimizers correct.

## Plan

- [ ] Inventory atomic orderings, syncscopes, fences, cmpxchg, and atomicrmw
      forms emitted by Zig.
- [ ] Parse and preserve ordering and syncscope operands for supported atomic
      instructions.
- [ ] Add verifier checks for valid ordering combinations and result types.
- [ ] Classify atomics as barriers for existing scalar passes unless a precise
      transform is explicitly implemented.
- [ ] Add fixtures for monotonic, acquire, release, acq_rel, seq_cst, weak
      cmpxchg, fences, and unsupported forms.
- [ ] Document differences from LLVM's concurrency model.
- [ ] Compare parse/verify preservation with `opt-22 -S` where useful.

## Exit Criteria

- [ ] Atomic rows preserve ordering and syncscope text.
- [ ] Invalid atomic forms fail closed.
- [ ] Optimizer treatment remains conservative and explicit.
