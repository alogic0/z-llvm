# Cycle 5: Globals, Aliases, And Global Optimization

## Goal

Support the global IR surface Zig emits before local scalar optimization can
claim meaningful corpus coverage: aliases, global initializers, local global
load/store patterns, GlobalDCE roots, and conservative GlobalOpt placeholders.

## Source Anchors

- Corpus row: `globals_comptime_release_fast`
- Local code: `src/passes/globaldce.zig`, `src/analysis/call_graph.zig`,
  `src/ir/parser.zig`, `src/ir/verifier.zig`
- LLVM: `llvm/lib/Transforms/IPO/GlobalDCE.cpp`,
  `llvm/lib/Transforms/IPO/GlobalOpt.cpp`,
  `llvm/lib/Transforms/IPO/ConstantMerge.cpp`

## Plan

- [x] Parse and preserve Zig-emitted global aliases.
- [x] Extend global initializers beyond scalar constants only where the corpus
      requires it.
- [x] Add global-as-value references for accepted load/store/call operands.
- [x] Strengthen GlobalDCE root marking for aliases and referenced globals.
- [x] Add conservative GlobalOpt and ConstantMerge placeholder docs for cases
      not implemented yet.
- [x] Add `opt-22` fixtures for removable internal globals, live aliases, and
      initializer references.
- [x] Promote a reduced globals/comptime corpus fixture to accepted optimizer
      input.

## Exit Criteria

- [x] GlobalDCE handles aliases and initializer references conservatively.
- [x] Global corpus blockers are classified by parser, verifier, or global pass
      owner.
- [x] Unsupported global optimizations remain documented placeholders.

## Implementation Notes

- `src/ir/parser.zig` preserves global address attributes such as
  `unnamed_addr` before the global kind.
- Global pointer operands such as `ptr @globals_comptime.global_counter` are
  parsed as global-flavored named values and verify as conservative pointer
  operands.
- `src/passes/globaldce.zig` now treats exported aliases as roots and follows
  alias edges to target functions or globals.
- GlobalOpt, ConstantMerge, available-externally cleanup, and GlobalsAA remain
  executable placeholders documented in
  `docs/passes/global_cleanup_placeholders.md`.
- The raw `globals_comptime_release_fast` corpus row now parses, verifies, and
  runs through the local corpus pipeline.
