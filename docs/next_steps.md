# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the first remaining Milestone 1 uncovered ReleaseFast x86_64 asm/object
blocker:
`test/distribution/releasefast_x86_64/inputs/switch_control_dense_switch.ll`.
The selected optimized-output shape has a switch-table load, indexed GEP, and
phi merge.

Zig evidence:
The fixture is reduced from
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir/switch_control.zig.ReleaseFast.x86_64.optimized.ll`,
emitted from `test/zig/inputs/switch_control.zig` in ReleaseFast mode. The
Milestone 1 manifest records the current blocker as
`UnsupportedCodegenControlFlow`.

LLVM fallback removed or reduced:
Add x86_64 asm/object support for the selected dense-switch shape. This reduces
the ReleaseFast x86_64 asm/object fallback within the named Milestone 1 subset
only; it does not claim broad switch lowering, global-data emission,
alias/export symbol emission, debug/unwind records, linker behavior, or
target-complete ABI lowering.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for selected subset`.

Upstream mapping:
Use LLVM x86_64 instruction selection for jump/value-table lowering, indexed
loads, compare/branch selection, and phi merge lowering as the reference
boundary:
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelDAGToDAG.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`.

Known boundary:
Implement only the selected dense-switch shape from
`switch_control_dense_switch.ll`. Do not generalize to arbitrary switch tables,
global initializers, relocations, stores, or branch probability metadata in this
slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh` and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
