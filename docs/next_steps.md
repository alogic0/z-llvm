# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the next measured ReleaseSmall x86_64 asm/object blocker: selected
`@c_fopen` noreturn unreachable stub lowering from
`behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll`.

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
ReleaseSafe gate also covers both shapes. The selected
`error_switch.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok for
straight-line `@error_switch` compare/select lowering. The selected
`globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok
for `@comptime_const`, `@update_global`, and `@read_global`, covering checked
multiply-by-constant arithmetic, checked private `i32` global updates, global
load/store PC-relative relocations, and panic-edge relocations. The current
probe advanced to 13 object successes and 4 object failures. The selected
`pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok
for `@load_store`, covering checked pointer load/add/store lowering and
panic-edge relocations. The current probe is 14 object successes and 3 object
failures. The selected `switch_control.zig.ReleaseSafe.x86_64.optimized.ll`
blocker is now object-ok for `@branch_mix` and the already covered
`@dense_switch`, covering checked add-or-sub branch lowering and panic-edge
relocations. The current probe is 15 object successes and 2 object failures.
The selected `tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now
object-ok for `@add` and `@sideEffectFree`, covering checked scalar add
lowering and panic-edge relocations. The current probe is 16 object successes
and 1 object failure. The selected
`tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok
for `@bump_tls` and `@read_tls`, covering checked local-exec TLS update
lowering, `R_X86_64_TPOFF32` relocations, `.tdata`, executable TLS behavior,
and panic-edge relocations. The ReleaseSafe broad object probe is now clean:
17 object successes and 0 object failures.

The next corrected-order probe captured ReleaseSmall optimized output at
`tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir`:
1474 processed, 1009 compile skips, 465 optimizer successes, and 0 parse,
verify, optimizer, or input-size failures. Local object probing with
`--input-limit=67108864` found 263 object successes and 202 object failures.
The selected `behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll`
blocker is now object-ok for `@writeToVRam` and `@testPackedStuff`, covering
volatile absolute-address byte store lowering. The current ReleaseSmall object
probe is 264 object successes and 201 object failures.

The first sorted ReleaseSmall object failure is
`behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll` with
`error: UnsupportedCodegenControlFlow`. The first selected public shape is
`@c_fopen = alias ptr (ptr, ptr), ptr @sizeof_and_typeof.exp.c_fopen`; the
optimized body is a `noreturn` function whose only terminator is `unreachable`.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected ReleaseSmall
`@c_fopen` unreachable-stub shape. This continues reducing the ReleaseSmall
asm/object fallback row. It does not claim arbitrary trap lowering, panic
semantics, non-x86_64 ABI behavior, debug records, unwind records, linker
ownership, or target-complete ABI behavior.

Mode/target/stage row:
`mode=ReleaseSmall`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=LLVM fallback required`.

Upstream mapping:
Use LLVM x86_64 instruction selection and MC encoding behavior as the reference
boundary:
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`. For the selected
unreachable stub, also map against SelectionDAG terminator and unreachable
handling in
`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`.

Known boundary:
Implement only the selected `@c_fopen` ReleaseSmall unreachable-stub shape from
the `behavior_sizeof_and_typeof` optimized output. Do not generalize to
arbitrary trap lowering, panic semantics, debug/unwind object records, or
non-x86_64 ABI behavior in this slice.

Validation gate:
Add or extend a reduced ReleaseSmall fixture and run its focused
object-structure gate, then rerun the ReleaseSmall object probe over
`tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir` with
`--input-limit=67108864`. Also keep `bash scripts/run_handoff_validation.sh`
green.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
