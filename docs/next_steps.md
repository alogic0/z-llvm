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
optimized-output capture: selected `@loop_sum` multi-block unrolled loop
lowering in `control_flow_calls.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
6 pass local object emission and 11 remain blocked. The newly closed row is
`atomics_inline_asm_debug.zig.ReleaseFast.x86_64.optimized.ll`, including
`@debug_location`, `@inline_asm_barrier`, and `@atomic_add`. The next sorted
failure is `control_flow_calls.zig.ReleaseFast.x86_64.optimized.ll`, where
`@call_chain` is already covered by the selected fixture and `@loop_sum` is the
remaining uncovered public alias.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected unrolled
`@loop_sum` shape. The source-backed optimized output uses multi-block integer
loop control flow, PHIs, loop-carried accumulation, `llvm.assume` calls, and an
unrolled eight-at-a-time body with a scalar epilogue. This reduces the
ReleaseFast x86_64 asm/object fallback for the next broad optimized-output row
only; it does not claim general loop lowering, vector loops, arbitrary
intrinsics, register allocation, scheduling, or target-complete ABI coverage.

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
Implement only the selected `@loop_sum` shape from the `control_flow_calls`
optimized output. Do not generalize to other multi-block loops, arbitrary PHI
webs, indirect calls, vectors, floating point, TLS, or non-x86_64 ABI behavior
in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
