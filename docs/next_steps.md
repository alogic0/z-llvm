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
optimized-output capture: selected `@slice_sum` loop/control-flow lowering in
`aggregates.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` reports
`aggregates.zig.ReleaseFast.x86_64.optimized.ll` as the first sorted object
failure after the selected `aggregate_abi` i64 pair fixture. The first bounded
constant-select shape, `@error_union_payload`, is now covered. The next shape is
`@slice_sum = alias i32 (ptr, i64)`, which starts with an empty-slice branch and
then enters unrolled/epilogue loop control flow over readonly i32 payloads.

LLVM fallback removed or reduced:
Add the smallest x86_64 lowering needed for a selected bounded `@slice_sum`
shape, or reduce and document the first smaller loop/control-flow sub-shape if
the full unrolled loop is too broad for one cycle. This reduces the ReleaseFast
x86_64 asm/object fallback for the next broad optimized-output row only; it
does not claim general loop lowering, vectorization, arbitrary pointer
arithmetic, memory alias analysis, or target-complete ABI coverage.

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
Implement only the selected `@slice_sum` shape or one measured sub-shape from
the aggregates optimized output. Do not generalize to unrelated aggregate
functions, vectors, atomics, floating point, or non-x86_64 ABI behavior in this
slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
