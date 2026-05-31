# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the next ReleaseFast x86_64 asm/object blocker from the broader
optimized-output capture: selected `@debug_location` add-immediate lowering in
`atomics_inline_asm_debug.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now passes
`aggregate_abi.zig.ReleaseFast.x86_64.optimized.ll` and
`aggregates.zig.ReleaseFast.x86_64.optimized.ll`. The next sorted failure is
`atomics_inline_asm_debug.zig.ReleaseFast.x86_64.optimized.ll`; the first shape
is `@debug_location = alias i32 (i32)`, which returns `%0 + 1`.

LLVM fallback removed or reduced:
Add the smallest x86_64 lowering needed for selected i32 add-immediate returns.
This reduces the ReleaseFast x86_64 asm/object fallback for the next broad
optimized-output row only; it does not claim inline asm, atomicrmw, global data,
memory ordering, or target-complete ABI coverage.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for selected subset`.

Upstream mapping:
Use LLVM x86_64 calling-convention and instruction selection behavior as the
reference boundary:
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`.

Known boundary:
Implement only the selected `@debug_location` shape from the
atomics/inline-asm optimized output. Do not generalize to inline asm barriers,
atomic operations, global storage, vectors, floating point, or non-x86_64 ABI
behavior in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
