# Cycle 12: LICM Memory Promotion Legality

## Goal

Advance LICM from safe scalar hoisting toward memory promotion only when loop,
alias, and MemorySSA facts prove legality.

## Plan

- [x] Inventory LLVM LICM memory-promotion requirements: preheader, latch,
      dedicated exits, must-execute, alias safety, and MemorySSA.
- [x] Add loop helper APIs for must-execute and dedicated-exit checks if still
      missing.
- [x] Enable hoisting of invariant loads only under MemorySSA and alias safety.
- [x] Add a narrow scalar promotion case for stack locations with no escaping
      aliases and well-formed exits.
- [x] Reject loops without preheaders, with side exits, with variant pointers,
      or with clobbering calls/stores.
- [x] Add source-backed and reduced fixtures for accepted and rejected cases.
- [x] Compare equivalent behavior against `opt-22`; document conservative gaps.

## Exit Criteria

- [x] LICM performs one memory hoist or promotion backed by MemorySSA.
- [x] Required loop canonical form is verified before the transform.
- [x] Rejected memory LICM cases have explicit fixtures.

## Completed Slice

Cycle 12 records the current memory LICM boundary. The implementation hoists
invariant header loads to an existing preheader only when the pointer is loop
invariant and the loop body has no MemorySSA/alias clobber for that access.

Store promotion remains deferred. Rejection fixtures cover may-alias stores and
loop-variant load pointers.
