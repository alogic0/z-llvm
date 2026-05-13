# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 32: Backend handoff validation for one optimized pattern

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map the LLVM handoff anchors: `opt`, `llc`, x86 instruction selection,
      asm printing, and ELF object emission.
- [x] Add one optimized scalar pattern that reaches local x86_64 assembly and
      object emission after local optimization.
- [x] Compare the optimized IR against `opt-22`.
- [x] Compare local object disassembly against `llc-22` object disassembly for
      the optimized pattern.
- [x] Keep the backend path documented as validation-only.
- [x] Run focused handoff validation.
- [x] Run readiness checks.
- [x] Review and commit Slice 32.
