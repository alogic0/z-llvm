# Cycle 17: Vector Target-Cost and Lane Optimization

## Goal

Move vector lane operations from preservation-only toward safe, target-aware
scalar optimizer participation.

## Plan

- [x] Define target-cost policy for vector lane operations on supported target
      triples.
- [x] Reclassify pure vector lane operations so they are not modeled as memory
      barriers, while still preventing unsupported transforms.
- [x] Add verifier and optimizer helpers for vector element types, lane counts,
      masks, and poison-sensitive behavior.
- [x] Enable simple lane simplifications such as extract-after-insert when
      indices and values prove legality.
- [x] Add fixtures for extract, insert, shuffle, poison/undef masks, and
      unsupported scalable vectors.
- [x] Compare equivalent fixtures with `opt-22`.
- [x] Update vector IR, target-cost, and memory-effect docs.

## Exit Criteria

- [x] Dead pure vector lane operations can be removed when unused.
- [x] At least one lane simplification matches LLVM for listed fixtures.
- [x] Unsupported vector transforms remain explicitly rejected.

## Completed Slice

Cycle 17 classifies fixed-vector lane operations as pure instructions, allowing
DCE to remove unused extract/insert/shuffle operations. InstCombine now folds
`extractelement (insertelement V, X, C), C` to `X` for the same constant lane.
Vectorizers, scalable vectors, target-cost profitability, and target-dependent
vector combines remain deferred.

Post-audit closure:

- MemorySSA classifies fixed-vector `extractelement`, `insertelement`, and
  `shufflevector` as non-accesses rather than barriers.
- Alias ModRef reports fixed-vector lane operations as `NoModRef`.
- EarlyCSE local store availability no longer treats fixed-vector lane
  operations as store clobbers.
- GVN, EarlyCSE, and DSE fixtures cover the no-clobber behavior across vector
  lane operations.
