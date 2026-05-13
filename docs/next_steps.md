# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 1: `always-inline` for direct internal calls

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map `AlwaysInliner` upstream entry points.
- [x] Define the accepted local IR surface: direct internal alwaysinline
      callees, direct calls only, no recursion, no varargs, no PHIs, no
      exceptional control flow.
- [x] Implement function body cloning for a single-block callee shape.
- [x] Implement argument substitution, local result renaming, and return
      replacement.
- [x] Preserve unsupported cases without marking the pass complete for those
      cases: PHIs, multiple blocks, multiple returns, recursive calls, varargs,
      indirect calls, noinline calls, and EH.
- [x] Add `opt-22` comparison fixtures for the positive direct-call case and
      the noinline rejection boundary.
- [x] Update pass docs and the algorithm parity audit.
- [x] Run focused comparison and readiness checks.
- [x] Review, commit, and mark Slice 1 complete in the roadmap.
