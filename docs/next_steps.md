# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 20: `globalopt` for internal constant globals

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `GlobalOptPass::run`, `OptimizeGlobalVars`,
      `processInternalGlobal`, and `CleanupConstantGlobalUsers`.
- [x] Define the accepted local IR surface: local non-TLS scalar `global`
      definitions with integer/FP/null/zero initializers and only direct
      non-volatile loads.
- [x] Replace eligible direct loads with the initializer value and delete the
      global when all accepted uses are removed.
- [x] Reject stores, calls, aliases, constant-expression pointer users,
      aggregate initializers, externally visible globals, COMDAT, and TLS.
- [x] Add `opt-22` fixtures for the positive scalar load cleanup and a
      store/address-taken rejection boundary.
- [x] Wire `globalopt` as a real pass and update global cleanup docs,
      pipelines docs, parity docs, and roadmap status.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 20.
