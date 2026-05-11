# Cycle 08: MemorySSA Updater and Phi Precision

## Goal

Move MemorySSA from a mostly query-time structure toward an updater-capable
analysis that can support transforms without full rebuilds.

## Plan

- [x] Inventory every current pass that mutates memory instructions after
      MemorySSA queries.
- [x] Add MemoryUse, MemoryDef, and MemoryPhi update operations for deletion,
      replacement, and simple block rewrites.
- [x] Add phi placement tests for diamonds, loops, side exits, and unreachable
      blocks.
- [x] Verify MemorySSA consistency after DSE, LICM, GVN, and EarlyCSE
      transforms that touch memory.
- [x] Keep complex CFG rewrites rebuilding MemorySSA until updater support is
      proven.
- [x] Document parity gaps against LLVM's `MemorySSAUpdater`.
- [x] Add a debug dump or test helper that makes clobber-chain expectations
      easy to assert.

## Exit Criteria

- [x] MemorySSA can be checked after at least one memory-mutating transform.
- [x] Phi precision improves one previously conservative fixture.
- [x] Rebuild-vs-update boundaries are explicit in docs.

## Completed Slice

Cycle 08 adds the first MemorySSA updater foundation:

- `deleteAccess` removes a MemoryUse/MemoryDef/barrier access after an
  instruction is deleted.
- `replaceInstructionAccess` updates an access kind/pointer for simple
  instruction replacement or inserts a new access for a newly memory-affecting
  instruction.
- `verifyConsistent` rebuilds and compares the local access list.
- `dump` prints deterministic access expectations for tests.
- DSE now verifies MemorySSA consistency after deleting stores.

Full LLVM `MemorySSAUpdater` parity, optimized-def recalculation, and CFG
renaming remain future work; complex CFG rewrites still rebuild MemorySSA.
