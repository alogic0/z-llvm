# Cycle 18: Vector FP and Select Transform Boundary

## Goal

Define the safe boundary for vector FP, vector compares, and select transforms.

## Plan

- [x] Inventory vector FP and select patterns in Zig-emitted rows and reduced
      fixtures.
- [x] Keep FP legality helpers scalar-only for now and document vector FP
      transforms as deferred until APFloat lane semantics and cost policy are
      reproduced.
- [x] Add select simplification coverage for scalar `i1` conditions with
      identical vector arms; keep vector-condition selects deferred until poison
      and undef behavior is understood.
- [x] Keep vectorization, SLP, loop vectorization, and target lowering out of
      scope.
- [x] Add fixture coverage for the accepted vector select slice and retain
      rejected scalable, lane, and target-cost-sensitive cases from the vector
      boundary suite.
- [x] Compare equivalent transforms with `opt-22`.
- [x] Update vector, select, FP, and target-cost docs.

## Exit Criteria

- [x] The project has a documented vector FP transform boundary.
- [x] At least one vector select or compare simplification is tested.
- [x] Vectorization remains deferred and clearly separated.

## Completed Slice

- Added `vector_select_same_arms`, an `opt-22` equivalent fixture for
  `select i1 C, <N x T> V, <N x T> V -> V`.
- Documented that vector FP transforms, vector-condition selects, vector
  comparisons, vectorization, and TargetTransformInfo-style profitability remain
  out of scope.
