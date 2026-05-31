# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Start the next measured x86_64 asm/object row after the clean ReleaseFast
broad-capture gate: selected ReleaseSafe `@slice_sum` overflow-checked loop
lowering from `aggregates.zig.ReleaseSafe.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output object probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` is clean:
17 rows, 17 local object successes, 0 failures.

The next corrected-order probe captured ReleaseSafe optimized output at
`tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir`:
17 rows, 17 optimizer successes. Local object probing with
`--input-limit=67108864` found 8 object successes and 9 object failures. The
first sorted failure is `aggregates.zig.ReleaseSafe.x86_64.optimized.ll` with
`error: UnsupportedCodegenControlFlow`. The public selected shape is
`@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum`; the optimized
body contains an overflow-checked loop using `llvm.sadd.with.overflow.i32` and
a safety panic edge to
`debug.FullPanic((function 'defaultPanic')).integerOverflow`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected ReleaseSafe
`@slice_sum` shape. This begins reducing the ReleaseSafe asm/object fallback
row for safety/runtime-call CFG shapes. It does not claim general ReleaseSafe
panic runtime lowering, arbitrary checked arithmetic, unwinding, debug records,
or target-complete ABI behavior.

Mode/target/stage row:
`mode=ReleaseSafe`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=LLVM fallback required`.

Upstream mapping:
Use LLVM x86_64 calling-convention and instruction selection behavior as the
reference boundary:
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`. For the selected
safety edge, also map against LLVM IR overflow intrinsic handling in
`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`.

Known boundary:
Implement only the selected `@slice_sum` ReleaseSafe shape from the
`aggregates` optimized output. Do not generalize to every panic edge, every
overflow intrinsic, arbitrary loops, unwinding, debug/unwind object records,
or non-x86_64 ABI behavior in this slice.

Validation gate:
Add the reduced ReleaseSafe fixture and run its focused object/executable or
object-structure gate, then rerun the ReleaseSafe object probe over
`tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir` with
`--input-limit=67108864`. Also keep `bash scripts/run_handoff_validation.sh`
green.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
