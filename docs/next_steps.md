# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [x86_64 Distribution Replacement Matrix](roadmap/x86_64_distribution_replacement_matrix.md#first-fallback-row)

No active slice. The empty-module ReleaseFast asm/object reduction is complete:
`test/handoff/inputs/releasefast_empty_module.ll` is tracked, local `--emit=asm`
produces empty assembly, local `--emit=obj` produces an x86_64 ELF relocatable
object, and `bash scripts/run_handoff_validation.sh` covers the fixture.
