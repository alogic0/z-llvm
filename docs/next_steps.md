# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 31: LTO prelink alias canonicalization

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `CanonicalizeAliases.cpp` recursive alias-chain flattening.
- [x] Replace the `canonicalize-aliases` placeholder with a real module pass.
- [x] Implement alias-to-alias target canonicalization for represented global
      aliases.
- [x] Keep constant-expression aliasee rewriting and full private anonymous
      value canonicalization documented as unsupported.
- [x] Add opt-equivalent fixture coverage for an alias chain.
- [x] Update LTO, parity, and roadmap docs.
- [x] Run focused alias canonicalization comparison/tests.
- [x] Run readiness checks.
- [x] Review and commit Slice 31.
