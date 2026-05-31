# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Select the next measured x86_64 replacement task now that the top-level
no-LLVM-codegen distribution subset includes selected Debug asm/object
coverage. Start from the matrix: prefer the first remaining LLVM fallback row
that can be reduced by source-backed Zig evidence.

Zig evidence:
The continuous Debug prefix-400 object probe at
`tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir` originally
found 394 object successes and 6 object failures. The first failure was
`standalone_compile_asm_main.zig.Debug.x86_64.ll`, a selected Debug/O0
panic-unreachable shape. That shape is now object-ok through the tracked
fixture `test/distribution/debug_x86_64/inputs/compile_asm_panic_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. The refreshed prefix-400
probe is now:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/object_probe_summary_after_compile_asm.txt
total=400
ok=395
fail=5
excluded=0
first_failure=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
first_failure_category=unsupported-control-flow
```

`standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll` is the Debug/O0
sibling of the already documented ReleaseSmall float-format helper boundary:
the selected public shape is `@strFromFloatHelp -> @main.strFromFloatHelp`,
a large multi-block float-format helper rather than a defensible one-slice
object reduction. With that row excluded, the next first failure was
`standalone_issue_339_test.zig.Debug.x86_64.ll`. The selected public shape is
`@foo -> @test.foo`, a call to private `@test.bar`, an i16 zero check, a
success return edge, and a panic-only unwrap-error edge.

That selected issue-339 shape is now object-ok through the tracked fixture
`test/distribution/debug_x86_64/inputs/issue_339_error_success_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. The refreshed prefix-400
probe is now:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/object_probe_summary_after_issue339.txt
total=400
ok=396
fail=3
excluded=1
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=standalone_libfuzzer_main.zig.Debug.x86_64.ll
first_failure_category=unsupported-instruction
```

The selected libfuzzer Debug/O0 shape is now object-ok through the tracked
fixture `test/distribution/debug_x86_64/inputs/libfuzzer_runner_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. It covers the public
runner aliases for broadcast/futex/test-name/test-run, the O0 alloca,
`extractvalue`, `llvm.memcpy`, and `Build.abi.fuzz.Slice.fromSlice` slice
materialization sequence, and the external `fuzzer_*` call relocations. The
refreshed prefix-400 probe is now:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/object_probe_summary_after_libfuzzer.txt
total=400
ok=397
fail=2
excluded=1
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=standalone_load_dynamic_library_add.zig.Debug.x86_64.ll
first_failure_category=unsupported-control-flow
```

The selected dynamic-library `add` Debug/O0 shape is now object-ok through the
tracked fixture
`test/distribution/debug_x86_64/inputs/load_dynamic_library_add_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. It reuses the checked
two-argument `llvm.sadd.with.overflow.i32` lowering family for `@add ->
@add.add`, with the selected integer-overflow panic relocation preserved. The
refreshed prefix-400 probe is now:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/object_probe_summary_after_load_dynamic_add.txt
total=400
ok=398
fail=1
excluded=1
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=standalone_mix_c_files_main.zig.Debug.x86_64.ll
first_failure_category=unsupported-control-flow
```

The selected mix-C Debug/O0 shape is now object-ok through the tracked fixture
`test/distribution/debug_x86_64/inputs/mix_c_files_main_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. It covers `@add_zig`,
`@zig_k`, and `@add_may_panic`, including checked `llvm.sadd.with.overflow.i32`
success paths, `R_X86_64_TPOFF32` relocation use for the external `C_k`, the
negative-input `debug.defaultPanic` edge, and integer-overflow panic
relocations. The refreshed prefix-400 probe is now clean except for the already
documented float-format exclusion:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/object_probe_summary_after_mix_c_files.txt
total=400
ok=399
fail=0
excluded=1
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=-
first_failure_category=-
```

The next bounded probe used the full available continuous Debug object set.
The report has 465 optimizer-ok rows, so the requested first-500-row prefix
collapses to the full corpus at
`tmp/zig_ir/debug_object_probe_continuous_full465_20260531/ir`. The direct
probe found 462 object successes, 2 object failures, and the existing
float-format helper exclusion:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/object_probe_summary.txt
total=465
ok=462
fail=2
excluded=1
first_failure=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
first_failure_category=unsupported-control-flow
```

`standalone_mix_o_files_base64.zig.Debug.x86_64.ll` is the Debug/O0 sibling of
the documented ReleaseSmall table-decoder boundary. The selected public shape
is `@decode_base_64 = alias i64 (ptr, i64, ptr, i64), ptr
@base64.decode_base_64`; the body is a broad table-driven decoder with
multi-block loops, table constants, input/output pointer traversal, panic
edges, and error returns. That is not a defensible one-slice Debug backend
reduction, so the row is an explicit boundary exclusion for this Debug object
probe.

With the float-format helper and table-decoder rows excluded, the adjusted
full continuous Debug object probe is:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/object_probe_adjusted_summary.txt
total=465
ok=462
fail=1
excluded=2
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
excluded_row=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
excluded_reason=debug-table-decoder-boundary
first_failure=standalone_shared_library_mathtest.zig.Debug.x86_64.ll
first_failure_category=unsupported-control-flow
```

