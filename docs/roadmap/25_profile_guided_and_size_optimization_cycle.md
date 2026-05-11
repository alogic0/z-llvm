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

- [ ] Inventory ReleaseSmall pipeline differences from Zig's LLVM backend.
- [ ] Parse size-related function attributes and metadata where emitted.
- [ ] Keep PGO metadata preserved but not interpreted until fixtures require it.
- [ ] Add ReleaseSmall corpus acceptance criteria separate from ReleaseFast.
- [ ] Document no-op placeholders for BFI/BPI-dependent passes.
- [ ] Add fixtures where size mode changes pass selection or legality.

## Exit Criteria

- [ ] ReleaseSmall blockers are classified independently.
- [ ] Size/PGO metadata does not get dropped accidentally.
- [ ] PGO-dependent optimizations remain honest placeholders.

