# Cycle 17: Vector Target-Cost and Lane Optimization

## Goal

Move vector lane operations from preservation-only toward safe, target-aware
scalar optimizer participation.

## Plan

- [ ] Define target-cost policy for vector lane operations on supported target
      triples.
- [ ] Reclassify pure vector lane operations so they are not modeled as memory
      barriers, while still preventing unsupported transforms.
- [ ] Add verifier and optimizer helpers for vector element types, lane counts,
      masks, and poison-sensitive behavior.
- [ ] Enable simple lane simplifications such as extract-after-insert when
      indices and values prove legality.
- [ ] Add fixtures for extract, insert, shuffle, poison/undef masks, and
      unsupported scalable vectors.
- [ ] Compare equivalent fixtures with `opt-22`.
- [ ] Update vector IR, target-cost, and memory-effect docs.

## Exit Criteria

- [ ] Dead pure vector lane operations can be removed when unused.
- [ ] At least one lane simplification matches LLVM for listed fixtures.
- [ ] Unsupported vector transforms remain explicitly rejected.