The selected `standalone_shared_library_mathtest.zig.Debug.x86_64.ll` public
shape is `@add = alias i32 (i32, i32), ptr @mathtest.add`, a Debug/O0
two-argument checked `llvm.sadd.with.overflow.i32` add with an integer-overflow
panic edge. That shape is now object-ok through the tracked fixture
`test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll` and
`bash scripts/run_distribution_debug_object_m4.sh`. The adjusted full
continuous Debug object probe is now clean for the captured subset:

```text
summary=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/object_probe_adjusted_summary_after_shared_library.txt
total=465
ok=463
fail=0
excluded=2
excluded_row=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
excluded_row=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
excluded_reason=debug-table-decoder-boundary
first_failure=-
first_failure_category=-
```

LLVM fallback removed or reduced:
Debug x86_64 asm/object fallback is reduced to a conservative captured-subset
boundary: 463 object-clean continuous Debug rows, with two explicit exclusions.

Mode/target/stage row:
Debug / x86_64-linux-gnu / asm-object is a conservative boundary for the
adjusted continuous 463-row subset. Debug outside that named subset remains an
LLVM fallback.

Upstream mapping:
LLVM owns this broad Debug/O0 object surface through the normal x86 target
CodeGen pipeline, including SelectionDAG/GlobalISel lowering, register
allocation, and ELF emission. The local replacement must only implement the
selected source-backed shape, not general Debug backend parity.

Known boundary:
DWARF/unwind emission, full O0 codegen, variable-location salvage,
target-complete ABI lowering, the Debug float-format helper, and the Debug
base64 table decoder remain outside this slice.

Validation gate:
Inspect the matrix, dashboard, and latest probe summaries. Promote exactly one
measured blocker or boundary closure into this file before implementation.

