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
optimized-output capture: selected `@float_select` and `@float_add`
floating-point return lowering in
`floats_math.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
9 pass local object emission and 8 remain blocked. The newly closed row is
`float_compare.zig.ReleaseFast.x86_64.optimized.ll`, including `@float_mul` and
`@float_less`. The next sorted failure is
`floats_math.zig.ReleaseFast.x86_64.optimized.ll`, where the public aliases are
`@float_select = alias double (double, double, i1)` and
`@float_add = alias float (float, float)`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected
`floats_math` shapes. The source-backed optimized output contains a straight
line `fadd float` return and a `select i1` choosing between two double
arguments. This reduces the ReleaseFast x86_64 asm/object fallback for the next
broad optimized-output row only; it does not claim general floating-point
arithmetic, FP condition-code lowering, vector FP, libm, or target-complete ABI
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
Implement only the selected `@float_select` and `@float_add` shapes from the
`floats_math` optimized output. Do not generalize to other FP operations,
integer/FP casts, vector FP, x87, libm calls, TLS, or non-x86_64 ABI behavior in
this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
