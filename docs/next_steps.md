# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Replacement goal:
Add the next external IR-writer runtime surface after conditional branches,
phi/merge values, loops, dense-switch, mutable global update, i32 ABI-argument
direct-call, i64 call-return, local-exec TLS read/update, selected atomic add,
selected inline-asm memory barrier, selected small aggregate ABI, selected
float compare/multiply/add/select/subtract/divide/remainder/literal-return,
selected comptime constant multiply, selected add-immediate return,
ReleaseSafe checked add-immediate boundary, ReleaseSafe checked comptime
constant multiply boundary, ReleaseSafe checked global update boundary, pointer
load/store/volatile-roundtrip/optional-pointer, ReleaseSafe checked pointer
load/store boundary, ReleaseSafe checked branch-mix boundary, ReleaseSafe
checked call-chain boundary, ReleaseSafe checked TLS bump boundary, packed
bitfield, extern-struct field-load, scalarized array-sum, optional scalar
payload, error-union payload, pointer-indexed slice-sum, and selected
ReleaseSmall base64 decode/store/residual-byte/padding-byte/padding-loop and
padding length-adjustment, chunk-loop guard, source-byte stride, first three
four-byte source-bundle surfaces, bit-buffer combine/store,
loop-advance/backedge, residual/preheader guard, residual table-bundle, and
residual output store/backedge surfaces: a source-backed x86_64 ReleaseSmall
base64 residual padding-check row.

