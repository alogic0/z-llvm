# Cycle 18: Vector FP and Select Transform Boundary

## Goal

Define the safe boundary for vector FP, vector compares, and select transforms.

## Plan

- [ ] Inventory vector FP and select patterns in Zig-emitted rows and reduced
      fixtures.
- [ ] Extend FP legality helpers to vector element-wise queries where all lanes
      are supported.
- [ ] Add select simplification for scalar and vector conditions when poison and
      undef behavior is understood.
- [ ] Keep vectorization, SLP, loop vectorization, and target lowering out of
      scope.
- [ ] Add fixtures for vector fcmp, select, fast-math flags, lane constants,
      and rejected scalable or target-cost-sensitive cases.
- [ ] Compare equivalent transforms with `opt-22`.
- [ ] Update vector, select, FP, and target-cost docs.

## Exit Criteria

- [ ] The project has a documented vector FP transform boundary.
- [ ] At least one vector select or compare simplification is tested.
- [ ] Vectorization remains deferred and clearly separated.
