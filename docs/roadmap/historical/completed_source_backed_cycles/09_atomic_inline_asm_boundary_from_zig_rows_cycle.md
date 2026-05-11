# Cycle 9: Atomic And Inline-Asm Boundary From Zig Rows

## Goal

Revisit atomics and inline asm using real Zig-emitted rows, preserving the
fail-closed boundary while accepting any narrow source-backed syntax that can be
classified safely.

## Source Anchors

- Corpus row: `atomics_inline_asm_debug_release_fast`
- Docs: `docs/ir_atomics_inline_asm.md`, `docs/unsupported_ir.md`
- Local code: parser, memory-effect analysis, pass barrier handling
- LLVM IR: `atomicrmw`, `cmpxchg`, `fence`, `call asm`

## Plan

- [x] Reclassify the current atomic/inline-asm capture against the latest parser
      and memory-effect support.
- [x] Accept only syntax that can be represented as an explicit barrier without
      losing ordering or clobber information.
- [x] Keep `atomicrmw`, `cmpxchg`, `fence`, and inline asm rejected unless the
      representation can preserve their semantics.
- [x] Add source-backed reduced fixtures for each accepted or rejected form.
- [x] Compare barrier-preservation behavior with `opt-22` where the local model
      is intended to match.
- [x] Document every local-conservative difference from LLVM's richer atomic and
      inline-asm models.

## Exit Criteria

- [x] The atomic/inline-asm corpus row has an updated honest classification.
- [x] Accepted forms are optimizer barriers with named pass fixtures.
- [x] Unsupported forms fail closed with source-backed tests.

## Completed Slice

Cycle 9 reclassifies `atomics_inline_asm_debug_release_fast`: the current parser
now reaches the source-backed inline asm call and rejects it as
`UnsupportedInlineAsm`; `atomicrmw` remains a second source-backed blocker. The
slice adds reduced unsupported fixtures for both forms and keeps accepted atomic
load/store syntax limited to conservative optimizer barriers covered by the
existing pass fixture matrix.
