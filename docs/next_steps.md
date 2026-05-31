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
optimized-output capture: selected i64 aggregate ABI lowering in
`aggregate_abi.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` reports
`aggregate_abi.zig.ReleaseFast.x86_64.optimized.ll` as the first sorted object
failure with `UnsupportedCodegenInstruction`. The fixture contains
`@pair_first = alias i32 (i64)` and `@make_pair = alias i64 (i32, i32)`.

LLVM fallback removed or reduced:
Add the smallest x86_64 lowering needed for the selected aggregate ABI shape:
`trunc i64 -> i32` return for `@pair_first`, and i64 zext/shift/or packing for
`@make_pair`. This reduces the ReleaseFast x86_64 asm/object fallback for the
next broad optimized-output row only; it does not claim general aggregate ABI,
struct returns, memory-passed aggregates, vector values, or target-complete ABI
coverage.

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
Implement only the two selected private functions in the aggregate ABI optimized
output. Do not generalize to arbitrary i64 arithmetic, memory aggregates,
multi-register returns, stack arguments, vectors, or non-x86_64 ABI behavior in
this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
