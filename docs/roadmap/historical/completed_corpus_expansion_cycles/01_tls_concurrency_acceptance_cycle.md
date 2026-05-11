# Cycle 1: TLS Concurrency Acceptance

## Goal

Promote the new Zig-emitted TLS corpus row from parser acceptance to useful
optimizer and handoff validation while keeping backend-specific TLS lowering
out of scope.

## Source Anchors

- Corpus: `tls_concurrency_release_fast`
- Zig source: `test/zig/inputs/tls_concurrency.zig`
- Captured IR: `test/zig/captured/tls_concurrency.ReleaseFast.x86_64.ll`
- Local code: `src/ir/parser.zig`, `src/passes/globaldce.zig`,
  `src/analysis/memory_effect.zig`

## Plan

- [x] Add an opt fixture derived from the TLS corpus row for GlobalDCE root
      preservation.
- [x] Add a memory-effect fixture showing TLS loads/stores stay conservative
      across DCE, GVN, EarlyCSE, and DSE.
- [x] Document that TLS optimizer treatment is symbol/root preservation only,
      not native TLS lowering.
- [x] Compare matching local-conservative cases against `opt-22` where LLVM
      behavior is expected to match.
- [x] Keep codegen/object TLS relocation work deferred until a Zig-native
      backend handoff fixture requires it.

## Exit Criteria

- [x] `tls_concurrency_release_fast` remains `parse,verify,optimizer-input`.
- [x] TLS GlobalDCE and memory-effect behavior has named fixtures.
- [x] Docs separate optimizer legality from backend TLS lowering.

## Completion Notes

- Added `globaldce_tls_concurrency_root` from the captured TLS corpus shape.
- Added DCE, GVN, EarlyCSE, and DSE TLS memory legality fixtures.
- Kept GVN TLS clobber behavior marked `local-conservative`; the local goal is
  preserving correctness across thread-local memory, not matching every LLVM
  global optimization opportunity.
