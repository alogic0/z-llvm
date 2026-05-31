# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the next measured ReleaseSafe x86_64 asm/object blocker: selected
`@error_switch` straight-line compare/select lowering from
`error_switch.zig.ReleaseSafe.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output object probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` is clean:
17 rows, 17 local object successes, 0 failures.

The next corrected-order probe captured ReleaseSafe optimized output at
`tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir`:
17 rows, 17 optimizer successes. Local object probing with
`--input-limit=67108864` originally found 8 object successes and 9 object
failures. The selected `aggregates.zig.ReleaseSafe.x86_64.optimized.ll`
blocker is now object-ok for `@slice_sum`, `@struct_sum`, and `@array_sum`
overflow-checked `llvm.sadd.with.overflow.i32` shapes with panic-edge
relocations. Focused validation for that closed slice is
`bash scripts/run_distribution_releasesafe_object_m2.sh`. The selected
`atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now
object-ok for `@debug_location`, `@inline_asm_barrier`, and `@atomic_add`; the
focused ReleaseSafe gate also covers the checked add-immediate shape. The
selected `control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll` blocker is
now object-ok for checked `@loop_sum` and guarded `@call_chain`; the focused
ReleaseSafe gate also covers both shapes. The current probe is 11 object
successes and 6 object failures.

The first sorted failure is now
`error_switch.zig.ReleaseSafe.x86_64.optimized.ll` with
`error: UnsupportedCodegenInstruction`. The selected public shape is
`@error_switch = alias i32 (i8), ptr @error_switch.error_switch`; the optimized
body is a one-block `icmp eq i8`, `icmp eq i8`, `select`, `select`, `ret`
canonical form.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected ReleaseSafe
`@error_switch` shape. This continues reducing the ReleaseSafe asm/object
fallback row for safety/runtime-call CFG shapes. It does not claim general
ReleaseSafe panic runtime lowering, arbitrary checked arithmetic, unwinding,
debug records, or target-complete ABI behavior.

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
Implement only the selected `@error_switch` ReleaseSafe shape from the
`error_switch` optimized output. Do not generalize to every compare/select
tree, arbitrary switch lowering, unwinding, debug/unwind object records, or
non-x86_64 ABI behavior in this slice.

Validation gate:
Add or extend the reduced ReleaseSafe fixture and run its focused
object/executable or object-structure gate, then rerun the ReleaseSafe object
probe over
`tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir` with
`--input-limit=67108864`. Also keep `bash scripts/run_handoff_validation.sh`
green.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