Commit:
Commit the gate update first, then commit the next selected task separately.

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
@main.zig_ret_u8`, a straight-line zero-extended u8 return. That focused
shape is now object-ok. The broad row still remains the first object failure;
the next selected public shape is `@zig_ret_bool = alias i1 (), ptr
@main.zig_ret_bool`, a straight-line boolean return. That focused shape is now
object-ok. The broad row still remains the first object failure; the next
selected public shape is `@zig_multiple_struct_floats = alias void (<2 x
float>, <2 x float>, <2 x float>, <2 x float>), ptr
@main.zig_multiple_struct_floats`, a vector-parameter floating comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges. The broad row still remains the first object failure; the next
selected public shape is `@zig_multiple_struct_ints = alias void (i64, i64,
i64, i64), ptr @main.zig_multiple_struct_ints`, a packed-integer comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges. The broad row still remains the first object failure; the next
selected public shape is `@zig_big_struct_both = alias void (ptr, ptr), ptr
@main.zig_big_struct_both`, a large byval/sret struct check-and-copy shape.
That focused shape is now object-ok with local trap failure edges and selected
sret stores. The broad row still remains the first object failure; the next
selected public shape is `@zig_split_struct_mixed = alias void (i64, i64), ptr
@main.zig_split_struct_mixed`, a split mixed integer/float comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges and an exact selected packed bit-pattern check for the mixed
integer/float register payload. The broad row still remains the first object
failure; the next selected public shape is `@zig_split_struct_ints = alias
void (i64, i64), ptr @main.zig_split_struct_ints`, a split integer struct
control-flow shape that checks a scalar first register and packed integer
fields in the second register. That focused shape is now object-ok with local
trap failure edges and an exact selected packed integer register payload check.
The broad row still remains the first object failure; the next selected public
shape is `@zig_big_packed_struct = alias void (i128), ptr
@main.zig_big_packed_struct`, a packed i128 struct control-flow shape that
checks low and high fields. That focused shape is now object-ok with local
trap failure edges and selected low/high register checks. The broad row still
remains the first object failure; the next selected public shape is
`@zig_small_packed_struct = alias void (i8), ptr
@main.zig_small_packed_struct`, a packed i8 struct control-flow shape with
masked sub-field checks and an unsigned high-bit comparison. That focused
shape is now object-ok with local trap failure edges and an exact selected
byte payload check. The broad row still remains the first object failure; the
next selected public shape is `@zig_med_struct_ints = alias void (i64, i32),
ptr @main.zig_med_struct_ints`, a medium integer struct control-flow shape
that checks packed fields across one 64-bit and one 32-bit argument register.
That focused shape is now object-ok with local trap failure edges and selected
packed integer register checks. The broad row still remains the first object
failure; the next selected public shape is `@zig_small_struct_ints = alias
void (i32), ptr @main.zig_small_struct_ints`, a small integer struct
control-flow shape that checks four packed byte fields in one 32-bit argument.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32 payload check. The broad row still remains the first
object failure; the next selected public shape is `@zig_med_struct_mixed =
alias void (i64, i64), ptr @main.zig_med_struct_mixed`, a medium mixed
integer/float struct control-flow shape. That focused shape is now object-ok
with local trap failure edges and selected packed mixed integer/float register
checks. The broad row still remains the first object failure; the next selected
public shape is `@zig_big_union = alias void (ptr), ptr @main.zig_big_union`,
a byval aggregate control-flow shape that checks fields from offsets 0, 8, 16,
24, and 32. That focused shape is now object-ok with local trap failure edges
and selected byval field-load checks. The broad row still remains the first
object failure; the next selected public shape is `@zig_big_struct = alias
void (ptr), ptr @main.zig_big_struct`, the sibling byval aggregate
control-flow shape over `%main.BigStruct`. That focused shape is now
object-ok with local trap failure edges and selected byval field-load checks.
The broad row still remains the first object failure; the next selected public
shape is `@zig_struct_i32_i32 = alias void (i64), ptr
@main.zig_struct_i32_i32`, a packed pair of i32 fields in one i64 argument.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32-pair register check. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_f32_f32f32 =
alias void (<2 x float>, float), ptr @main.zig_struct_f32_f32f32`, a
vector/scalar float struct control-flow shape. The alternate
`@zig_struct_f32f32_f32` alias maps to the same body. That focused shape is
now object-ok with local trap failure edges and selected vector/scalar float
register checks. The broad row still remains the first object failure; the
next selected public shape is `@zig_ret_struct_f32_f32f32 = alias { <2 x
float>, float } (), ptr @main.zig_ret_struct_f32_f32f32`, a vector/scalar
float struct return. The alternate `@zig_ret_struct_f32f32_f32` alias maps to
the same body. That focused shape is now object-ok for both public aliases with
selected `%xmm0`/`%xmm1` return materialization. The broad row still remains
the first object failure; the next selected public shape is
`@zig_struct_f32a8_f32a8 = alias void (<2 x float>, float, float), ptr
@main.zig_struct_f32a8_f32a8`, a vector/scalar float struct control-flow shape
with selected `3.125`, `4.375`, and `5.5` comparisons. That focused shape is
now object-ok with local trap failure edges and selected low-lane float
register checks. The broad row still remains the first object failure; the
next selected public shape is `@zig_ret_struct_f32a8_f32a8 = alias { <2 x
float>, float } (), ptr @main.zig_ret_struct_f32a8_f32a8`, a vector/scalar
float struct return with an undef second vector lane. That focused shape is now
object-ok with selected `%xmm0`/`%xmm1` return materialization while leaving
the undef vector lane unconstrained. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_f32a8 = alias
void (float, float), ptr @main.zig_struct_f32a8`, a two-scalar float
comparison control-flow shape. That focused shape is now object-ok with local
trap failure edges and selected low-lane float register checks. The broad row
still remains the first object failure; the next selected public shape is
`@zig_ret_struct_f32a8 = alias { float } (), ptr @main.zig_ret_struct_f32a8`,
a scalar float struct return shape. That focused shape is now object-ok with
selected `%xmm0` return materialization. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_f64 = alias
void (double), ptr @main.zig_struct_f64`, a scalar double comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges and a selected scalar double register check. The broad row still
remains the first object failure; the next selected public shape is
`@zig_ret_struct_f64 = alias { double } (), ptr @main.zig_ret_struct_f64`, a
scalar double struct return shape. That focused shape is now object-ok with
selected `%xmm0` return materialization. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_f32 = alias
void (float), ptr @main.zig_struct_f32`, a scalar float comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges and a selected scalar float register check. The broad row still
remains the first object failure; the next selected public shape is
`@zig_ret_struct_f32 = alias { float } (), ptr @main.zig_ret_struct_f32`, a
scalar float struct return shape. That focused shape is now object-ok with
selected `%xmm0` return materialization. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_u64_u64_8 =
alias void (i64, i64, i64, i64, i64, i64, i64, i64, ptr, i64), ptr
@main.zig_struct_u64_u64_8`, a byval two-u64 struct control-flow shape after
eight leading integer arguments. That focused shape is now object-ok with
selected stack argument loads, byval field loads, and local trap failure
edges. The broad row still remains the first object failure; the next selected
public shape is `@zig_struct_u64_u64_7 = alias void (i64, i64, i64, i64, i64,
i64, i64, ptr, i64), ptr @main.zig_struct_u64_u64_7`, a byval two-u64 struct
control-flow shape after seven leading integer arguments. That focused shape
is now object-ok with selected stack argument loads, byval field loads, and
local trap failure edges. The broad row still remains the first object
failure; the next selected public shape is `@zig_struct_u64_u64_6 = alias
void (i64, i64, i64, i64, i64, i64, ptr, i64), ptr
@main.zig_struct_u64_u64_6`, a byval two-u64 struct control-flow shape after
six leading integer arguments. That focused shape is now object-ok with
selected stack argument loads, byval field loads, and local trap failure
edges. The broad row still remains the first object failure; the next selected
public shape is `@zig_struct_u64_u64_5 = alias void (i64, i64, i64, i64, i64,
ptr, i64), ptr @main.zig_struct_u64_u64_5`, a byval two-u64 struct
control-flow shape after five leading integer arguments. That focused shape is
now object-ok with selected `%r9` byval field loads, stack argument load, and
local trap failure edges. The broad row still remains the first object
failure; the next selected public shape is `@zig_struct_u64_u64_4 = alias void
(i64, i64, i64, i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_4`, a split
u64 pair struct control-flow shape with the final field stack-passed. That
focused shape is now object-ok with selected register and stack argument
checks plus local trap failure edges. The broad row still remains the first
object failure; the next selected public shape is `@zig_struct_u64_u64_3 =
alias void (i64, i64, i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_3`, a
split u64 pair struct control-flow shape entirely in argument registers. That
focused shape is now object-ok with selected register checks and local trap
failure edges. The broad row still remains the first object failure; the next
selected public shape is `@zig_struct_u64_u64_2 = alias void (i64, i64, i64,
i64, i64), ptr @main.zig_struct_u64_u64_2`, a split u64 pair struct
control-flow shape entirely in argument registers. That focused shape is now
object-ok with selected register checks and local trap failure edges. The
broad row still remains the first object failure; the next selected public
shape is `@zig_struct_u64_u64_1 = alias void (i64, i64, i64, i64), ptr
@main.zig_struct_u64_u64_1`, a split u64 pair struct control-flow shape
entirely in argument registers. That focused shape is now object-ok with
selected register checks and local trap failure edges. The broad row still
remains the first object failure; the next selected public shape is
`@zig_struct_u64_u64_0 = alias void (i64, i64, i64), ptr
@main.zig_struct_u64_u64_0`, a split u64 pair struct control-flow shape
entirely in argument registers. That focused shape is now object-ok with
selected register checks and local trap failure edges. The broad row still
remains the first object failure; the next selected public shape is
`@zig_ret_struct_u64_u64 = alias { i64, i64 } (), ptr
@main.zig_ret_struct_u64_u64`, a two-register u64 pair return shape. That
focused shape is now object-ok with selected `%rax`/`%rdx` return
materialization. The broad row still remains the first object failure; the
next selected public shape is `@zig_struct_u64 = alias void (i64, i64), ptr
@main.zig_struct_u64`, a two-u64 control-flow shape. That focused shape is
now object-ok with selected register checks and local trap failure edges. The
broad row still remains the first object failure; the next selected public
shape is `@zig_ret_struct_u64 = alias i64 (), ptr @main.zig_ret_struct_u64`,
an i64 return shape. That focused shape is now object-ok with selected `%rax`
return materialization. The broad row still remains the first object failure;
the next selected public shape is `@zig_struct_u32 = alias void (i32, i64), ptr
@main.zig_struct_u32`, an i32/i64 control-flow shape. That focused shape is
now object-ok with selected i32/i64 register checks and local trap failure
edges. The broad row still remains the first object failure; the next selected
public shape is `@zig_ret_struct_u32 = alias i32 (), ptr
@main.zig_ret_struct_u32`, an i32 return shape. That focused shape is now
object-ok through existing straight-line i32 return lowering. The broad row
still remains the first object failure; the next selected public shape is
`@zig_struct_u16 = alias void (i16, i64), ptr @main.zig_struct_u16`, an
i16/i64 control-flow shape. That focused shape is now object-ok with selected
16-bit and 64-bit register checks plus local trap failure edges. The broad row
still remains the first object failure; the next selected public shape is
`@zig_ret_struct_u16 = alias i16 (), ptr @main.zig_ret_struct_u16`, an i16
return shape. That focused shape is now object-ok with selected `%eax` return
materialization. The broad row still remains the first object failure; the next
selected public shape is `@zig_struct_u8 = alias void (i8, i64), ptr
@main.zig_struct_u8`, an i8/i64 control-flow shape. That focused shape is now
object-ok with selected 8-bit and 64-bit register checks plus local trap
failure edges. The broad row still remains the first object failure; the next
selected public shape is `@zig_ret_struct_u8 = alias i8 (), ptr
@main.zig_ret_struct_u8`, an i8 return shape. That focused shape is now
object-ok with selected `%eax` return materialization. The broad row still
remains the first object failure; the next selected public shape is
`@zig_cmultd_comp = alias { double, double } (double, double, double, double),
ptr @main.zig_cmultd_comp`, a double-comparison control-flow shape returning
two doubles. That focused shape is now object-ok with selected `ucomisd`
comparisons and `%xmm0`/`%xmm1` return materialization. The broad row still
remains the first object failure; the next selected public shape is
`@zig_cmultf_comp = alias { <2 x float> } (float, float, float, float), ptr
@main.zig_cmultf_comp`, a float-comparison control-flow shape returning a
packed two-float vector. That focused shape is now object-ok with selected
low-lane float comparisons and packed `%xmm0` vector return materialization.
The broad row still remains the first object failure; the next selected public
shape is `@zig_cmultd = alias { double, double } (double, double, double,
double), ptr @main.zig_cmultd`, a double-comparison control-flow shape
returning two doubles. That focused shape is now object-ok through the shared
selected `ucomisd` comparison path. The broad row still remains the first
object failure; the next selected public shape is `@zig_cmultf = alias
{ <2 x float> } (<2 x float>, <2 x float>), ptr @main.zig_cmultf`, a
two-vector float comparison shape returning a packed two-float vector. That
focused shape is now object-ok with selected packed vector comparisons and
packed `%xmm0` return materialization. The broad row still remains the first
object failure; the next selected public shape is `@zig_bool = alias void
(i1), ptr @main.zig_bool`, an i1 branch-to-return-or-trap shape. That focused
shape is now object-ok with selected low-byte compare and local trap failure
edge. The broad row still remains the first object failure; the next selected
public shape is `@zig_ptr = alias void (ptr), ptr @main.zig_ptr`, a pointer
equality branch-to-return-or-trap shape. That focused shape is now object-ok
with selected 64-bit pointer compare and local trap failure edge. The broad row
still remains the first object failure; `@zig_longdouble` is a trivial void
return that is already object-ok through existing straight-line lowering. The
next selected public shape is `@zig_f64 = alias void (double), ptr
@main.zig_f64`, a double equality branch-to-return-or-trap shape. That
focused shape is now object-ok with selected `ucomisd` equality comparison and
local trap failure edge. The broad row still remains the first object failure;
the next selected public shape is `@zig_f32 = alias void (float), ptr
@main.zig_f32`, a float equality branch-to-return-or-trap shape. That focused
shape is now object-ok with selected `ucomiss` equality comparison and local
trap failure edge. The broad row still remains the first object failure; the
next selected public shape is `@zig_five_floats = alias void (float, float,
float, float, float), ptr @main.zig_five_floats`, a five-argument float
equality ladder ending in return-or-trap. That focused shape is now object-ok
with selected low-lane float comparisons through `%xmm4` and a local trap
failure edge. The broad row still remains the first object failure; the next
selected public shape is `@zig_struct_u128 = alias void (i64, i64), ptr
@main.zig_struct_u128`, a split u128 equality branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low/high i64 comparisons and
a local trap failure edge. The broad row still remains the first object
failure; the next selected public shape is `@zig_struct_i128 = alias void
(i64, i64), ptr @main.zig_struct_i128`, a split i128 equality
branch-to-return-or-trap shape. That focused shape is now object-ok with
selected low/high i64 comparisons and a local trap failure edge. The broad row
still remains the first object failure; the next selected public shape is
`@zig_i64 = alias void (i64), ptr @main.zig_i64`, an i64 equality
branch-to-return-or-trap shape. That focused shape is now object-ok with a
selected 64-bit argument comparison and a local trap failure edge. The broad
row still remains the first object failure; the next selected public shape is
`@zig_i32 = alias void (i32), ptr @main.zig_i32`, an i32 equality
branch-to-return-or-trap shape. That focused shape is now object-ok with a
selected 32-bit argument comparison and a local trap failure edge. The broad
row still remains the first object failure; the next selected public shape is
`@zig_i16 = alias void (i16), ptr @main.zig_i16`, an i16 equality
branch-to-return-or-trap shape. That focused shape is now object-ok with a
selected 16-bit argument comparison and a local trap failure edge. The broad
row still remains the first object failure; the next selected public shape is
`@zig_i8 = alias void (i8), ptr @main.zig_i8`, an i8 equality
branch-to-return-or-trap shape. That focused shape is now object-ok with a
selected 8-bit argument comparison and a local trap failure edge. The broad
row still remains the first object failure; the next selected public shape is
`@zig_u64 = alias void (i64), ptr @main.zig_u64`, a u64 equality
branch-to-return-or-trap shape. That focused shape is now object-ok through
the selected 64-bit scalar branch path. The broad row still remains the first
object failure; the next selected public shape is `@zig_u32 = alias void
(i32), ptr @main.zig_u32`, a u32 equality branch-to-return-or-trap shape. That focused shape is now object-ok through the selected 32-bit scalar branch path. The broad row still remains the first object failure; the next selected public shape is `@zig_u16 = alias void (i16), ptr @main.zig_u16`, a u16 equality branch-to-return-or-trap shape. That focused shape is now object-ok through the selected 16-bit scalar branch path. The broad row still remains the first object failure; the next selected public shape is `@zig_u8 = alias void (i8), ptr @main.zig_u8`, a u8 equality branch-to-return-or-trap shape. That focused shape is now object-ok through the selected 8-bit scalar branch path. The broad row still remains the first object failure; the next selected public shape is `@zig_five_integers = alias void (i32, i32, i32, i32, i32), ptr @main.zig_five_integers`, a five-argument integer equality ladder ending in return-or-trap. That focused shape is now object-ok with selected integer argument comparisons through `%r8d` and a local trap failure edge. The broad row still remains the first object failure; the next selected public shape is `@zig_panic = alias void (), ptr @main.zig_panic`, a noreturn panic stub ending in unreachable. That focused shape is now object-ok through a selected local `ud2` panic stub, and the broad `c_abi_main` row is object-clean. The current ReleaseSmall object probe is 266 object successes and 199 object failures. The next sorted failure is `cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll`; the selected public entry shape is `@_start = alias void (), ptr @start._start`, a naked startup inline-asm trampoline that calls `@start.posixCallMainAndExit` and ends in `unreachable`. That focused shape is now object-ok with selected startup trampoline lowering and an `R_X86_64_PLT32` relocation to `start.posixCallMainAndExit`. The current ReleaseSmall object probe is 327 object successes and 138 object failures. The actual next alias-target blocker in `cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll` is `@getauxval = weak_odr alias i64 (i64), ptr @os.linux.getauxvalImpl`; the selected auxv scan shape is now object-ok with a PC-relative load of `@os.linux.elf_aux_maybe` and a bounded tag/value loop. The current ReleaseSmall object probe is 455 object successes and 10 object failures. The next sorted failure is `cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll`; the selected public shape is `@elemPtr = alias void (), ptr @illegal_operation_on_logical_ptr.elemPtr`, an empty noreturn compile-error stub ending in `unreachable`. That focused shape is now object-ok through the selected `ud2` unreachable-stub path. The current ReleaseSmall object probe is 456 object successes and 9 object failures. The next sorted failure is `cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll`; the selected public shape is `@entry = alias i64 (), ptr @inherit_want_safety.entry`, an i64 constant return of `4`.

