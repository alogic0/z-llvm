# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [x86_64 Distribution Replacement Matrix](roadmap/x86_64_distribution_replacement_matrix.md#first-fallback-row)

Replacement goal:
Reduce the first `x86_64-linux-gnu` ReleaseFast asm/object LLVM fallback row by
adding a validation fixture for one concrete accepted optimized-output shape:
`tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir/behavior_if.zig.ReleaseFast.x86_64.optimized.ll`.
That file is a metadata-only empty module after the ReleaseFast accepted
pipeline, so the missing capability is explicit x86_64 asm/object validation for
accepted optimized modules with no functions.

Zig evidence:
`tmp/zig_ir/optimized_cfg_releasefast_20260530` captures normalized local
optimized output for CFG-sensitive ReleaseFast accepted rows. The broader clean
ReleaseFast accepted optimizer sweep is
`tmp/zig_ir/accepted_20260530_193848_releasefast`. The selected source row is
`behavior/if.zig`, and its captured optimized output contains only
`source_filename`, target records, and empty module flags.

LLVM fallback removed or reduced:
This reduces the ReleaseFast x86_64 asm/object fallback by adding an explicit
handoff/codegen proof for an accepted optimizer output shape that currently has
no dedicated validation fixture. It does not remove broad backend parity,
debug/unwind object records, linker behavior, or target-complete ABI lowering.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=LLVM fallback required`.

Upstream mapping:
LLVM lowers an empty module through the normal target machine emission path
without function lowering. Use `llvm-project-22/llvm/lib/Target/X86/`,
`llvm-project-22/llvm/lib/CodeGen/AsmPrinter/AsmPrinter.cpp`,
`llvm-project-22/llvm/lib/MC/MCObjectStreamer.cpp`, and
`llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp` as the upstream source map for
the selected asm/object behavior.

Known boundary:
The local x86_64 backend, assembly printer, and ELF writer are validation-only.
Do not implement broad register allocation, scheduling, debug/unwind records,
linker behavior, or target-complete ABI lowering in this slice.

Validation gate:
Add the smallest handoff/codegen check for the selected empty optimized module,
covering `--emit=asm` and `--emit=obj` for `x86_64-unknown-linux-gnu`, then
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the selected shape, fixture, docs, and validation
gate are complete.
