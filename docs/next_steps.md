# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 15: SROA slice partition builder

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `AllocaSlices`, `SliceBuilder`, partition iteration,
      `SROA::splitAlloca`, and `SROA::rewritePartition`.
- [x] Define the accepted local IR surface: entry-block aggregate allocas,
      constant struct/array GEPs, scalar integer or DataLayout-backed pointer
      fields, exact field/element ranges, and nonvolatile load/store users.
- [x] Replace the one-off aggregate GEP collection with an AllocaSlices-backed
      partition builder for fixed structs and arrays.
- [x] Use partitions to create replacement scalar allocas and rewrite exact
      field/element load/store users.
- [x] Keep partial overlaps, variable indexes, packed/vector aggregates,
      volatile/atomic accesses, memcpy/memmove, debug salvage, and full
      type-selection heuristics out of scope and documented.
- [x] Add or reuse `opt-22` comparison fixture coverage for the partitioned
      aggregate shape.
- [x] Update SROA, inventory, parity, and optimizer prerequisite docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 15 complete in the roadmap.
