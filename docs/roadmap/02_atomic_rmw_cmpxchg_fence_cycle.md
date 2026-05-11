# Cycle 2: Atomic RMW, Cmpxchg, And Fence Representation

## Goal

Model the atomic forms Zig emits or may emit as conservative IR operations, so
the optimizer can preserve correctness before any precise atomic optimization is
attempted.

## Source Anchors

- Corpus row: `atomics_inline_asm_debug_release_fast`
- Reduced fixture: `atomics_inline_asm_atomicrmw_reduced`
- LLVM IR: `atomicrmw`, `cmpxchg`, `fence`, atomic orderings
- Local code: parser, verifier, memory-effect analysis

## Plan

- [x] Add narrow IR nodes or explicit barrier records for `atomicrmw`, `cmpxchg`,
      and `fence`.
- [x] Preserve ordering text and reject unsupported `syncscope` or malformed
      result shapes.
- [x] Classify accepted atomic operations as memory barriers for every
      memory-sensitive optimizer.
- [x] Add verifier rules for result type, pointer operand, value operand, and
      ordering presence.
- [x] Add opt fixtures that prove atomics are not deleted, folded, CSE'd, or
      moved.
- [x] Keep atomic lowering, target-specific lock-free behavior, and concurrency
      optimization out of scope.

## Exit Criteria

- [x] Source-backed atomic forms are either accepted as barriers or rejected with
      precise diagnostics.
- [x] Existing atomic load/store barrier behavior still passes.
- [x] Docs separate syntax support from semantic optimization support.

## Completed Slice

- Added conservative IR records for `atomicrmw`, `cmpxchg`, and `fence`.
- Preserved operation, ordering, volatility, pointer/value operands, and
      alignment where present.
- Classified accepted atomic forms as side-effecting memory barriers for DCE,
      ADCE, GVN, EarlyCSE, LICM, DSE, Mem2Reg, SROA, and MemorySSA scans.
- Promoted the source-backed atomic/inline-asm row to optimizer input under the
      barrier-only model.
- Kept syncscope, target lock-free lowering, and atomic optimization out of
      scope.
