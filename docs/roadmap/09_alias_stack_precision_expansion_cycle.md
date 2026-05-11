# Cycle 09: Alias Stack Precision Expansion

## Goal

Improve alias and ModRef precision for Zig-emitted pointer patterns without
overstating LLVM parity.

## Plan

- [ ] Inventory pointer patterns still blocking accepted corpus
      optimizations: alloca fields, GEP chains, byval, sret, noalias,
      dereferenceable, and alias metadata.
- [ ] Add structured memory-location decomposition for supported GEP and
      aggregate offsets.
- [ ] Extend alias results with must-alias, no-alias, partial-alias, and
      may-alias cases where size and offset are known.
- [ ] Wire function and call ModRef facts through the shared memory-effect API.
- [ ] Add fixtures for alias scopes, parameter attributes, disjoint fields,
      overlapping fields, and unknown calls.
- [ ] Compare equivalent cases against LLVM AA behavior where possible.
- [ ] Update alias, memory-location, memory-effect, and function-attrs docs.

## Exit Criteria

- [ ] At least one source-backed memory optimization becomes less conservative.
- [ ] Partial-overlap cases remain safe and tested.
- [ ] Alias precision docs identify unsupported LLVM AA providers.
