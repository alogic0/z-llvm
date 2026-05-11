# Cycle 25: Profile-Guided And Size Optimization

## Goal

Represent profile-guided and size-sensitive pipeline differences for Zig modes
without implementing broad PGO machinery prematurely.

## Source Anchors

- Zig optimization modes: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall
- LLVM: PGO instrumentation/use, BlockFrequencyInfo, BranchProbabilityInfo,
  size optimization pipelines
- Local docs: pass pipeline inventory and corpus manifest

## Plan

- [x] Inventory ReleaseSmall pipeline differences from Zig's LLVM backend.
- [x] Parse size-related function attributes and metadata where emitted.
- [x] Keep PGO metadata preserved but not interpreted until fixtures require it.
- [x] Add ReleaseSmall corpus acceptance criteria separate from ReleaseFast.
- [x] Document no-op placeholders for BFI/BPI-dependent passes.
- [x] Add fixtures where size mode changes pass selection or legality.

## Exit Criteria

- [x] ReleaseSmall blockers are classified independently.
- [x] Size/PGO metadata does not get dropped accidentally.
- [x] PGO-dependent optimizations remain honest placeholders.

## Completion Notes

- Added `docs/pgo_size_optimization.md` to separate ReleaseSmall corpus
  acceptance from full Oz/PGO behavior.
- Added no-op pipeline placeholders for BranchProbabilityInfo and
  BlockFrequencyInfo requirements.
- Added unit coverage for opaque `minsize`/`optsize` and branch profile
  metadata preservation.
- PGO instrumentation, profile-summary interpretation, BFI/BPI computation,
  and size-aware profitability remain unimplemented.
