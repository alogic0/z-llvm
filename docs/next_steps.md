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
ReleaseSafe checked add-immediate boundary, pointer
load/store/volatile-roundtrip/optional-pointer, packed bitfield, extern-struct
field-load, scalarized array-sum, optional scalar payload, error-union
payload, and pointer-indexed slice-sum surfaces: a source-backed x86_64
ReleaseSafe checked comptime constant multiply row.

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
integer-overflow panic edge.

LLVM fallback removed or reduced:
Reduce the remaining external writer gap for selected ReleaseSafe checked
arithmetic after the checked add-immediate row: emit
`globals_comptime.comptime_const` as `llvm.smul.with.overflow.i32(value, 5)`
with the selected Zig integer-overflow panic edge, plus a C ABI executable
proof for the non-overflow path. Do not claim broad ReleaseSafe panic
semantics, arbitrary checked multiplication, runtime ownership, or all safety
paths.

Mode/target/stage row:
ReleaseFast / x86_64-linux-gnu / external IR writer -> accepted optimizer
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
integer-overflow panic edge, and a non-overflow `extractvalue` return.
Source behavior is represented by Zig's `globals_comptime` fixture.
Record more precise upstream files if the slice needs optimizer/codegen
behavior beyond the selected ReleaseSafe checked multiply-by-constant shape.

Completed error-union mapping:
`%.not.i = icmp eq i32 %0, 0`,
`%2 = select i1 %.not.i, i32 7, i32 -1`, `ret i32 %2` in
`test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll`.

Known boundary:
Only selected `i32` checked multiply-by-five with the integer-overflow panic
edge stubbed for non-overflow executable proof. Broad ReleaseSafe runtime
semantics, all panic functions, arbitrary checked arithmetic, and runtime
ownership remain out of scope.

Validation gate:
`zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_comptime_const`
then `zig build distribution-zig-ir-writer`. If x86_64 codegen changes, also
run `zig build handoff`; if only the writer/runner/docs change and the focused
gate passes through existing lowering, run `zig build test`.

Commit:
Commit the selected ReleaseSafe checked comptime constant multiply slice
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
also passes: the first ReleaseFast tiny-scalar row and the full 43-row
integrated set go through `ZIG_USE_ZLLVM_IR_WRITER=1` with
`ZLLVM_IR_WRITER_MODE=external`, `z_llvm --emit=ir-writer`, the accepted
`z_llvm` preopt pipeline, local object emission, and Zig native linking. The
writer now has 43 runtime-emitted selected rows and 0 minimal-wrapper hook
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
add-immediate return row, plus the selected ReleaseSafe checked add-immediate
panic-edge row. Broad
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
             full set total=43 executable_ok=43 link_only_ok=0 local_fail=0
             scalar_runtime_rows=43 minimal_wrapper_rows=0
             surface-counts scalar-add-ret=1 integer-arithmetic=1
             error-switch-select=2 direct-call=1 global-load=2
             i64-arithmetic=1 i64-call-return=1 table-indexed-load=1
             checked-add-runtime-boundary=1 runtime-condbr=1
             runtime-phi-merge=1 runtime-loop-sum=1 runtime-switch=1
             global-update=1 pointer-load-store=1 volatile-roundtrip=1
             optional-pointer=1 packed-read-flag=1 abi-arg-call=1
             packed-replace-low=1 tls-read=1 tls-bump=1 atomic-add=1
             inline-asm-barrier=1 aggregate-pair-abi=1
             float-less=1 float-mul=1 float-add=1 float-select=1
             float-sub=1 double-div=1 float-rem=1 struct-field-sum=1
             array-scalar-sum=1 optional-scalar-payload=1
             error-union-payload=1
             slice-loop-sum=1 fp-literal-return=1
             comptime-const-mul=1
             add-imm-return=1
             checked-add-imm-boundary=1
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
