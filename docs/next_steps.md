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
optimized-output capture: selected `@volatile_roundtrip` and `@load_store`
pointer memory lowering in `pointers_memory.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
15 pass local object emission and 2 remain blocked. The newly closed row is
`packed_bits.zig.ReleaseFast.x86_64.optimized.ll`, including `@replace_low` and
`@read_flag`. The next sorted failure is
`pointers_memory.zig.ReleaseFast.x86_64.optimized.ll`, where the public aliases
are `@volatile_roundtrip = alias i32 (ptr, i32)` and
`@load_store = alias i32 (ptr, ptr)`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected
`pointers_memory` shapes. The source-backed optimized output contains a volatile
store/load roundtrip through a pointer argument and a non-volatile load/add/store
between two pointer arguments. This reduces the ReleaseFast x86_64 asm/object
fallback for the next broad optimized-output row only; it does not claim general
alias analysis, memory ordering, volatile completeness, aggregate memory, or
target-complete ABI coverage.

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
Implement only the selected `@volatile_roundtrip` and `@load_store` shapes from
the `pointers_memory` optimized output. Do not generalize to arbitrary pointer
memory, aliasing, volatile ordering, vectors, TLS, floating point, or non-x86_64
ABI behavior in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
