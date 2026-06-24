# x86_64 Broad Real-AIR Shape Recognizer Audit

Current measured gates:

```text
zig build distribution-zig-air-uncurated-releasefast-broad
zig build distribution-zig-air-uncurated-releasesafe-broad
zig build distribution-zig-air-uncurated-releasesmall-broad
```

All three release modes currently report:

```text
structured_functions=152
structured_air_v1_functions=152
structured_air_v2_functions=152
typed_air_type_functions=152
typed_air_operand_functions=152
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=152
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
top_typed_v2_fallback_reason=-
top_typed_v2_fallback_count=0
```

`structured_air-v1` is present for every accepted function and carries
instruction tags plus body/branch metadata. `structured_air-v2` is also present
for every accepted function after the contract bump; it currently carries
instruction result records, typed value operands, typed control targets, typed
sentinel operands, operand text details, and call signature records. z_llvm now
lowers the straight-line scalar, load/store, global pointer constants,
stack-slot, direct-call, runtime symbol pointer, simple block-result diamond
select, struct field-sum, array aggregate-sum, and base64 table-lookup subset from typed v2 records, using
`structured_air-v1` body topology
only where block structure is still required. Aggregate pair first/make-pair now validates typed-v2
aggregate ABI records before lowering to the scalar SysV representation. Error-union payload now
validates typed-v2 error-union branch/payload records before lowering to the selected payload value.
Maybe-error helpers now validate typed-v2 branch/return records before lowering to the selected
error-union scalar representation. Optional scalar-payload helpers now validate typed-v2
wrap/null-check/payload branch records. Optional pointer-payload helpers now validate typed-v2
null-check/payload/load records. Packed read/replace helpers now validate typed-v2
packed field pointer/load/store records before lowering to the scalar bit representation.
Slice-sum helpers now validate typed-v2 pointer-add/slice/len/element/loop records,
including the ReleaseSafe safety-expanded form. Selected monotonic atomic add and
empty inline-asm memory-barrier helpers now lower from typed-v2 records directly.
Accumulator-loop helpers now validate typed-v2 loop/repeat/branch records before lowering to
the phi-based loop IR. Dense-switch and conditional slot-update helpers now validate typed-v2
switch/branch and branch/store/update records before lowering. Error-switch and classifier helpers
now validate typed-v2 error-union switch, branch, payload, and classifier records before lowering
to the scalar error representation. Runtime optional-pointer and pointer load/store wrapper mains
now validate typed-v2 call, callee, branch, compare, and merge records before lowering. One
mixed C/Zig panic-edge function now validates typed-v2 negative-check, `defaultPanic`, global-load,
and add/add_safe records before lowering, preserving the named `debug.defaultPanic` runtime boundary.

The broad gates emit `typed-v2-fallback` diagnostics only when an accepted
function falls back to legacy AIR text. The summary records the first fallback
function/opcode/data kind/reason and the top fallback bucket. Generic typed-v2
validation failures report the concrete failing typed opcode and data kind
instead of a synthetic `typed_v2` bucket. The current broad gates have no typed
v2 fallback bucket.

No broad shape-recognizer families remain in `src/zig_air_lowering.zig`.

