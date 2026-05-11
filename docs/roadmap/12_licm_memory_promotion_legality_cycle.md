# Cycle 12: LICM Memory Promotion Legality

## Goal

Advance LICM from safe scalar hoisting toward memory promotion only when loop,
alias, and MemorySSA facts prove legality.

## Plan

- [ ] Inventory LLVM LICM memory-promotion requirements: preheader, latch,
      dedicated exits, must-execute, alias safety, and MemorySSA.
- [ ] Add loop helper APIs for must-execute and dedicated-exit checks if still
      missing.
- [ ] Enable hoisting of invariant loads only under MemorySSA and alias safety.
- [ ] Add a narrow scalar promotion case for stack locations with no escaping
      aliases and well-formed exits.
- [ ] Reject loops without preheaders, with side exits, with variant pointers,
      or with clobbering calls/stores.
- [ ] Add source-backed and reduced fixtures for accepted and rejected cases.
- [ ] Compare equivalent behavior against `opt-22`; document conservative gaps.

## Exit Criteria

- [ ] LICM performs one memory hoist or promotion backed by MemorySSA.
- [ ] Required loop canonical form is verified before the transform.
- [ ] Rejected memory LICM cases have explicit fixtures.