Zig evidence:
The completed `releasefast_runtime_cond_branch` and
`releasefast_runtime_phi_merge` rows are paired with
`test/zig/inputs/switch_control.zig`; `releasefast_runtime_loop_sum` is paired
with `test/zig/inputs/control_flow_calls.zig`; `releasefast_runtime_switch` is
paired with `test/zig/inputs/switch_control.zig`;
`releasefast_runtime_global_update` is paired with
`test/zig/inputs/globals_comptime.zig`; `releasefast_runtime_call_chain` is
paired with `test/zig/inputs/control_flow_calls.zig`;
`releasesmall_runtime_i64_call` is paired with
`test/zig/inputs/i64_arithmetic.zig`. The `releasefast_runtime_tls_read` and
`releasefast_runtime_tls_bump` rows cover selected local-exec TLS read/update
evidence. The `releasefast_runtime_atomic_add` row covers selected monotonic
atomic add evidence. The `releasefast_runtime_inline_asm_barrier` row covers
the selected side-effecting memory-barrier inline asm shape. The
`releasefast_runtime_aggregate_pair` row covers the selected two-i32 aggregate
ABI shape from `test/zig/inputs/aggregate_abi.zig`. The next source-backed
`releasefast_runtime_float_less` row covers the selected
`float_less(a: f32, b: f32) bool` family from
`test/zig/inputs/float_compare.zig`, and `releasefast_runtime_float_mul`
covers `float_mul(a: f64, b: f64) f64` from the same fixture. The next
`releasefast_runtime_float_add` and `releasefast_runtime_float_select` rows
cover `float_add(a: f32, b: f32) f32` and
`float_select(a: f64, b: f64, flag: bool) f64` from
`test/zig/inputs/floats_math.zig`. The completed
`releasefast_runtime_float_sub` and `releasefast_runtime_double_div` rows
cover `float_sub(a: f32, b: f32) f32` and
`double_div(a: f64, b: f64) f64` from
`test/zig/inputs/fp_extended_ops.zig`. The completed
`releasefast_runtime_float_rem` row uses the
same fixture's selected `float_rem(a: f32, b: f32) f32` family that appears in
captured ReleaseFast x86_64 IR and selected x86_64 FP object/codegen evidence.
The completed `releasefast_runtime_pointer_load_store` row is paired with
`pointers_memory.load_store(p: *i32, q: *i32) i32` from
`test/zig/inputs/pointers_memory.zig`, which exercises a pointer load, integer
add, pointer store, and re-load through the external writer path.
The completed `releasefast_runtime_volatile_roundtrip` row from the same
fixture is `pointers_memory.volatile_roundtrip(p: *volatile i32, value: i32)
i32`, which exercises selected volatile store/load preservation through the
external writer path.
The completed `releasefast_runtime_optional_pointer` row is paired with
`optional_pointer.optional_ptr_value(p: ?*const i32) i32` from
`test/zig/inputs/optional_pointer.zig`, which exercises pointer null-check
control flow and a selected non-null `i32` load.
The completed `releasefast_runtime_packed_read_flag` row is paired with
`packed_bits.read_flag(raw: u8) bool` from
`test/zig/inputs/packed_bits.zig`, which exercises selected packed-bitfield
read/bit-test behavior.
The completed `releasefast_runtime_packed_replace_low` row from the same
fixture is `packed_bits.replace_low(raw: u8, value: u8) u8`, which exercises
selected packed low-bit replacement with mask/or integer operations.
The completed `releasefast_runtime_struct_sum` row is paired with
`aggregates.struct_sum(pair: *const Pair) i32` from
`test/zig/inputs/aggregates.zig`, which exercises two `i32` field loads from
an extern struct pointer and a scalar add. The completed
`aggregates.array_sum(a: i32, b: i32, c: i32) i32` from the same fixture,
which appears in captured ReleaseFast x86_64 IR as a scalarized
three-argument add chain, is now covered by
`releasefast_runtime_array_sum`. The next source-backed shape is
`aggregates.optional_payload(flag: i32, value: i32) i32` from the same fixture,
which appears in captured ReleaseFast x86_64 IR as an `icmp eq` and `select`
over a scalar optional payload and is now covered by
`releasefast_runtime_optional_payload`. The next source-backed shape is
`aggregates.error_union_payload(flag: i32) i32`, which appears in captured
ReleaseFast x86_64 IR as an `icmp eq` and `select` over the success payload
and catch fallback and is now covered by
`releasefast_runtime_error_union_payload`. The next source-backed shape is
`aggregates.slice_sum(ptr: [*]const i32, len: usize) i32`, which appears in
captured ReleaseFast x86_64 IR as a loop with phi values, indexed GEP, `i32`
load, add, and loop-exit branch and is now covered by
`releasefast_runtime_slice_sum`. The next source-backed shape is
`fp_constants.float_literal() f32` / `fp_constants.double_literal() f64`,
which appears in captured ReleaseFast x86_64 IR as direct `ret float` and
`ret double` constants and is now covered by
`releasefast_runtime_fp_constants`. The next source-backed shape is
`globals_comptime.comptime_const(value: i32) i32`, which appears in captured
ReleaseFast x86_64 IR as an `i32` multiply by the comptime-known scale value
and is now covered by `releasefast_runtime_comptime_const`. The next
source-backed shape is
`atomics_inline_asm_debug.debug_location(value: i32) i32`, which appears in
captured ReleaseFast x86_64 IR as selected `add nsw i32 %0, 1` plus a direct
return and is now covered by `releasefast_runtime_debug_location`. The next
source-backed shape is
`atomics_inline_asm_debug.debug_location(value: i32) i32` under ReleaseSafe,
which appears in captured ReleaseSafe x86_64 IR as `llvm.sadd.with.overflow`
plus an integer-overflow panic edge and is now covered by
`releasesafe_runtime_debug_location`. The next source-backed shape is
`globals_comptime.comptime_const(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as checked multiply-by-five with an
integer-overflow panic edge and is now covered by
`releasesafe_runtime_comptime_const`. The next source-backed shape is
`globals_comptime.update_global(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as a private `i32` global load,
checked add with `llvm.sadd.with.overflow.i32`, overflow branch to the same
integer-overflow panic edge, non-overflow store back to the private global,
and returned updated value and is now covered by
`releasesafe_runtime_global_update`. The next source-backed shape is
`pointers_memory.load_store(p: *i32, q: *i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as an `i32` pointer load, checked
add-one with `llvm.sadd.with.overflow.i32`, overflow branch to the same
integer-overflow panic edge, non-overflow pointer store, and returned updated
value and is now covered by `releasesafe_runtime_pointer_load_store`. The
next source-backed shape is `switch_control.branch_mix(a: i32, b: i32, flag:
bool) i32` under ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR
as a flag branch, checked add path, checked subtract path, merge phi, and two
integer-overflow panic edges and is now covered by
`releasesafe_runtime_branch_mix`. The next source-backed shape is
`control_flow_calls.call_chain(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as a selected checked callee-range
guard followed by `shl nsw` and `or` result construction and is now covered
by `releasesafe_runtime_call_chain`. The next source-backed shape is
`tls_concurrency.bump_tls(value: i32) i32` under ReleaseSafe, which appears in
captured ReleaseSafe x86_64 IR as a local-exec TLS load, checked add with
`llvm.sadd.with.overflow.i32`, overflow panic edge, TLS store, and returned
updated value and is now covered by `releasesafe_runtime_tls_bump`. The next
source-backed shape is `aggregates.array_sum(a: i32, b: i32, c: i32) i32`
under ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR as two
checked `llvm.sadd.with.overflow.i32` operations and two integer-overflow
panic edges and is now covered by `releasesafe_runtime_array_sum`. The next
source-backed shape is `aggregates.struct_sum(pair: *const Pair) i32` under
ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR as two `i32`
field loads, one checked `llvm.sadd.with.overflow.i32` operation, and one
integer-overflow panic edge and is now covered by
`releasesafe_runtime_struct_sum`. The next source-backed shape is
`aggregates.slice_sum(ptr: [*]const i32, len: usize) i32` under ReleaseSafe,
which appears in captured ReleaseSafe x86_64 IR as a loop with phi values,
indexed GEP/load, checked `llvm.sadd.with.overflow.i32` operation in the loop
body, and an integer-overflow panic edge and is now covered by
`releasesafe_runtime_slice_sum`. The next source-backed shape is
`control_flow_calls.loop_sum(count: i32) i32` under ReleaseSafe, which appears
in captured ReleaseSafe x86_64 IR as a counted loop with phi values, checked
`llvm.sadd.with.overflow.i32` operations, integer-overflow panic edges, and
the selected integer-out-of-bounds panic edge and is now covered by
`releasesafe_runtime_loop_sum`. The next source-backed shape is
`globals_comptime.read_global() i32` under ReleaseSafe, which appears in
captured ReleaseSafe x86_64 IR as a private global `i32` load and direct
return through the ReleaseSafe accepted pipeline and is now covered by
`releasesafe_runtime_read_global`. The next source-backed shape is
`tls_concurrency.read_tls() i32` under ReleaseSafe, which appears in captured
ReleaseSafe x86_64 IR as a direct local-exec TLS `i32` load and return and
is now covered by `releasesafe_runtime_tls_read`. The next source-backed
shape is `tiny_scalar.sideEffectFree() void` under ReleaseSafe, which appears
in captured ReleaseSafe x86_64 IR as a private void function with a direct
`ret void` and is now covered by
`releasesafe_runtime_side_effect_free`. The next source-backed shape is the
ReleaseSmall `standalone_extern_exports_hidden_access` row, which exposes a
private hidden `i32` global through `getHidden() i32` and
`updateHidden(value: i32) void` aliases and is now covered by
`releasesmall_runtime_hidden_access`. The next source-backed shape is the
ReleaseSmall `standalone_mix_c_files_add_zig` row, which loads Zig-owned
`main.zig_k`, combines it with an argument, then combines that value with a
C-owned TLS `C_k` input and is now covered by
`releasesmall_runtime_mix_c_add_zig`. The next source-backed shape is the
ReleaseSmall `standalone_mix_c_files_add_may_panic` row, which branches on a
negative argument, calls the selected panic runtime edge on that path, and
otherwise loads `main.zig_k`, adds the non-negative argument, and returns the
sum and is now covered by `releasesmall_runtime_mix_c_add_may_panic`. The
next source-backed shape is the ReleaseSmall
`no_compile_panic_for_unchecked_arith_umul_fix_sat_i64` row, which calls
`llvm.umul.fix.sat.i64(i64 0, i64 2, i32 0)` and returns the `i64` result
and is now covered by `releasesmall_runtime_umul_fix_sat_i64`. The next
source-backed shape is the ReleaseSmall `inherit_want_safety_i64_return` row,
which returns `i64 4` through an `entry` alias and is now covered by
`releasesmall_runtime_inherit_want_safety_i64`. The next source-backed shape
is the ReleaseSmall `standalone_compile_asm_main_unreachable` row, which
aliases `@main` to `@main.main` and lowers to an empty noreturn
`unreachable` stub with three `i32` parameters and is now covered by
`releasesmall_runtime_compile_asm_unreachable`. The next measured ReleaseSmall
boundary is the `standalone_emit_llvm_no_bin_main` row, whose selected alias is
`@strFromFloatHelp -> @main.strFromFloatHelp`, a multi-block float-format
helper. That boundary now has a reduced external writer prologue slice covered
by `releasesmall_runtime_str_from_float_help`. The next measured ReleaseSmall
boundary is the `standalone_mix_o_files_base64` row, whose selected alias is
`@decode_base_64 -> @base64.decode_base_64`, a table-driven multi-block
decoder. That boundary now has a reduced table-load/OR/validity step covered
by `releasesmall_runtime_base64_decode_step`. The next selected slice from the
same decoder is the decoded-word store step around block `%164`, which stores
the combined i32 word to the output pointer and returns to the narrow decode
loop and is now covered by `releasesmall_runtime_base64_store_step`. The next
selected slice from the same decoder is the residual byte emit path around
block `%189`, which masks the residual bit count, shifts/truncates the i12
accumulator to i8, stores one output byte, and advances the output index and
is now covered by `releasesmall_runtime_base64_residual_byte_step`. The next
selected slice from the same decoder is the padding-tail byte check around
block `%206`, which loads a remaining source byte and accepts only `=`
padding, and is now covered by
`releasesmall_runtime_base64_padding_tail_step`. The next selected slice from
the same decoder is the padding-tail loop walk around block `%205`, which
advances across accepted trailing padding bytes, and is now covered by
`releasesmall_runtime_base64_padding_loop_step`. The next selected slice from
the same decoder is the entry padding length adjustment in `.critedge.i`,
which loads the last two source bytes, compares each with `=`, sign-extends
the boolean results to `i64`, and adds them to the computed output length,
and is now covered by
`releasesmall_runtime_base64_padding_length_step`. The next selected slice
from the same decoder is the chunk-loop guard in block `%18`, which advances
the source/output indexes by 16 and 15 bytes, compares both against the input
and output bounds, combines the predicates with `select`, and branches into
the wide decode loop only when both are in range, and is now covered by
`releasesmall_runtime_base64_chunk_guard_step`. The next selected slice from
the same decoder is the wide decode source-byte stride in block `%24`, which
computes a source byte address, loads an `i8`, zero-extends it to `i64`, uses
that index for a table GEP, and loads the selected table word, and is now
covered by `releasesmall_runtime_base64_source_stride_step`. The next selected
slice from the same decoder is the four-byte source bundle for one wide decode
word in block `%24`, and is now covered by
`releasesmall_runtime_base64_source_bundle_step`. The next selected slice from
the same decoder is the next four-byte source bundle in block `%73`, and is
now covered by `releasesmall_runtime_base64_next_source_bundle_step`. The next
selected slice from the same decoder is the third four-byte source bundle in
block `%97`, and is now covered by
`releasesmall_runtime_base64_third_source_bundle_step`. The next selected
slice from the same decoder is the wide `i128` bit-buffer combine and output
store in block `%121`, and is now covered by
`releasesmall_runtime_base64_bit_buffer_store_step`. The next selected slice
from the same decoder is the source/output index advance and backedge at the
end of block `%121`, and is now covered by
`releasesmall_runtime_base64_loop_advance_step`. The next selected slice from
the same decoder is the residual/preheader guard before block `%139`, and is
now covered by `releasesmall_runtime_base64_residual_guard_step`. The next
selected slice from the same decoder is the residual four-byte source/table
bundle in block `%139`, and is now covered by
`releasesmall_runtime_base64_residual_bundle_step`. The next selected slice is
the residual output store and `-4` backedge, and is now covered by
`releasesmall_runtime_base64_residual_store_step`. The next selected slice is
the residual remaining-length calculation in block `%162`, and is now covered
by `releasesmall_runtime_base64_residual_length_step`. The next selected slice
is the residual byte-loop/table check in block `%169`, and is now covered by
`releasesmall_runtime_base64_residual_table_check_step`. The next selected
slice is the residual accumulator update in block `%176`, and is now covered
by `releasesmall_runtime_base64_residual_accumulator_step`. The next selected
slice is the residual loop-index advance in block `%187`.

LLVM fallback removed or reduced:
Reduce the remaining external writer gap for selected ReleaseSmall base64
decoder coverage after the reduced residual accumulator row: create one
source-backed reduced residual loop-index advance fixture or selected external
writer row from
`base64.decode_base_64`, then drive the first concrete parser, optimizer,
codegen, or object blocker. Do not claim the full decoder, arbitrary loops,
all table forms, all bit-buffer behavior, all stores, all padding validation,
or all object/linker behavior.

Mode/target/stage row:
ReleaseSmall / x86_64-linux-gnu / external IR writer -> accepted optimizer
pipeline -> local object -> Zig native-link executable proof.

Upstream mapping:
LLVM lowers the completed slice-sum source row to a loop in
`test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll` with:
`%.010 = phi i32 [ 0, %2 ], [ %5, %.lr.ph ]`,
`%.089 = phi i64 [ 0, %2 ], [ %6, %.lr.ph ]`,
`%3 = getelementptr [4 x i8], ptr %0, i64 %.089`,
`%4 = load i32, ptr %3, align 4`, `%5 = add nsw i32 %4, %.010`,
and a loop-exit compare/branch.
The completed FP constants row lowers to direct FP returns in
`test/distribution/releasefast_x86_64/inputs/fp_constants_literals.ll`:
`ret double 2.250000e+00` and `ret float 1.500000e+00`.
Source behavior is represented by Zig's `fp_constants` fixture. The next
selected row lowers in
`test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll` to:
`%2 = mul nsw i32 %0, 5`, `ret i32 %2`.
Source behavior is represented by Zig's `globals_comptime` fixture. The next
selected row lowers in
`test/distribution/releasefast_x86_64/inputs/atomics_debug_location.ll` to:
`%2 = add nsw i32 %0, 1`, `ret i32 %2`.
Source behavior is represented by Zig's `atomics_inline_asm_debug` fixture.
The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll`
to `llvm.sadd.with.overflow.i32`, an overflow branch to
`debug.FullPanic((function 'defaultPanic')).integerOverflow`, and a non-overflow
`extractvalue` return and is now covered by
`releasesafe_runtime_debug_location`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll` to
`llvm.smul.with.overflow.i32(i32 %0, i32 5)`, an overflow branch to the same
integer-overflow panic edge, and a non-overflow `extractvalue` return and is
now covered by `releasesafe_runtime_comptime_const`. Source behavior is
represented by Zig's `globals_comptime` fixture. The next selected row lowers
in the same file to private global load from
`@globals_comptime.global_counter`, `llvm.sadd.with.overflow.i32`, overflow
branch to the same panic edge, non-overflow `store i32` back to the private
global, and `ret i32` of the updated value and is now covered by
`releasesafe_runtime_global_update`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll` to
`load i32, ptr %0`, `llvm.sadd.with.overflow.i32(i32 %3, i32 1)`, an overflow
branch to the same panic edge, non-overflow `store i32 %8, ptr %1`, and
`ret i32 %8` and is now covered by
`releasesafe_runtime_pointer_load_store`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll`
to a branch on the `i1` flag, `llvm.sadd.with.overflow.i32` for the true path,
`llvm.ssub.with.overflow.i32` for the false path, a merge `phi`, and two
integer-overflow panic edges and is now covered by
`releasesafe_runtime_branch_mix`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll` to
`add i32 %0, 1073741824`, `icmp slt`, a panic edge on negative, and
non-overflow result construction with `shl nsw i32 %0, 1` and
`or disjoint i32 %5, 1` and is now covered by
`releasesafe_runtime_call_chain`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll` to a
private `thread_local` `@tls_concurrency.tls_counter`, TLS load,
`llvm.sadd.with.overflow.i32`, overflow panic edge, non-overflow TLS store,
and `ret i32` of the updated value and is now covered by
`releasesafe_runtime_tls_bump`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll` to
`aggregates.array_sum` with checked add of `%0 + %1`, overflow branch, checked
add of that result plus `%2`, a second overflow branch, and `ret i32` of the
second extractvalue result and is now covered by
`releasesafe_runtime_array_sum`. The next selected row lowers in the same file
to `aggregates.struct_sum` with `load i32, ptr %0`,
`getelementptr i8, ptr %0, i64 4`, `load i32, ptr %3`,
`llvm.sadd.with.overflow.i32(i32 %2, i32 %4)`, an integer-overflow panic edge,
and `ret i32` of the extractvalue result and is now covered by
`releasesafe_runtime_struct_sum`. The next selected row lowers in the same
file to `aggregates.slice_sum` with two loop phi values, indexed GEP/load,
`llvm.sadd.with.overflow.i32` in the loop body, an integer-overflow panic edge,
and loop-exit branch to the final sum and is now covered by
`releasesafe_runtime_slice_sum`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll` to
`control_flow_calls.loop_sum` with counted-loop phi values, checked add
operations in the loop body, integer-overflow panic edges, and the selected
integer-out-of-bounds panic edge and is now covered by
`releasesafe_runtime_loop_sum`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll` to
`globals_comptime.read_global` with `load i32, ptr @globals_comptime.global_counter`
and direct `ret i32` and is now covered by
`releasesafe_runtime_read_global`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll` to
`tls_concurrency.read_tls` with a direct load from
`@tls_concurrency.tls_counter` and `ret i32` and is now covered by
`releasesafe_runtime_tls_read`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll` to
`tiny_scalar.sideEffectFree` with a direct `ret void` and is now covered by
`releasesafe_runtime_side_effect_free`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll`
to `exports.getHidden` and `exports.updateHidden` over private
`@exports.hidden` storage and is now covered by
`releasesmall_runtime_hidden_access`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll`
to `main.add_zig`, which loads private `@main.zig_k`, adds the incoming
argument, loads `@C_k`, and returns the combined sum and is now covered by
`releasesmall_runtime_mix_c_add_zig`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll`
to `main.add_may_panic`, which branches on `icmp slt i32 %0, 0`, calls
`debug.defaultPanic` on the panic edge, and returns `@main.zig_k + %0` on the
non-panicking edge and is now covered by
`releasesmall_runtime_mix_c_add_may_panic`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll`
to a selected `llvm.umul.fix.sat.i64` intrinsic call and `ret i64` and is now
covered by `releasesmall_runtime_umul_fix_sat_i64`. The next selected row
lowers in
`test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll`
to `inherit_want_safety.entry` with direct `ret i64 4` and is now covered by
`releasesmall_runtime_inherit_want_safety_i64`. The next selected row lowers
in
`test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll`
to `@main = alias void (i32, i32, i32), ptr @main.main`, where
`main.main` contains only `unreachable`, and is now covered by
`releasesmall_runtime_compile_asm_unreachable`. The next selected row is the
ReleaseSmall boundary exclusion
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`,
where `@strFromFloatHelp` aliases `@main.strFromFloatHelp`, a multi-block
float-format helper. The reduced prologue slice covers the selected double
bitcast, exponent extraction, special-value branch, and `ret void`/`unreachable`
edge and is now covered by `releasesmall_runtime_str_from_float_help`. The
next selected boundary row is
`test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll`,
where `@decode_base_64` aliases `@base64.decode_base_64`, a table-driven
multi-block decoder. The reduced decode-step slice covers four selected table
GEP/load pairs, i32 OR combination, `icmp ult i32 %word, 16777216`, and a
runtime exit-code select and is now covered by
`releasesmall_runtime_base64_decode_step`. The next selected slice is the
store step from the same fixture around `%165 = getelementptr [1 x i8], ptr %0,
i64 %.1.i` and `store i32 %161, ptr %165, align 1` and is now covered by
`releasesmall_runtime_base64_store_step`. The next selected slice is the
residual byte emit path around `%190 = and i4 %183, 7`,
`%194 = lshr i12 %192, %193`, `%195 = trunc i12 %194 to i8`, and
`store i8 %195, ptr %191, align 1` and is now covered by
`releasesmall_runtime_base64_residual_byte_step`. The accepted ReleaseSmall
pipeline folds the selected constant residual chain to `store i8 63`, and the
object gate lowers that optimized shape. The padding-tail byte check around
`%207 = getelementptr [1 x i8], ptr %203, i64 %.0301.i`,
`%208 = load i8, ptr %207, align 1`, and
`%.not318.i = icmp eq i8 %208, 61` is now covered by
`releasesmall_runtime_base64_padding_tail_step`. The next selected slice from
the same block is the padding-tail loop walk around `%.0301.i = phi i64`,
`%exitcond348.not.i = icmp eq i64 %.0301.i, %204`, `%209 = add i64 %.0301.i,
1`, and the backedge branch on `%.not318.i`, and is now covered by
`releasesmall_runtime_base64_padding_loop_step`. The next selected slice is
the entry padding length adjustment around `%10 = load i8, ptr %9`,
`%11 = icmp eq i8 %10, 61`, `%12 = sext i1 %11 to i64`,
`%spec.select.i = add i64 %7, %12`, `%14 = load i8, ptr %13`,
`%15 = icmp eq i8 %14, 61`, `%16 = sext i1 %15 to i64`, and
`%spec.select21.i = add i64 %spec.select.i, %16`, and is now covered by
`releasesmall_runtime_base64_padding_length_step`. The next selected slice is
the chunk-loop guard around `%19 = add nuw i64 %.0304.i, 16`,
`%20 = icmp ult i64 %19, %3`, `%21 = add nuw i64 %.0303.i, 15`,
`%22 = icmp ult i64 %21, %.sroa.0.0.ph`, `%23 = select i1 %20, i1 %22,
 i1 0`, and `br i1 %23, label %24, label %.preheader.i`, and is now covered
by `releasesmall_runtime_base64_chunk_guard_step`. The next selected slice is
the source-byte stride around `%50 = getelementptr i8, ptr %25, i64 4`,
`%51 = load i8, ptr %50, align 1`, `%52 = zext i8 %51 to i64`,
`%53 = getelementptr [4 x i8], ptr @__anon_1321, i64 %52`, and
`%54 = load i32, ptr %53, align 4`, and is now covered by
`releasesmall_runtime_base64_source_stride_step`. The next selected slice is
the four-byte source bundle around `%50` through `%72`: four source byte
GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not321.i = icmp ult i32 %72, 16777216`, and is now covered by
`releasesmall_runtime_base64_source_bundle_step`. The next selected slice is
the next four-byte source bundle around `%74` through `%96`: four source byte
GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not322.i = icmp ult i32 %96, 16777216`, and is now covered by
`releasesmall_runtime_base64_next_source_bundle_step`. The next selected slice
is the third four-byte source bundle around `%98` through `%120`: four source
byte GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not323.i = icmp ult i32 %120, 16777216`, and is now covered by
`releasesmall_runtime_base64_third_source_bundle_step`. The next selected
slice is the bit-buffer combine and output store around `%122 = zext nneg i32
%120 to i128`, `%123 = zext nneg i32 %72 to i128`,
`%124 = shl nsw nuw i128 %123, 24`, `%125 = or disjoint i128 %124, %48`,
`%126 = zext nneg i32 %96 to i128`, `%127 = shl nsw nuw i128 %126, 48`,
`%128 = or disjoint i128 %125, %127`, `%129 = shl nsw nuw i128 %122, 72`,
`%130 = or disjoint i128 %128, %129`, and `store i128 %130, ptr %131`, and
is now covered by `releasesmall_runtime_base64_bit_buffer_store_step`. The
next selected slice is the loop advance and backedge around
`%132 = add nuw i64 %.0303.i, 12`,
`%indvars.iv.next.i = add i64 %indvars.iv.i, -16`, and `br label %18`, and
is now covered by `releasesmall_runtime_base64_loop_advance_step`. The next
selected slice is the residual/preheader guard around
`%133 = add nuw i64 %.1305.i, 4`, `%134 = icmp ult i64 %133, %3`,
`%135 = add nuw i64 %.1.i, 3`, `%136 = icmp ult i64 %135, %.sroa.0.0.ph`,
`%137 = select i1 %134, i1 %136, i1 0`,
`%138 = getelementptr [1 x i8], ptr %2, i64 %.1305.i`, and the branch on
`%137`, and is now covered by
`releasesmall_runtime_base64_residual_guard_step`. The next selected slice is
the residual four-byte source/table bundle around `%140 = load i8, ptr %138`,
`%141 = zext i8 %140 to i64`,
`%142 = getelementptr [4 x i8], ptr @__anon_1321, i64 %141`,
`%143 = load i32, ptr %142`, the three following byte/table loads at offsets
1, 2, and 3, `%149 = or i32 %148, %143`, `%155 = or i32 %149, %154`,
`%161 = or i32 %155, %160`, and the validity branch on
`%.not319.i = icmp ult i32 %161, 16777216`, and is now covered by
`releasesmall_runtime_base64_residual_bundle_step`. The next selected slice is
the residual success store/backedge around
`%165 = getelementptr [1 x i8], ptr %0, i64 %.1.i`,
`store i32 %161, ptr %165, align 1`,
`%indvars.iv.next346.i = add i64 %indvars.iv345.i, -4`, and
`br label %.preheader.i`, and is now covered by
`releasesmall_runtime_base64_residual_store_step`. The next selected slice is
the residual remaining-length calculation around
`%163 = sub nuw i64 %3, %.1305.i` and `br label %168`, and is now covered by
`releasesmall_runtime_base64_residual_length_step`. The next selected slice is
the residual byte-loop/table check around `%.2.i` and `%.0302.i` phi values,
`%exitcond.i = icmp eq i64 %.0302.i, %indvars.iv345.i`,
`%170 = getelementptr [1 x i8], ptr %138, i64 %.0302.i`,
`%171 = load i8, ptr %170`, `%172 = zext i8 %171 to i64`,
`%173 = getelementptr [1 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 4096), i64 %172`,
`%174 = load i8, ptr %173`, `%175 = icmp eq i8 %174, -1`, and the branch on
`%175`, and is now covered by
`releasesmall_runtime_base64_residual_table_check_step`. The next selected
slice is the residual accumulator update around the `i16` load/trunc to `i12`,
`%178 = shl i12 %177, 6`, `%179 = zext i8 %174 to i12`,
`%180 = add nuw i12 %178, %179`, `store i12 %180`, the bit-count
`%181 = trunc i8 ... to i4`, `%182 = add nuw i4 %181, 6`, and `store i4
%182`, and is now covered by
`releasesmall_runtime_base64_residual_accumulator_step`. The next selected
slice is the residual loop-index advance around
`%.3.i = phi i64 [ %196, %189 ], [ %.2.i, %176 ]`,
`%188 = add nuw i64 %.0302.i, 1`, and `br label %168`, and is now covered
by `releasesmall_runtime_base64_residual_loop_advance_step`. The next selected
slice is the residual padding check around `%186 = add nuw i64 %.0302.i,
%.1305.i`, `%.not313.i = icmp eq i8 %171, 61`, and the branch on
`%.not313.i`.

Completed error-union mapping:
`%.not.i = icmp eq i32 %0, 0`,
`%2 = select i1 %.not.i, i32 7, i32 -1`, `ret i32 %2` in
`test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll`.

Known boundary:
Only the selected ReleaseSmall base64 residual padding check
boundary-reduction slice.
Full decoder coverage, arbitrary loops, all table forms, all bit-buffer
behavior, all stores, all padding validation, and all object/linker behavior
remain out of scope.

Validation gate:
`zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_check_step`
then `zig build distribution-zig-ir-writer`. If x86_64 codegen changes, also
run `zig build handoff`; if only the writer/runner/docs change and the focused
gate passes through existing lowering, run `zig build test`.

Commit:
Commit the selected ReleaseSmall base64 residual padding check
boundary-reduction slice
separately with the policy in
`docs/commit_policy.md`.

## Current Evidence

Latest local validation:

```text
zig build test
zig build readiness
zig build distribution-all
zig build distribution-native-link
zig build probe-native-linker
zig build distribution-zig-source-native-link
zig build distribution-zig-integrated-object
zig build distribution-zig-integrated-preopt
zig build distribution-zig-ir-writer-tiny-scalar
zig build distribution-zig-ir-writer
zig build probe-native-linker-broad -- --mode=ReleaseFast
zig build probe-native-linker-broad -- --mode=ReleaseSafe
zig build probe-native-linker-broad -- --mode=ReleaseSmall
zig build probe-native-linker-broad -- --mode=Debug
zig build distribution-native-link-boundary2
```

The focused gates passed after the script runner cleanup, shared tool helper
refactor, selected native-linker proof expansion, native-linker compatibility
probe addition, exact broad-probe category split, ReleaseSmall base64 table
lookup reduction, and the experimental patched-Zig object-emission hook. The
Zig source integration gate passes: 10 source rows go from stage4 Zig-emitted
LLVM IR through local `z_llvm` object emission and Zig native linking, with 9
executable proofs and 1 ReleaseSafe link-only panic-runtime boundary. The Zig
integrated object-emission gate uses paired C ABI wrapper objects and a patched
`../ziglang` hook so the selected rows go through Zig's `build-obj` object
boundary before `z_llvm --emit=obj` and `zig build-exe -fno-lld`. The
integrated preopt gate also passes for the same 10 rows: patched Zig writes
pre-optimization IR before LLVM's `module_pm.run(...)`, `z_llvm` runs the
accepted Zig-mode pipeline and emits the object, and Zig native linking
finishes the selected wrappers. The external z_llvm textual IR writer gate now
also passes: the first ReleaseFast tiny-scalar row and the full 83-row
integrated set go through `ZIG_USE_ZLLVM_IR_WRITER=1` with
`ZLLVM_IR_WRITER_MODE=external`, `z_llvm --emit=ir-writer`, the accepted
`z_llvm` preopt pipeline, local object emission, and Zig native linking. The
writer now has 83 runtime-emitted selected rows and 0 minimal-wrapper hook
proofs. Runtime surfaces cover tiny scalar add, integer arithmetic,
error-switch-style compare/select, direct call, global load, i64 arithmetic,
ReleaseSmall i64 call-return, table indexed load, and the ReleaseSafe checked-add panic-runtime
boundary, plus ReleaseFast runtime conditional branch, phi/merge, loop, and
dense-switch rows, plus the mutable global update, ABI-argument direct-call,
selected pointer load/store row, local-exec TLS read/update rows, the selected
volatile roundtrip row, local-exec TLS read/update rows, the selected atomic
add row, optional pointer row, and the selected inline-asm memory barrier row,
plus the selected packed read-flag row, selected packed replace-low row,
selected aggregate pair ABI row, selected struct field-sum row, selected
scalarized array-sum row, selected optional scalar payload row, selected
error-union payload row, selected pointer-indexed slice-sum row,
selected ordered `f32` less-than row, selected `f64` multiply row, selected
`f32` add row, selected `f64` select row, selected `f32` subtract row, and
selected `f64` divide row, selected `f32` remainder row, and selected f32/f64
literal-return row, selected comptime constant multiply row, and selected
add-immediate return row, plus the selected ReleaseSafe checked add-immediate,
checked comptime-const, checked global-update, and checked pointer-load/store
panic-edge rows, plus the selected checked branch-mix and checked call-chain
rows, selected checked TLS bump row, selected checked array-sum row, and
selected checked struct-sum row, selected checked slice-sum row, and selected
checked loop-sum row, plus the selected ReleaseSafe read-global row. Broad
native-link probes are link-only evidence: every current ReleaseFast,
ReleaseSafe, ReleaseSmall, and Debug row is accepted, accounted for by an exact
Zig runtime/TLS/compiler-rt category, or explicitly excluded as a documented
boundary. No broad probe currently reports an unclassified local object/link
failure.

Current distribution evidence is recorded in
[x86_64_distribution_object_dashboard.md](roadmap/x86_64_distribution_object_dashboard.md)
and
[x86_64_distribution_replacement_matrix.md](roadmap/x86_64_distribution_replacement_matrix.md).
The selected native-link distribution slice is recorded in
[x86_64_native_link_distribution_slice.md](roadmap/x86_64_native_link_distribution_slice.md):
the captured release-mode claim is recorded in
[x86_64_captured_release_native_link_claim.md](roadmap/x86_64_captured_release_native_link_claim.md).
The Zig source integration slice is recorded in
[x86_64_zig_source_native_link_slice.md](roadmap/x86_64_zig_source_native_link_slice.md).
The experimental patched-Zig object-emission slice is recorded in
[x86_64_zig_integrated_object_emit_slice.md](roadmap/x86_64_zig_integrated_object_emit_slice.md).

```text
ReleaseFast  x86_64 asm/object: conservative boundary, 17/17 captured rows object-clean
ReleaseSafe  x86_64 asm/object: conservative boundary, 17/17 captured rows object-clean
ReleaseSmall x86_64 asm/object: conservative boundary, 463/465 captured rows object-clean,
             2 explicit exclusions
Debug        x86_64 asm/object: conservative boundary, adjusted continuous 463-row subset
             object-clean, 2 explicit exclusions
musl         selected x86_64 object/executable subset gates pass
linking      final executable/library/archive/linker-script ownership remains Zig-owned
native link  45 selected ABI-stable objects link and run through
             `zig build-exe -fno-lld`; probe accepted=45 failed=0
             per-mode: ReleaseFast 27/27, ReleaseSafe 9/9,
             ReleaseSmall 8/8, Debug 1/1
source link  Zig source -> stage4 LLVM IR -> z_llvm object -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             ReleaseFast executable=5, ReleaseSafe executable=1 plus
             1 panic-runtime link-only boundary, ReleaseSmall executable=3
integrated   patched Zig build-obj -> optimized IR -> z_llvm object
             -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             each wrapper records covered_fixture, mode, and proof
preopt       patched Zig build-obj -> preopt IR -> z_llvm accepted pipeline
             -> z_llvm object -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             ReleaseFast narrow gate also passes with --mode=ReleaseFast
ir writer    patched Zig build-obj -> external z_llvm textual IR subset
             -> z_llvm accepted pipeline -> z_llvm object -> Zig native link:
             tiny-scalar total=1 executable_ok=1 local_fail=0,
             scalar_runtime_rows=1 minimal_wrapper_rows=0
             full set total=83 executable_ok=83 link_only_ok=0 local_fail=0
             scalar_runtime_rows=83 minimal_wrapper_rows=0
             surface-counts scalar-add-ret=1 integer-arithmetic=1
             error-switch-select=2 direct-call=1 global-load=3
             i64-arithmetic=1 i64-call-return=1 table-indexed-load=1
             checked-add-runtime-boundary=1 runtime-condbr=1
             runtime-phi-merge=1 runtime-loop-sum=1 runtime-switch=1
             checked-loop-sum-boundary=1
             global-update=1 pointer-load-store=1 volatile-roundtrip=1
             optional-pointer=1 packed-read-flag=1 abi-arg-call=1
             packed-replace-low=1 tls-read=2 tls-bump=1 atomic-add=1
             inline-asm-barrier=1 aggregate-pair-abi=1
             float-less=1 float-mul=1 float-add=1 float-select=1
             float-sub=1 double-div=1 float-rem=1 struct-field-sum=1
             array-scalar-sum=1 optional-scalar-payload=1
             error-union-payload=1
             slice-loop-sum=1 fp-literal-return=1
             comptime-const-mul=1
             void-noop-call=1
             hidden-global-access=1
             mixed-c-zig-add=1
             mixed-c-zig-panic-add=1
             umul-fix-sat-i64=1
             inherit-i64-return=1
             compile-asm-unreachable=1
             str-from-float-prologue=1
             base64-decode-step=1
             base64-store-step=1
             base64-residual-byte-step=1
             base64-padding-tail-step=1
             base64-padding-loop-step=1
             base64-padding-length-step=1
             base64-chunk-guard-step=1
             base64-source-stride-step=1
             base64-source-bundle-step=1
             base64-next-source-bundle-step=1
             base64-third-source-bundle-step=1
             base64-bit-buffer-store-step=1
             base64-loop-advance-step=1
             base64-residual-guard-step=1
             base64-residual-bundle-step=1
             base64-residual-store-step=1
             base64-residual-length-step=1
             base64-residual-table-check-step=1
             base64-residual-accumulator-step=1
             base64-residual-loop-advance-step=1
             add-imm-return=1
             checked-add-imm-boundary=1
             checked-comptime-const-boundary=1
             checked-global-update-boundary=1
             checked-pointer-load-store-boundary=1
             checked-branch-mix-boundary=1
             checked-call-chain-boundary=1
             checked-tls-bump-boundary=1
             checked-array-sum-boundary=1
             checked-struct-sum-boundary=1
             checked-slice-loop-sum-boundary=1
             minimal-ret0=0
broad link   link-only native-link boundary2:
             ReleaseFast total=17 accepted=16 accounted=1 local_fail=0
             ReleaseSafe total=17 accepted=8 accounted=9 local_fail=0
             ReleaseSmall total=465 accepted=271 accounted=192 local_fail=0,
             2 explicit exclusions, accounted_total=465
             Debug total=10 accepted=6 accounted=4 local_fail=0
AArch64      object emission remains an explicit target boundary
```

There is no current measured first failure in the selected x86_64 distribution
subset. The broad native-link boundary2 gate also has no unclassified local
failure; remaining broad rows are Zig-owned runtime/TLS/compiler-rt boundaries
or the two named ReleaseSmall exclusions, so they are not active `z_llvm`
implementation slices.

## Next Selection Rule

Do not start generic pass parity work from this file. To open the next active
cycle, first produce or identify one measured replacement gap from Zig-backed
evidence, then replace this section with a single implementation slice using
the template below.

Preferred next probes, in order:

1. Refresh only stale x86_64 distribution evidence if a codegen, object,
   handoff, manifest, or fixture change affects it.
2. Expand one named x86_64 distribution subset only when there is a concrete
   source-backed input directory or manifest row beyond the current captured
   boundary.
3. Promote the first parse, verify, optimize, handoff, object, executable ABI,
   relocation, or boundary failure from that probe.
4. For native-linker work, run `zig build probe-native-linker` or
   `zig build distribution-native-link-boundary2` before selecting
   implementation. The first unclassified local failure becomes a local object
   compatibility slice unless evidence proves Zig runtime, TLS, compiler-rt,
   or linker ownership.
5. If no blocker appears, update the dashboard or matrix only when the clean
   evidence changes a row status or named boundary.

Use this template for the next active slice:

```text
Replacement goal:
Zig evidence:
LLVM fallback removed or reduced:
Mode/target/stage row:
Upstream mapping:
Known boundary:
Validation gate:
Commit:
```

Use `unknown` only while selecting a slice. Before implementation is marked
complete, replace every `unknown` with a concrete answer or document why the
slice is preparatory infrastructure only.
