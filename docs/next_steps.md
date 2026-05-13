# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 3: `correlated-propagation` for branch-implied integer facts

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map `CorrelatedValuePropagation` and `LazyValueInfo` upstream entry
      points.
- [x] Define the accepted local IR surface: dominating conditional branches on
      same-block integer `icmp` results comparing a named value with an integer
      constant.
- [x] Add a small LazyValueInfo-shaped fact table for edge-derived `icmp`
      predicates.
- [x] Implement `icmp` replacement when the fact table proves the comparison
      true or false at the instruction block.
- [x] Preserve unsupported cases without marking the pass complete for those
      cases: non-dominating edges, multi-predecessor edge targets, non-constant
      RHS, PHI/select/range reasoning, assumes, switches, overflow flags, and
      intrinsic handling.
- [x] Add `opt-22` comparison fixtures for positive branch-implied equality
      facts and unsupported no-fact preservation.
- [x] Update pass and analysis docs plus the algorithm parity audit.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 3 complete in the roadmap.