That focused `inherit_want_safety.entry` shape is now object-ok through
selected `%rax` constant return materialization. The current ReleaseSmall
object probe is 457 object successes and 8 object failures. The next sorted
failure is
`cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected public shape is `@entry = alias i64 (), ptr
@no_compile_panic_for_unchecked_arith.entry`, a straight-line
`llvm.umul.fix.sat.i64(i64 0, i64 2, i32 0)` call whose result is returned as
i64.

That focused `no_compile_panic_for_unchecked_arith.entry` shape is now
object-ok through selected `llvm.umul.fix.sat.i64` constant-call
materialization. The current ReleaseSmall object probe is 458 object successes
and 7 object failures. The next sorted failure is
`standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected public shape is `@main = alias void (i32, i32, i32), ptr
@main.main`, an empty noreturn function ending in `unreachable`.

That focused `main.main` shape is now object-ok through the selected `ud2`
unreachable-stub path. The current ReleaseSmall object probe is 459 object
successes and 6 object failures. The next sorted failure is
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected public shape is `@strFromFloatHelp = alias void (double), ptr
@main.strFromFloatHelp`, a large multi-block float-format helper with stack
locals, lifetime intrinsics, table loads, branches, and helper calls.

The `standalone_emit_llvm_no_bin_main` row is a documented ReleaseSmall
boundary exclusion for the current object subset: `@strFromFloatHelp` is a
large multi-block float-format helper and is not a defensible one-slice
backend reduction. A direct no-exclusion probe confirms the boundary:

