# Cycle 16: SimplifyCFG Canonical Shape Parity

## Goal

Improve CFG canonicalization for patterns that block downstream optimization.

## Plan

- [ ] Inventory missed SimplifyCFG deltas from accepted corpus rows.
- [ ] Add branch folding, empty-block threading, unreachable removal, and
      simple diamond select formation only where LLVM-equivalent.
- [ ] Preserve loop canonical shape required by loop passes.
- [ ] Keep switch lowering, jump tables, EH pads, and speculative threading
      deferred unless fixtures require them.
- [ ] Add fixtures for branches, diamonds, phis, unreachable blocks, loops, and
      side-effect guarded blocks.
- [ ] Compare equivalent fixtures with `opt-22`.
- [ ] Update SimplifyCFG, CFG, and pass-manager docs.

## Exit Criteria

- [ ] SimplifyCFG unlocks at least one downstream scalar optimization fixture.
- [ ] Loop, EH, and side-effect boundaries remain conservative.
- [ ] Pass ordering is documented for the affected pipeline.
