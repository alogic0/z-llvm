# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Replacement goal:
Reduce the first `x86_64-linux-gnu` ReleaseFast asm/object LLVM fallback row by
adding one concrete accepted optimized-output shape to the local handoff or
asm/object validation subset.

Zig evidence:
`tmp/zig_ir/optimized_cfg_releasefast_20260530` captures normalized local
optimized output for CFG-sensitive ReleaseFast accepted rows. The broader clean
ReleaseFast accepted optimizer sweep is
`tmp/zig_ir/accepted_20260530_193848_releasefast`.

LLVM fallback removed or reduced:
unknown until the selected optimized-output shape is reduced. The expected
outcome is a bounded reduction of the ReleaseFast x86_64 asm/object fallback,
not broad backend parity.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=LLVM fallback required`.

Upstream mapping:
Start from LLVM x86_64 codegen/object emission for the selected shape:
`llvm-project-22/llvm/lib/Target/X86/`, `llvm-project-22/llvm/lib/CodeGen/`,
and `llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp`. Narrow this list before
marking the slice complete.

Known boundary:
The local x86_64 backend, assembly printer, and ELF writer are validation-only.
Do not implement broad register allocation, scheduling, debug/unwind records,
linker behavior, or target-complete ABI lowering in this slice.

Validation gate:
Run the smallest new handoff/codegen check for the selected shape, then
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the selected shape, fixture, docs, and validation
gate are complete.
