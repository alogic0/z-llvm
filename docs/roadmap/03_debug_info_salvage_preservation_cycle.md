# Cycle 03: Debug Info Salvage Preservation

## Goal

Start transforming debug-bearing functions safely by preserving or invalidating
debug locations deliberately instead of disabling all useful optimization.

## Plan

- [ ] Identify the first accepted Debug fixtures where scalar optimization is
      otherwise safe.
- [ ] Add debug-location attachment preservation for instructions cloned,
      simplified, or removed by existing scalar passes.
- [ ] Add a conservative rule for dropping stale variable-location intrinsics
      only when the referenced value is removed and cannot be salvaged.
- [ ] Keep complex salvage expressions deferred unless a source-backed fixture
      requires them.
- [ ] Add fixtures for DCE, InstSimplify, EarlyCSE, and GVN with debug
      locations.
- [ ] Record differences from LLVM debug salvage behavior in pass docs.
- [ ] Run opt-22 comparisons for cases expected to match and local-only checks
      for conservative differences.

## Exit Criteria

- [ ] Scalar passes can run on selected debug-bearing fixtures.
- [ ] No accepted transform leaves a dangling debug value reference.
- [ ] Every conservative debug-info divergence is documented and tested.
