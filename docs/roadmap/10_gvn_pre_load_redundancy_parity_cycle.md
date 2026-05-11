# Cycle 10: GVN PRE and Load Redundancy Parity

## Goal

Expand GVN from local redundancy toward LLVM-shaped load redundancy and a small
PRE subset.

## Plan

- [ ] Document the LLVM GVN entry points and data structures used for load PRE
      and scalar PRE.
- [ ] Add availability analysis for expressions across simple diamonds and loop
      preheaders.
- [ ] Use MemorySSA and alias queries for load redundancy instead of syntactic
      scans.
- [ ] Add fixtures for full redundancy, partial redundancy, clobbered loads,
      side exits, and unreachable stores.
- [ ] Keep speculative PRE disabled unless dominance, safety, and cost are
      proven.
- [ ] Compare equivalent fixtures with `opt-22`.
- [ ] Record local-only conservative differences in `docs/passes/gvn.md`.

## Exit Criteria

- [ ] GVN eliminates one non-local redundant scalar expression.
- [ ] GVN eliminates one non-local redundant load through MemorySSA legality.
- [ ] Unsafe PRE cases are rejected and tested.
