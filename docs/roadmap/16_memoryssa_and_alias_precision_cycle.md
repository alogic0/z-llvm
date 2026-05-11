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

- [x] Represent memory defs, uses, and simple join facts for accepted CFGs.
- [x] Keep MemoryPhi support narrow and explicitly documented.
- [x] Extend alias precision for stack objects, GEP offsets, and globals.
- [x] Add MemorySSA-backed load availability checks for GVN and EarlyCSE.
- [x] Add DSE overwrite queries only where direction and dominance are proven.
- [x] Keep LICM memory movement disabled until this model proves loop safety.
- [x] Compare conservative local results with `opt-22`.

## Exit Criteria

- [x] GVN and EarlyCSE use the new memory access model for accepted cases.
- [x] Existing volatile/atomic/unknown-call rejection fixtures still pass.
- [x] MemorySSA limitations are documented beside tests.

## Completion Notes

- `src/analysis/memory_ssa.zig` now builds a persisted local access list with
  use/def/barrier entries plus narrow join facts for accepted CFGs.
- GVN and EarlyCSE route load availability through the local MemorySSA access
  model; DSE uses a centralized same-block overwrite query.
- Alias analysis now has module-aware global/alias root handling and uses
  module DataLayout when available.
- LICM memory motion remains disabled. The current model is a conservative
  access-list slice, not LLVM's full MemorySSA walker/updater.
