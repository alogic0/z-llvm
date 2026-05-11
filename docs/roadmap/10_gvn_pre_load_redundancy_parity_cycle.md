# Cycle 10: GVN PRE and Load Redundancy Parity

## Goal

Expand GVN from local redundancy toward LLVM-shaped load redundancy and a small
PRE subset.

## Plan

- [x] Document the LLVM GVN entry points and data structures used for load PRE
      and scalar PRE.
- [x] Add availability analysis for expressions across simple diamonds and loop
      preheaders.
- [x] Use MemorySSA and alias queries for load redundancy instead of syntactic
      scans.
- [x] Add fixtures for full redundancy, partial redundancy, clobbered loads,
      side exits, and unreachable stores.
- [x] Keep speculative PRE disabled unless dominance, safety, and cost are
      proven.
- [x] Compare equivalent fixtures with `opt-22`.
- [x] Record local-only conservative differences in `docs/passes/gvn.md`.

## Exit Criteria

- [x] GVN eliminates one non-local redundant scalar expression.
- [x] GVN eliminates one non-local redundant load through MemorySSA legality.
- [x] Unsafe PRE cases are rejected and tested.

## Completed Slice

Cycle 10 documents and fixtures the current GVN availability boundary:

- non-local dominating scalar redundancy is eliminated;
- non-local load redundancy is eliminated when MemorySSA has no phi/clobber
  barrier on the path;
- scalar PRE remains disabled for partially available expressions.

This is still not LLVM load PRE. The local pass does not insert expressions,
split critical edges, or speculate computations.
