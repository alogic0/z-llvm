# Cycle 09: Alias Stack Precision Expansion

## Goal

Improve alias and ModRef precision for Zig-emitted pointer patterns without
overstating LLVM parity.

## Plan

- [x] Inventory pointer patterns still blocking accepted corpus
      optimizations: alloca fields, GEP chains, byval, sret, noalias,
      dereferenceable, and alias metadata.
- [x] Add structured memory-location decomposition for supported GEP and
      aggregate offsets.
- [x] Extend alias results with must-alias, no-alias, partial-alias, and
      may-alias cases where size and offset are known.
- [x] Wire function and call ModRef facts through the shared memory-effect API.
- [x] Add fixtures for alias scopes, parameter attributes, disjoint fields,
      overlapping fields, and unknown calls.
- [x] Compare equivalent cases against LLVM AA behavior where possible.
- [x] Update alias, memory-location, memory-effect, and function-attrs docs.

## Exit Criteria

- [x] At least one source-backed memory optimization becomes less conservative.
- [x] Partial-overlap cases remain safe and tested.
- [x] Alias precision docs identify unsupported LLVM AA providers.

## Completed Slice

Cycle 09 adds an explicit `partial_alias` result for known overlapping byte
ranges. Same-root locations with known disjoint ranges still return `no_alias`;
same-offset equal or unknown-size locations remain `must_alias`; known
overlapping but non-identical ranges now return `partial_alias`.

The new partial-overlap fixture keeps EarlyCSE conservative for overlapping
parameter GEP ranges, while the existing disjoint parameter-GEP fixture remains
the source-backed precision case.
