# Cycle 1: Inline Asm IR Representation

## Goal

Represent source-backed `call asm` syntax explicitly enough to reject unsafe
optimization and preserve memory-clobber information, without implementing full
inline assembly lowering.

## Source Anchors

- Corpus row: `atomics_inline_asm_debug_release_fast`
- Reduced fixture: `atomics_inline_asm_inline_asm_reduced`
- LLVM IR: `call asm sideeffect`, constraint strings, memory clobbers
- Local docs: `docs/ir_atomics_inline_asm.md`, `docs/unsupported_ir.md`

## Plan

- [x] Add a narrow inline-asm call representation or explicit parser boundary
      that records side-effect and memory-clobber facts.
- [x] Verify inline asm calls are always side-effecting unless proven otherwise.
- [x] Treat inline asm memory clobbers as optimizer barriers in DCE, ADCE, GVN,
      EarlyCSE, LICM, and DSE.
- [x] Keep assembly constraint validation, register allocation, and native
      lowering out of scope.
- [x] Add source-backed accepted or rejected fixtures for the observed Zig form.
- [x] Document every unsupported inline asm feature separately from the accepted
      barrier model.

## Exit Criteria

- [x] Source-backed inline asm has an honest manifest classification.
- [x] Optimizer passes cannot delete or move across accepted side-effecting asm.
- [x] Unsupported asm forms fail closed with named tests.

## Completed Slice

- Added `InlineAsm` metadata on call instructions for the observed
      `call void asm sideeffect ..., "~{memory}..."()` form.
- Preserved template and constraint text, recorded `sideeffect`, and classified
      `~{memory}` as an optimizer memory barrier.
- Kept constraint validation, register allocation, native lowering, output
      constraints, and target-specific behavior unsupported.
- Added `inline_asm_barrier_preserve` as an `opt-22` comparison fixture.
