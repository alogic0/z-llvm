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
optimized-output capture: selected `@bump_tls` and `@read_tls` thread-local i32
counter lowering in `tls_concurrency.zig.ReleaseFast.x86_64.optimized.ll`.

Zig evidence:
The broad ReleaseFast optimized-output probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now has 17 rows:
16 pass local object emission and 1 remains blocked. The newly closed row is
`pointers_memory.zig.ReleaseFast.x86_64.optimized.ll`, including
`@volatile_roundtrip` and `@load_store`. The next sorted failure is
`tls_concurrency.zig.ReleaseFast.x86_64.optimized.ll`, where the public aliases
are `@bump_tls = alias i32 (i32)` and `@read_tls = alias i32 ()`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected
`tls_concurrency` shapes. The source-backed optimized output contains a private
thread-local i32 initialized to `1`, a load/add/store bump path, and a load-only
read path. This reduces the final measured ReleaseFast x86_64 asm/object
fallback row in this optimized-output set; it does not claim general TLS model
coverage, dynamic TLS, cross-platform TLS relocations, atomics, or
target-complete ABI behavior.

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
Implement only the selected `@bump_tls` and `@read_tls` shapes from the
`tls_concurrency` optimized output. Do not generalize to arbitrary TLS models,
dynamic TLS, cross-target TLS relocations, vectors, floating point, or
non-x86_64 ABI behavior in this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh`,
`bash scripts/run_distribution_executable_m1.sh`, and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