```text
input=tmp/zig_ir/releasesmall_exclusion_emit_llvm_no_bin_20260531/ir
summary total=1 ok=0 fail=1 excluded=0
first_failure=standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
first_failure_category=unsupported-control-flow
selected_public_shape=@strFromFloatHelp -> @main.strFromFloatHelp
```

With that row excluded, the adjusted ReleaseSmall object probe found
`standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll` as the next
blocker. The selected `@getHidden` and `@updateHidden` shapes are now
object-ok for private i32 global load/store access through public function
aliases. The adjusted ReleaseSmall object probe is 460 object successes, 4
object failures, and 1 excluded row. The next sorted implementation failure is
`standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected public shape is `@_start = alias void (), ptr @main._start`, a
noreturn two-block infinite loop.

That focused `@main._start` shape is now object-ok through selected
unconditional self-branch lowering. The adjusted ReleaseSmall object probe is
461 object successes, 3 object failures, and 1 excluded row. The next sorted
implementation failure is
`standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll`; the selected
public shape is `@runner_futex_wait = alias i1 (ptr, i32), ptr
@main.runner_futex_wait`, a straight-line `ret i1 0`.

That focused `@runner_futex_wait` shape is now object-ok through selected
`i1` constant return materialization. The adjusted broad row still fails in
`standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll`, so the
adjusted ReleaseSmall object probe remains 461 object successes, 3 object
failures, and 1 excluded row. The next selected public shape in that row is
`@runner_test_name = alias { i64, i64 } (i32), ptr @main.runner_test_name`,
which returns `{ i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }` for the
`"test"` string.

That focused `@runner_test_name` shape is now object-ok through selected
PC-relative string-symbol address materialization and two-register aggregate
return lowering. The adjusted broad row still fails in
`standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll`, so the
adjusted ReleaseSmall object probe remains 461 object successes, 3 object
failures, and 1 excluded row. The next selected public shape in that row is
`@runner_test_run = alias void (i32), ptr @main.runner_test_run`, which calls
`@fuzzer_set_test`, two `@fuzzer_new_input` string/length pairs, and
`@fuzzer_start_test`.

That focused `@runner_test_run` shape is now object-ok through selected
libfuzzer runtime-call argument materialization, PC-relative function/string
addresses, PLT32 call relocations, and selected private string constants. The
adjusted ReleaseSmall object probe advanced to 462 object successes, 2 object
failures, and 1 excluded row. The next sorted implementation failure is
`standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected public shape is `@add_zig = alias i32 (i32), ptr @main.add_zig`,
which loads private Zig global `@main.zig_k`, adds the i32 argument, loads
external C global `@C_k`, adds it, and returns the result.