Backend generic CFG ownership is tracked separately from typed-v2 lowering.
The current broad x86_64 release gates report `generic_cfg_functions=152` /
`structural_matcher_functions=0` for ReleaseFast, ReleaseSafe, and
ReleaseSmall. The expanded frontier reports `generic_cfg_functions=197` /
`structural_matcher_functions=0` for all three release modes. Newly promoted
backend families include alloca-stored extern-struct field loads at offsets 0
and 4, branch-local field-0 updates, the nested optional-pointer branch payload
with a preserved ReleaseSafe guard edge, optional-pointer load-plus-add payload
blocks, the expanded f32 pipeline with an unused scalar bool parameter, the
base64 byte-table lookup leaf, the conditional slice-loop update row,
single-block scalar FP binary/compare/select/literal returns, single-block
volatile i32 store/load roundtrips, single-block packed read/replace bit
helpers, scalar numeric conversion casts, signed-min `icmp slt`/`select`
classifiers, nested `i8` equality error-switch selects, nested `i8` equality
error-union/classifier selects, boolean-parameter branch-mix add/sub selects,
constant-return `i8 switch` CFGs, void `i32` global/TLS store helpers, and existing
slice/aggregate sum shapes plus small aggregate pair SysV pack/unpack helpers
that pass strict generic CFG eligibility, plus selected monotonic atomic add
and empty inline-asm memory-barrier leaves through a generic effect-barrier
admission path, and empty no-op `ret void` helpers through the generic void CFG
path. The expanded ABI frontier adds seven- and nine-argument exported integer
functions, noinline helper calls with one and three stack-passed integer
arguments, f32/f64 plus mixed integer/f32/f64 direct-call returns, and i64
mixed-argument call/return paths through the shared SysV call/frame helpers.
Generic no-arg void-call wrapper
mains that return `i32 0` now route
through a shape-driven generic CFG admission instead of a wrapper-name-specific
lowerer. Scalar multiply-by-constant leaves now reuse the existing generic
`mul const` validator/emitter through generic CFG, covering
`control_flow_calls.callee` and `globals_comptime.comptime_const`. Scalar
`shift_mix` and i64 constant-return leaves, including the selected i64
wrapper-family mains that reduce to those leaves, now route through generic
scalar/i64 CFG admissions. Constant sibling-wrapper call/check mains with a
direct `fastcc` FP or bool call, constant scalar arguments, and an
`fcmp`/`select` or bool-call/`select` i32 0/1 return now validate through a
generic CFG admission instead of the selected runtime float wrapper table.
Integer-return sibling-wrapper call/check mains with constant scalar arguments,
`icmp eq/ne`, and the same i32 0/1 select now use the same generic CFG path.
Sibling update/get wrapper mains that issue a void update call with a constant
`i32` argument followed by an `i32` getter call now route through generic CFG
direct-call lowering instead of hidden-global structural lowering. Wrapper
mains that tail-call a direct `i32` helper with constant `i32` arguments and an
optional identity cast now also route through generic direct-call lowering,
covering the mixed C/Zig and TLS bump wrapper checks. Pointer-literal sibling
call/check wrapper mains now validate `ptr @global` and `ptr null` arguments
through the same generic admission, covering the slice-sum, struct-sum, and
volatile roundtrip wrapper checks. Two-call aggregate wrapper chains that pass
an i64 return into an i32 helper now emit real calls through generic CFG,
covering `runtime_aggregate_pair_main.main`. Multi-block call/global-load
checks with a boolean merge now emit real sibling calls and RIP-relative
global-address arguments through generic CFG, covering
`runtime_pointer_load_store_main.main`. Multi-block two-call optional-pointer
wrapper checks now validate `ptr @global` and `ptr null` sibling call
arguments through generic CFG, covering `runtime_optional_pointer_main.main`.
The mixed C/Zig panic-edge leaf now validates the negative guard,
`debug.defaultPanic` noreturn call, global-load/add return, and checked
overflow panic edge through generic CFG. No structural matcher backend rows
remain in the current broad or expanded release gates.

Set `ZLLVM_DEBUG_CODEGEN_PATHS=1` on an uncurated AIR gate to print the
per-function backend route. The current expanded ReleaseFast structural
inventory groups as follows:

- conditional slice-loop / loop-memory dependency: the exported
  `expanded_cfg_memory_aggregates.expanded_slice_conditional_sum` now routes
  through generic CFG. Wrapper `main` check functions with pointer-literal
  calls, such as `runtime_slice_sum_main.main`, now use the generic sibling
  call/check admission. Larger loop-memory dependency variants remain future
  work.
- volatile memory: `pointers_memory.volatile_roundtrip`,
  `runtime_volatile_roundtrip_main.volatileRoundtrip`, and the wrapper
  `runtime_volatile_roundtrip_main.main` now route through generic CFG after
  validating the exact volatile store-before-load order, pointer parameter
  shape, and pointer-literal wrapper call/check shape. Multi-block volatile
  CFGs remain rejected until branch-local volatile ordering is modeled
  explicitly.
- broader global/TLS addressing: simple global/TLS data functions such as
  `globals_comptime.read_global`, `globals_comptime.update_global`,
  `tls_concurrency.read_tls`, `tls_concurrency.bump_tls`,
  `expanded_records_memory.expanded_global_update`, and
  `expanded_records_memory.expanded_tls_bump` already route through generic
  CFG. `runtime_hidden_access_main.updateHidden` now routes through the generic
  void global-store path, `runtime_hidden_access_main.main` now routes through
  the generic sibling update/get wrapper path, and `runtime_tls_bump_main.main`
  now routes through the generic direct-call wrapper path.
- aggregate field stores and ABI aggregate pairs:
  `expanded_cfg_memory_aggregates.expanded_struct_field_a`,
  `expanded_cfg_memory_aggregates.expanded_struct_field_b`, and
  `expanded_cfg_memory_aggregates.expanded_struct_branch_update` are generic
  CFG. `aggregate_abi.pair_first`, `aggregate_abi.make_pair`,
  `expanded_records_memory.expanded_pair_first`,
  `expanded_records_memory.expanded_make_pair`,
  `runtime_aggregate_pair_main.makePair`, and
  `runtime_aggregate_pair_main.pairFirst` now route through generic CFG as
  small aggregate pair ABI pack/unpack helpers. The sret store path for
  two-`i32` aggregates is shape-validated and no longer depends on the
  `runtime_aggregate_pair_main.makePair` symbol name, and the first-field
  pointer load path is owned by the ordinary generic CFG pointer-load return
  lowering rather than the `runtime_aggregate_pair_main.pairFirst` symbol name.
  The aggregate wrapper
  `runtime_aggregate_pair_main.main` now routes through a generic two-call
  chain admission that passes the first helper's i64 return to the second
  helper.
