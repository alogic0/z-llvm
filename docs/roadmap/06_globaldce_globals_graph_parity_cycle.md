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

- [ ] Add or document the LLVM GlobalDCE algorithm contract.
- [ ] Represent references from global initializers and constants.
- [ ] Build a global dependency graph for supported globals and functions.
- [ ] Include aliases as graph roots or edges where locally represented.
- [ ] Add conservative placeholders for ifunc and comdat behavior.
- [ ] Delete only globals proven unreachable under local linkage rules.
- [ ] Add fixtures for internal/private globals, exported aliases, constants,
      and referenced functions.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] GlobalDCE uses a graph rather than isolated symbol checks.
- [ ] Alias/global references are not accidentally dropped.
- [ ] Comdat/ifunc gaps are explicit and conservative.
- [ ] Zig-emitted global fixtures drive the supported cases.