That focused `@add_zig` shape is now object-ok through selected private global
load, external TLS global add, and `R_X86_64_TPOFF32` relocation support. The
adjusted broad row still fails in
`standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll`, so the
adjusted ReleaseSmall object probe remains 462 object successes, 2 object
failures, and 1 excluded row. The next selected public shape in that row is
`@add_may_panic = alias i32 (i32), ptr @main.add_may_panic`, which branches on
`%0 < 0`, calls `@debug.defaultPanic` on the cold edge, and otherwise loads
`@main.zig_k`, adds the i32 argument, and returns the result.

That focused `@add_may_panic` shape is now object-ok through selected signed
negative branch lowering, panic-edge call relocation, selected panic string
data, and the existing private global add return path. The
`standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll` row is now
object-clean. The adjusted ReleaseSmall object probe advanced to 463 object
successes, 1 object failure, and 1 excluded row. The next sorted
implementation failure is
`standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected public shape is `@decode_base_64 = alias i64 (ptr, i64, ptr, i64),
ptr @base64.decode_base_64`, a large table-driven base64 decoder with
multi-block control flow, table constants, input/output pointer loops, and
error return paths.

The `standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll` row
is a documented boundary exclusion for the current ReleaseSmall object subset:
it is broad multi-block decoder/table lowering, not a defensible one-slice
backend reduction. A direct no-exclusion probe confirms the boundary:

```text
input=tmp/zig_ir/releasesmall_exclusion_mix_o_files_base64_20260531/ir
summary total=1 ok=0 fail=1 excluded=0
first_failure=standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
first_failure_category=unsupported-control-flow
selected_public_shape=@decode_base_64 -> @base64.decode_base_64
```

With that row and the existing
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`
float-format helper excluded, the adjusted ReleaseSmall object probe is clean:
463 object successes, 0 object failures, and 2 excluded rows. ReleaseSmall
asm/object is now a conservative boundary for the named captured subset.

