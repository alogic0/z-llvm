# Cycle 6: GlobalDCE And Globals Graph Parity

## Goal

Move GlobalDCE toward LLVM's global dependency graph model for supported
functions, globals, aliases, constants, and comdat-like constraints.

## Source Anchors

- LLVM: `llvm/lib/Transforms/IPO/GlobalDCE.cpp`
- Related LLVM global passes: `GlobalOpt.cpp`, `ConstantMerge.cpp`
- Local docs: `docs/passes/globaldce.md`, `docs/analysis/call_graph.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [x] Add or document the LLVM GlobalDCE algorithm contract.
- [x] Represent references from global initializers and constants.
- [x] Build a global dependency graph for supported globals and functions.
- [x] Include aliases as graph roots or edges where locally represented.
- [x] Add conservative placeholders for ifunc and comdat behavior.
- [x] Delete only globals proven unreachable under local linkage rules.
- [x] Add fixtures for internal/private globals, exported aliases, constants,
      and referenced functions.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] GlobalDCE uses a graph rather than isolated symbol checks.
- [x] Alias/global references are not accidentally dropped.
- [x] Comdat/ifunc gaps are explicit and conservative.
- [x] Zig-emitted global fixtures drive the supported cases.

## Notes

Aliases, ifuncs, comdats, and aggregate constant initializers are not locally
represented yet. This cycle closes them by conservative placeholder policy:
when those IR forms are added, GlobalDCE must treat them as roots or graph
edges before deleting related globals.
