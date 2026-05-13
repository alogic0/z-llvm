# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 5: MemorySSA walker API for clobber queries

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `MemorySSA`, `MemoryUse`, `MemoryDef`, `MemoryPhi`,
      `MemorySSAWalker`, and `MemorySSAUpdater` entry points.
- [x] Define the accepted local IR surface: load/store/call/fence/atomic
      accesses, conservative MemoryPhi barriers, and CFG reachability-backed
      clobber queries.
- [x] Add a MemorySSA walker API that returns live-on-entry or the clobbering
      access for accepted queries.
- [x] Route existing clobber helpers through the walker-shaped API instead of
      direct block/instruction scans.
- [x] Add unit coverage for direct clobber, live-on-entry, and MemoryPhi
      clobber results.
- [x] Document why `opt-22` comparison is not direct for this analysis API:
      behavior is covered indirectly by existing EarlyCSE/GVN/DSE opt fixtures.
- [x] Update MemorySSA docs and the algorithm parity audit.
- [x] Run focused MemorySSA tests.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 5 complete in the roadmap.
