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

- [x] Parse atomic load/store syntax as barrier-classified memory operations.
- [x] Parse or explicitly reject `atomicrmw` and `cmpxchg`.
- [x] Parse or explicitly reject inline asm calls before optimization.
- [x] Preserve parsed atomic ordering text and reject unsupported syncscope.
- [x] Add a DCE opt fixture plus parser, memory-effect, and unit coverage for
      atomic/inline-asm barriers.
- [x] Document which atomic transformations are deliberately not implemented.

## Exit Criteria

- [x] Inline asm and atomics cannot be optimized across accidentally.
- [x] Corpus atomic/asm blockers are classified.
- [x] Unsupported atomic forms fail closed.

## Completion Notes

- Atomic load/store parsing and memory-effect barrier classification already
  existed; this cycle made the boundary explicit in docs and fixture metadata.
- Added explicit parser rejection for `fence` and inline asm calls, plus unit
  coverage for `cmpxchg`.
- Added `memory_atomic_barrier_reject` to the opt fixture table as a
  local-conservative DCE barrier fixture. Other pass coverage remains unit-level
  or policy-level until dedicated pass-specific atomic fixtures are needed.
- Inline asm remains rejected rather than modeled as an unknown call because
  constraints and memory clobbers are not represented yet.
