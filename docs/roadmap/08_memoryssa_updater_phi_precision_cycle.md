# Cycle 08: MemorySSA Updater and Phi Precision

## Goal

Move MemorySSA from a mostly query-time structure toward an updater-capable
analysis that can support transforms without full rebuilds.

## Plan

- [ ] Inventory every current pass that mutates memory instructions after
      MemorySSA queries.
- [ ] Add MemoryUse, MemoryDef, and MemoryPhi update operations for deletion,
      replacement, and simple block rewrites.
- [ ] Add phi placement tests for diamonds, loops, side exits, and unreachable
      blocks.
- [ ] Verify MemorySSA consistency after DSE, LICM, GVN, and EarlyCSE
      transforms that touch memory.
- [ ] Keep complex CFG rewrites rebuilding MemorySSA until updater support is
      proven.
- [ ] Document parity gaps against LLVM's `MemorySSAUpdater`.
- [ ] Add a debug dump or test helper that makes clobber-chain expectations
      easy to assert.

## Exit Criteria

- [ ] MemorySSA can be checked after at least one memory-mutating transform.
- [ ] Phi precision improves one previously conservative fixture.
- [ ] Rebuild-vs-update boundaries are explicit in docs.
