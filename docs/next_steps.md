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
optimized-output capture: selected `@replace_low` and `@read_flag` i8 bit
lowering in `packed_bits.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
14 pass local object emission and 3 remain blocked. The newly closed row is
`integers.zig.ReleaseFast.x86_64.optimized.ll`, including `@add_wrap`,
`@cmp_select`, and `@shift_mix`. The next sorted failure is
`packed_bits.zig.ReleaseFast.x86_64.optimized.ll`, where the public aliases are
`@replace_low = alias i8 (i8, i8)` and `@read_flag = alias i1 (i8)`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected
`packed_bits` shapes. The source-backed optimized output masks and replaces the
low three bits of an i8 value, and reads the sign bit through `icmp slt i8 %0,
0`. This reduces the ReleaseFast x86_64 asm/object fallback for the next broad
optimized-output row only; it does not claim general sub-i32 lowering, arbitrary
bitfields, vectors, or target-complete ABI coverage.

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
Implement only the selected `@replace_low` and `@read_flag` shapes from the
`packed_bits` optimized output. Do not generalize to arbitrary sub-i32
operations, bitfield layout, vectors, TLS, floating point, or non-x86_64 ABI
behavior in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