The first named no-LLVM-codegen x86_64 distribution subset gate is now
`bash scripts/run_distribution_no_llvm_codegen_subset.sh`. It composes the
ReleaseFast object and executable gates, the ReleaseSafe object gate, the
selected ReleaseSmall object gate, the selected Debug object gate, and
`bash scripts/run_handoff_validation.sh`. The gate passed locally for
`TARGET=x86_64-unknown-linux-gnu`.

The bounded Debug x86_64 asm/object feasibility probe over
`test/zig/expected/debug_*.reduced.ll` originally found 2 object successes and
4 object failures. The first blocker was `debug_call_chain.reduced.ll`, a call
result plus immediate-add shape. After selected constant-add-after-call
lowering, debug intrinsic object no-ops, the reduced loop-sum lowerer, and the
selected scope-branch phi lowerer, the probe is clean: 6 object successes and
0 failures. The focused validation gate is
`bash scripts/run_distribution_debug_object_m4.sh`. Debug remains
`LLVM fallback required` for broad asm/object replacement; the new evidence is
a reduced conservative object subset, not DWARF/unwind or full O0 codegen
ownership.

Object-probe automation is now tracked as
`bash scripts/probe_distribution_objects.sh`. It emits stable per-row
ok/fail/excluded lines, first-failure data, and category counts. It reproduced
the current x86_64 release-mode object evidence:

```text
ReleaseFast  input=tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir
             summary total=17 ok=17 fail=0 excluded=0 first_failure=-
ReleaseSafe  input=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
             summary total=17 ok=17 fail=0 excluded=0 first_failure=-
ReleaseSmall input=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
             summary total=465 ok=463 fail=0 excluded=2 first_failure=-
             excluded=standalone_emit_llvm_no_bin_main float-format helper,
                      standalone_mix_o_files_base64 table decoder
```

