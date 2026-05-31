# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the first Milestone 1 uncovered ReleaseFast x86_64 asm/object blocker:
`test/distribution/releasefast_x86_64/inputs/switch_control_branch_mix.ll`.
The selected optimized-output shape has a `select i1` result feeding integer
addition.

Zig evidence:
The fixture is reduced from
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir/switch_control.zig.ReleaseFast.x86_64.optimized.ll`,
emitted from `test/zig/inputs/switch_control.zig` in ReleaseFast mode. The
Milestone 1 manifest records the current blocker as
`UnsupportedCodegenInstruction`.

LLVM fallback removed or reduced:
Add x86_64 asm/object support for the selected `select`-feeding-arithmetic
shape. This reduces the ReleaseFast x86_64 asm/object fallback within the named
Milestone 1 subset only; it does not claim broad branch lowering, switch-table
lowering, alias/export symbol emission, debug/unwind records, linker behavior,
or target-complete ABI lowering.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for selected subset`.

Upstream mapping:
Use LLVM x86_64 instruction selection and conditional-move/branch lowering for
integer `select` as the reference boundary:
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelDAGToDAG.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`.

Known boundary:
Implement only the selected i32 arithmetic shape from
`switch_control_branch_mix.ll`. Do not generalize to arbitrary control flow,
phi lowering, switch tables, memory loads, globals, or branch probability
metadata in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh` and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
