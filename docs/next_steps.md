# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 21: `constmerge` for identical private constants

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `ConstantMergePass::run`, `mergeConstants`,
      `isUnmergeableGlobal`, `IsBetterCanonical`, and `makeMergeable`.
- [x] Define the accepted local IR surface: local non-TLS scalar `constant`
      globals with `unnamed_addr`, matching type/initializer/attrs, and no
      COMDAT.
- [x] Merge duplicates into the later canonical private constant and rewrite
      accepted global value operands.
- [x] Reject non-constant globals, externally visible globals, TLS, COMDAT,
      aggregate initializers, non-unnamed constants, and mismatched attrs.
- [x] Add `opt-22` fixtures for an unnamed private scalar merge and a
      no-unnamed rejection boundary.
- [x] Wire `constmerge` as a real pass and update global cleanup docs,
      pipelines docs, parity docs, and roadmap status.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 21.