The unified dashboard is
`docs/roadmap/x86_64_distribution_object_dashboard.md`. It records ReleaseFast
and ReleaseSafe as 17/17 object-clean captured subsets, ReleaseSmall as an
adjusted 463/465 object-clean subset with two explicit exclusions, and Debug as
a reduced 9-fixture object-clean subset plus selected broad raw and continuous
prefix object-clean rows while broad Debug std rows remain unproven.

The first broad Debug row from the fixture manifest,
`tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll`, originally failed before object
emission on Debug/O0 parser and verifier boundaries: LLVM `#dbg_declare`
records, `unreachable` and `ret` terminator metadata, sizeless
`DIBasicType`, and columnless `DILocation(line: 0, scope: ...)` nodes. Those
metadata forms are now accepted as conservative object-readiness boundaries,
and the selected `pointers_memory` row also closes the O0 alloca debug
prologue before volatile pointer roundtrip lowering. The selected broad raw
object probes are clean:

```text
input=tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir
summary total=1 ok=1 fail=0 excluded=0 first_failure=-
source=tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll

input=tmp/zig_ir/debug_object_probe_control_flow_calls_20260531/ir
summary total=1 ok=1 fail=0 excluded=0 first_failure=-
source=tmp/zig_ir/raw/control_flow_calls.Debug.ll

input=tmp/zig_ir/debug_object_probe_pointers_memory_20260531/ir
summary total=1 ok=1 fail=0 excluded=0 first_failure=-
source=tmp/zig_ir/raw/pointers_memory.Debug.ll

input=tmp/zig_ir/debug_object_probe_tiny_scalar_plain_20260531/ir
summary total=1 ok=1 fail=0 excluded=0 first_failure=-
source=tmp/zig_ir/raw/tiny_scalar.Debug.ll
```

The continuous Debug object probe now has a clean first-100-row prefix:

```text
input=tmp/zig_ir/debug_object_probe_continuous_prefix100_20260531/ir
summary total=100 ok=100 fail=0 excluded=0 first_failure=-
closed_boundary=behavior_sizeof_and_typeof Debug/O0 c_* panic-call unreachable stubs

input=tmp/zig_ir/debug_object_probe_continuous_prefix200_20260531/ir
summary total=200 ok=200 fail=0 excluded=0
first_failure=-
first_failure_category=-
closed_blockers=c_abi_main.zig.Debug.x86_64.ll,
                cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.Debug.x86_64.ll,
                cases_address_spaces_pointer_access_chaining_array_pointer.zig.Debug.x86_64.ll,
                cases_address_spaces_pointer_access_chaining_complex.zig.Debug.x86_64.ll,
                cases_address_spaces_pointer_access_chaining_struct_pointer.zig.Debug.x86_64.ll,
                cases_array_in_anon_struct.zig.Debug.x86_64.ll,
                cases_blocks.zig.Debug.x86_64.ll,
                cases_compile_errors_illegal_operation_on_logical_ptr.zig.Debug.x86_64.ll,
                cases_compile_errors_spirv_merge_logical_pointers.zig.Debug.x86_64.ll,
                cases_inherit_want_safety.zig.Debug.x86_64.ll,
                cases_no_compile_panic_for_unchecked_arith.zig.Debug.x86_64.ll

input=tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir
summary total=300 ok=300 fail=0 excluded=0
first_failure=-
first_failure_category=-
```

LLVM fallback removed or reduced:
The adjusted continuous Debug 465-row object probe is clean for 463 rows with
two explicit exclusions after the selected shared-library mathtest checked-add
slice. Keep broad Debug asm/object as LLVM fallback outside the named captured
subset.

Mode/target/stage row:
`mode=Debug`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for the adjusted continuous 463-row subset`.

Upstream mapping:
Use LLVM x86_64 Debug/O0 codegen, MC/object emission, diagnostics, and
object-file handoff behavior as the reference boundary:
`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`,
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`,
`llvm-project-22/llvm/lib/Target/X86/X86ISelLowering.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td`. For object-file
classification, also map MC/object emission, relocations, and debug-record
boundaries against `llvm-project-22/llvm/lib/Target/X86/X86MCInstLower.cpp` and
`llvm-project-22/llvm/lib/Target/X86/X86AsmPrinter.cpp`.

Known boundary:
Do not promote target-complete Debug asm/object. The conservative boundary
excludes DWARF/unwind emission, variable-location salvage, target-complete ABI
lowering, the float-format helper, and the base64 table decoder.

Validation gate:
Keep `bash scripts/run_distribution_debug_object_m4.sh`, the adjusted full
continuous Debug object probe, and
`bash scripts/run_distribution_no_llvm_codegen_subset.sh` green.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