- multi-block call/global-load checks: `runtime_pointer_load_store_main.main`
  now routes through a generic CFG admission that validates a sibling call with
  two global pointer arguments, a call-result guard, a second-block global load
  guard, a boolean merge phi, and an i32 0/1 select return.
- multi-block two-call optional-pointer checks:
  `runtime_optional_pointer_main.main` now routes through a generic CFG
  admission that validates two unary pointer sibling calls, `ptr @global` and
  `ptr null` arguments, call-result guards, a boolean merge phi, and an i32
  0/1 select return.
- ABI/call/aggregate-return shapes: generic CFG owns simple direct-call branch
  rows such as `expanded_cfg_memory_aggregates.expanded_branch_call*` and
  `control_flow_calls.call_chain`, plus no-arg void-call wrapper mains such as
  `runtime_side_effect_free_main.main`, constant direct-call wrapper mains such
  as `runtime_mix_c_add_zig_main.main`, and panic-boundary direct-call wrapper
  mains such as `runtime_mix_c_add_may_panic_main.main`. The
  `expanded_abi_frontier` row extends this proof to multiple stack-passed
  integer call arguments, stack-passed integer parameters, mixed integer/SSE
  direct-call returns, and i64 direct-call returns in the expanded corpus.
- scalar FP, packed-bit, numeric-cast, and wrapper-check families: single-block scalar FP rows such as
  `float_compare.*`, `floats_math.*`, `fp_extended_ops.*`,
  `fp_constants.*`, and `expanded_float_calls.*` now route through generic CFG.
  Single-block packed helpers such as `packed_bits.read_flag`,
  `packed_bits.replace_low`, `runtime_packed_read_flag_main.readFlag`, and
  `runtime_packed_replace_low_main.replaceLow` now route through generic CFG
  after validating the mask/shift/OR or sign-bit compare pattern. Numeric
  conversion rows in `expanded_numeric_casts.*` now route through generic CFG
  for fpext, fptrunc, int-from-float, signed int-to-float, and unsigned
  int-to-double shapes. Runtime FP wrapper-main check rows such as
  `runtime_float_add_main.main`, `runtime_float_less_main.main`,
  `runtime_double_div_main.main`, and their sibling wrappers now route through
  the generic constant call/check admission. Integer-return wrapper checks such
  as `runtime_array_sum_main.main`, `runtime_optional_payload_main.main`,
  `runtime_error_union_payload_main.main`, `runtime_packed_replace_low_main.main`,
  `runtime_slice_sum_main.main`, `runtime_struct_sum_main.main`, and
  `runtime_volatile_roundtrip_main.main` now use that same generic admission.
- ReleaseSafe checked/panic-edge shapes: selected checked guard shapes are
  generic CFG, and the mixed C/Zig panic-edge wrapper main now uses generic
  direct-call lowering. The `runtime_mix_c_add_may_panic_main.add_may_panic`
  helper now uses generic guarded global-add lowering while preserving the full
  runtime-call boundary and global-load/add_safe shape.
- other scalar classifier rows: `integers.cmp_select` now routes through
  generic CFG from the typed AIR block-result `icmp slt`/`select` shape, and
  `error_switch.error_switch` routes through generic CFG from nested `i8`
  equality selects. `switch_control.branch_mix` now routes through generic CFG
  from the boolean-parameter select plus add/sub expression shape.
  `switch_control.dense_switch` routes through generic CFG from the
  constant-return `i8 switch` terminator shape. `error_switch.classify`,
  `aggregates.maybeError`, and
  `runtime_error_union_payload_main.maybeError` now route through the generic
  i64 CFG path for nested `i8` equality error-union/classifier selects. Simple
  scalar multiply-by-constant leaves such as `control_flow_calls.callee` and
  `globals_comptime.comptime_const` now route through generic CFG.

Next typed-contract target:

- lower directly from typed `structured_air-v2` records instead of legacy AIR
  text
- convert control-flow, optional/error-union, pointer/slice/array, aggregate,
  lowering from recognizer families to generic typed AIR
  lowering
- keep `legacy_air_text_lowering_functions=0` and
  `shape_recognizer_functions=0` as broad coverage expands
