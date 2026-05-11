# Cycle 16: MemorySSA And Alias Precision

## Goal

Replace the current linear clobber helper with a more LLVM-shaped memory access
model for accepted IR, without enabling unsafe memory optimizations.

## Source Anchors

- LLVM: `llvm/include/llvm/Analysis/MemorySSA.h`
- LLVM: `llvm/lib/Analysis/MemorySSA.cpp`
- LLVM: `llvm/lib/Analysis/BasicAliasAnalysis.cpp`
- Local code: `src/analysis/memory_ssa.zig`, `src/analysis/alias.zig`,
  `src/analysis/memory_location.zig`

## Plan

- [ ] Represent memory defs, uses, and simple join facts for accepted CFGs.
- [ ] Keep MemoryPhi support narrow and explicitly documented.
- [ ] Extend alias precision for stack objects, GEP offsets, and globals.
- [ ] Add MemorySSA-backed load availability checks for GVN and EarlyCSE.
- [ ] Add DSE overwrite queries only where direction and dominance are proven.
- [ ] Keep LICM memory movement disabled until this model proves loop safety.
- [ ] Compare conservative local results with `opt-22`.

## Exit Criteria

- [ ] GVN and EarlyCSE use the new memory access model for accepted cases.
- [ ] Existing volatile/atomic/unknown-call rejection fixtures still pass.
- [ ] MemorySSA limitations are documented beside tests.

