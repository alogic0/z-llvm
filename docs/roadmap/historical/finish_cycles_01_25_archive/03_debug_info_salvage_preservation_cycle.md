# Cycle 03: Debug Info Salvage Preservation

## Goal

Start transforming debug-bearing functions safely by preserving or invalidating
debug locations deliberately instead of disabling all useful optimization.

## Plan

- [x] Identify the first accepted Debug fixtures where scalar optimization is
      otherwise safe.
- [x] Add debug-location attachment preservation for instructions cloned,
      simplified, or removed by existing scalar passes.
- [x] Add a conservative rule for dropping stale variable-location intrinsics
      only when the referenced value is removed and cannot be salvaged.
- [x] Keep complex salvage expressions deferred unless a source-backed fixture
      requires them.
- [x] Add fixtures for DCE, InstSimplify, EarlyCSE, and GVN with debug
      locations.
- [x] Record differences from LLVM debug salvage behavior in pass docs.
- [x] Run opt-22 comparisons for cases expected to match and local-only checks
      for conservative differences.

## Exit Criteria

- [x] Scalar passes can run on selected debug-bearing fixtures.
- [x] No accepted transform leaves a dangling debug value reference.
- [x] Every conservative debug-info divergence is documented and tested.

## Completed Slice

Cycle 03 enables debug-location-only scalar fixtures for DCE, InstCombine,
EarlyCSE, and GVN. The local rule is conservative: unchanged or leader
instructions keep their `!dbg` attachment, removed instructions drop their
location, and modules containing `llvm.dbg.value` or `llvm.dbg.declare` still
skip transform passes until variable-location salvage exists.
