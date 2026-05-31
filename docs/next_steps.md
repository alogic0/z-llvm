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
`@zig_ret_u8` straight-line zero-extended u8 return lowering from
`c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll`.

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
probe is 264 object successes and 201 object failures. The selected
`behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll` blocker is
now object-ok for `@c_fopen`, `@c_ftell`, `@c_fputs`, and `@c_printf`,
covering selected noreturn unreachable-stub lowering. The current ReleaseSmall
object probe is 265 object successes and 200 object failures.

The first sorted ReleaseSmall object failure is
`c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll` with
`error: UnsupportedCodegenControlFlow`. The first selected public shape was
`@zig_f128_f128_struct = alias void (ptr, ptr), ptr
@main.zig_f128_f128_struct`; the optimized body uses an sret destination, a
byval fp128 struct input, `__eqtf2` comparison calls, panic branches, and
fp128 stores into the return buffer. That focused shape is now object-ok in
`bash scripts/run_distribution_releasesmall_object_m3.sh`. The broad
`c_abi_main` row remains the first object failure because the next selected
public shape was `@zig_f128_struct = alias { fp128 } (fp128), ptr
@main.zig_f128_struct`; its body compares an fp128 argument through `__eqtf2`,
returns `{ fp128 }` on the success edge, and traps on the panic edge. The
adjacent `@zig_f128 = alias fp128 (fp128), ptr @main.zig_f128` scalar fp128
return shape is also object-ok in the focused gate. The broad `c_abi_main` row
still remains the first object failure; the next selected public shape is
`@zig_assert_PD = alias i32 (i64, double), ptr @main.zig_assert_PD`, a mixed
integer/double assertion shape with stack local aggregate setup, floating-point
comparison, and a diagnostic failure edge. The focused gate now covers the
selected return-code branch behavior for that shape while leaving diagnostic
printing side effects outside the local replacement boundary. The broad
`c_abi_main` row still remains the first object failure; the next selected
public shape is `@zig_ret_PD = alias { i64, double } (), ptr
@main.zig_ret_PD`, a mixed integer/double aggregate return. That focused shape
is now object-ok. The broad `c_abi_main` row still remains the first object
failure; the next selected public shape is `@zig_ret_CFF = alias { i64, float
} (), ptr @main.zig_ret_CFF`, a mixed integer/float aggregate return. That
focused shape is now object-ok. The broad `c_abi_main` row still remains the
first object failure; the next selected public shape is `@zig_assert_CFF =
alias i32 (i64, float), ptr @main.zig_assert_CFF`, a mixed integer/float
assertion shape with floating-point comparison and diagnostic failure edge.
The focused gate now covers the selected return-code branch behavior for that
shape while leaving diagnostic printing side effects outside the local
replacement boundary. The broad `c_abi_main` row still remains the first
object failure; the next selected public shape is `@zig_ret_DC = alias {
double, i64 } (), ptr @main.zig_ret_DC`, a mixed double/integer aggregate
return. That focused shape is now object-ok. The broad `c_abi_main` row still
remains the first object failure; the next selected public shape is
`@zig_assert_DC = alias i32 (double, i64), ptr @main.zig_assert_DC`, a mixed
double/integer assertion shape with floating-point comparison, low-byte integer
comparison, and diagnostic failure edge. The focused gate now covers the
selected return-code branch behavior for that shape while leaving diagnostic
printing side effects outside the local replacement boundary. The broad
`c_abi_main` row still remains the first object failure; the next selected
public shape is `@zig_ret_split_struct_mixed = alias { i64, i64 } (), ptr
@main.zig_ret_split_struct_mixed`, a two-register aggregate return. That
focused shape is now object-ok. The broad `c_abi_main` row still remains the
first object failure; the next selected public shape is
`@zig_ret_med_struct_mixed = alias { i64, i64 } (), ptr
@main.zig_ret_med_struct_mixed`, another two-register aggregate return with
different constant bit patterns. That focused shape is now object-ok. The
broad `c_abi_main` row still remains the first object failure; the next
selected public shape is `@zig_ret_med_struct_ints = alias { i64, i32 } (),
ptr @main.zig_ret_med_struct_ints`, an integer aggregate return. That focused
shape is now object-ok. The broad `c_abi_main` row also advances past the
adjacent existing `@zig_ret_small_struct_ints` i32 return. The broad row still
remains the first object failure; the next selected public shape is
`@zig_ret_i64 = alias i64 (), ptr @main.zig_ret_i64`, a straight-line i64
return. That focused shape is now object-ok. The broad `c_abi_main` row also
advances past the adjacent existing `@zig_ret_i32` return. The broad row still
remains the first object failure; the next selected public shape is
`@zig_ret_i16 = alias i16 (), ptr @main.zig_ret_i16`, a straight-line i16
return. That focused shape is now object-ok. The broad row still remains the
first object failure; the next selected public shape is `@zig_ret_i8 = alias
i8 (), ptr @main.zig_ret_i8`, a straight-line i8 return. That focused shape
is now object-ok. The broad row still remains the first object failure; the
next selected public shape is `@zig_ret_u16 = alias i16 (), ptr
@main.zig_ret_u16`, a straight-line zero-extended u16 return. That focused
shape is now object-ok. The broad row still remains the first object failure;
the next selected public shape is `@zig_ret_u8 = alias i8 (), ptr
@main.zig_ret_u8`, a straight-line zero-extended u8 return.

LLVM fallback removed or reduced:
Add the smallest object/codegen support needed for the selected ReleaseSmall
`@zig_ret_u8` straight-line zero-extended u8 return shape. This continues
reducing the ReleaseSmall asm/object fallback row. It does not claim broad
scalar return coverage, non-x86_64 ABI behavior, debug records, unwind records,
linker ownership, or target-complete ABI behavior.

Mode/target/stage row:
`mode=ReleaseSmall`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=LLVM fallback required`.

Upstream mapping:
Use LLVM x86_64 instruction selection and MC encoding behavior as the reference
boundary:
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`. For the selected
straight-line zero-extended u8 return, also map against SelectionDAG integer
return and register assignment lowering in
`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`.

Known boundary:
Implement only the selected `@zig_ret_u8` ReleaseSmall straight-line
zero-extended u8 return shape from the `c_abi_main` optimized output. Do not
generalize to all scalar return attributes, debug/unwind object records, or
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
