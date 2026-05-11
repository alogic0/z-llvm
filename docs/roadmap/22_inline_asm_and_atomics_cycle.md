# Cycle 22: Inline Assembly And Atomics

## Goal

Handle inline assembly and atomic operations as conservative optimization
barriers first, then add precise modeling only where Zig-emitted fixtures require
it.

## Source Anchors

- Corpus row: `atomics_inline_asm_debug_release_fast`
- LLVM IR: `call asm`, `atomicrmw`, `cmpxchg`, atomic load/store orderings
- Local code: `src/analysis/memory_effect.zig`,
  `src/analysis/alias.zig`, `src/ir/parser.zig`

## Plan

- [ ] Parse atomic load/store syntax as barrier-classified memory operations.
- [ ] Parse or explicitly reject `atomicrmw` and `cmpxchg`.
- [ ] Parse inline asm calls as unknown side-effecting calls.
- [ ] Preserve syncscope/orderings text where parsed.
- [ ] Add DCE, ADCE, GVN, EarlyCSE, LICM, and DSE rejection fixtures.
- [ ] Document which atomic transformations are deliberately not implemented.

## Exit Criteria

- [ ] Inline asm and atomics cannot be optimized across accidentally.
- [ ] Corpus atomic/asm blockers are classified.
- [ ] Unsupported atomic forms fail closed.

