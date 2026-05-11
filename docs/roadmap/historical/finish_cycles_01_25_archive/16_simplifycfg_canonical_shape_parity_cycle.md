# Cycle 16: SimplifyCFG Canonical Shape Parity

## Goal

Improve CFG canonicalization for patterns that block downstream optimization.

## Plan

- [x] Inventory missed SimplifyCFG deltas from accepted corpus rows.
- [x] Add branch folding, empty-block threading, unreachable removal, and
      simple diamond select formation only where LLVM-equivalent.
- [x] Preserve loop canonical shape required by loop passes.
- [x] Keep switch lowering, jump tables, EH pads, and speculative threading
      deferred unless fixtures require them.
- [x] Add fixtures for branches, diamonds, phis, unreachable blocks, loops, and
      side-effect guarded blocks.
- [x] Compare equivalent fixtures with `opt-22`.
- [x] Update SimplifyCFG, CFG, and pass-manager docs.

## Exit Criteria

- [x] SimplifyCFG unlocks at least one downstream scalar optimization fixture.
- [x] Loop, EH, and side-effect boundaries remain conservative.
- [x] Pass ordering is documented for the affected pipeline.

## Completed Slice

Cycle 16 adds a strict empty-diamond select formation rule: two empty branch
arms that join at a single phi returned immediately can be folded to
`select`/`ret` in the predecessor. Loop-carried phis, side-effecting arms,
switches, EH pads, and speculative threading remain outside the local subset.
