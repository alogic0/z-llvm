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

- [ ] Parse and preserve Zig-emitted global aliases.
- [ ] Extend global initializers beyond scalar constants only where the corpus
      requires it.
- [ ] Add global-as-value references for accepted load/store/call operands.
- [ ] Strengthen GlobalDCE root marking for aliases and referenced globals.
- [ ] Add conservative GlobalOpt and ConstantMerge placeholder docs for cases
      not implemented yet.
- [ ] Add `opt-22` fixtures for removable internal globals, live aliases, and
      initializer references.
- [ ] Promote a reduced globals/comptime corpus fixture to accepted optimizer
      input.

## Exit Criteria

- [ ] GlobalDCE handles aliases and initializer references conservatively.
- [ ] Global corpus blockers are classified by parser, verifier, or global pass
      owner.
- [ ] Unsupported global optimizations remain documented placeholders.

