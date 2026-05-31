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
optimized-output capture: selected `@float_rem`, `@double_div`, and
`@float_sub` floating-point operation lowering in
`fp_extended_ops.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
11 pass local object emission and 6 remain blocked. The newly closed row is
`fp_constants.zig.ReleaseFast.x86_64.optimized.ll`, including
`@double_literal` and `@float_literal`. The next sorted failure is
`fp_extended_ops.zig.ReleaseFast.x86_64.optimized.ll`, where the public aliases
are `@float_rem = alias float (float, float)`,
`@double_div = alias double (double, double)`, and
`@float_sub = alias float (float, float)`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected
`fp_extended_ops` shapes. The source-backed optimized output contains straight
line `fsub float`, `fdiv double`, and `frem float` returns. This reduces the
ReleaseFast x86_64 asm/object fallback for the next broad optimized-output row
only; it does not claim general FP operation coverage, libm lowering beyond the
selected remainder shape, vector FP, x87, or target-complete ABI coverage.

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
Implement only the selected `@float_rem`, `@double_div`, and `@float_sub` shapes
from the `fp_extended_ops` optimized output. Do not generalize to other FP
operations, vector FP, x87, TLS, or non-x86_64 ABI behavior in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
