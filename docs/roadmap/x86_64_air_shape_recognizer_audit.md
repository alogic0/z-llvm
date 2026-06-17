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
The current broad x86_64 release gates report `generic_cfg_functions=101` /
`structural_matcher_functions=51` for ReleaseFast and ReleaseSmall, and
`102` / `50` for ReleaseSafe. The expanded frontier reports
`generic_cfg_functions=121` / `structural_matcher_functions=60` for
ReleaseFast and ReleaseSmall, and `123` / `58` for ReleaseSafe. Newly promoted
backend families include alloca-stored extern-struct field loads at offsets 0
and 4, branch-local field-0 updates, the nested optional-pointer branch payload
with a preserved ReleaseSafe guard edge, the conditional slice-loop update row,
single-block scalar FP binary/compare/select/literal returns, single-block
volatile i32 store/load roundtrips, and existing slice/aggregate sum shapes
that pass strict generic CFG eligibility. Multi-block volatile memory, broader
aggregate field stores, broader global/TLS addressing, and larger loop-memory
dependencies remain structural/backend frontier work.

Set `ZLLVM_DEBUG_CODEGEN_PATHS=1` on an uncurated AIR gate to print the
per-function backend route. The current expanded ReleaseFast structural
inventory groups as follows:

- conditional slice-loop / loop-memory dependency: the exported
  `expanded_cfg_memory_aggregates.expanded_slice_conditional_sum` now routes
  through generic CFG. Remaining structural loop-adjacent examples are wrapper
  `main` check functions such as `runtime_slice_sum_main.main` and
  `runtime_array_sum_main.main`, whose call/compare/select validation is still
  handled by selected structural wrapper helpers.
- volatile memory: `pointers_memory.volatile_roundtrip` and
  `runtime_volatile_roundtrip_main.volatileRoundtrip` now route through generic
  CFG after validating the exact volatile store-before-load order and pointer
  parameter shape. `runtime_volatile_roundtrip_main.main` remains structural
  because it is a wrapper call/check row, and multi-block volatile CFGs remain
  rejected until branch-local volatile ordering is modeled explicitly.
- broader global/TLS addressing: simple global/TLS data functions such as
  `globals_comptime.read_global`, `globals_comptime.update_global`,
  `tls_concurrency.read_tls`, `tls_concurrency.bump_tls`,
  `expanded_records_memory.expanded_global_update`, and
  `expanded_records_memory.expanded_tls_bump` already route through generic
  CFG. Remaining structural examples include wrapper or hidden-symbol shapes
  such as `runtime_hidden_access_main.updateHidden`,
  `runtime_hidden_access_main.main`, and `runtime_tls_bump_main.main`.
- aggregate field stores and ABI aggregate pairs:
  `expanded_cfg_memory_aggregates.expanded_struct_field_a`,
  `expanded_cfg_memory_aggregates.expanded_struct_field_b`, and
  `expanded_cfg_memory_aggregates.expanded_struct_branch_update` are generic
  CFG. Structural ABI examples remain in `aggregate_abi.pair_first`,
  `aggregate_abi.make_pair`, `expanded_records_memory.expanded_pair_first`,
  `expanded_records_memory.expanded_make_pair`, and the
  `runtime_aggregate_pair_main.*` wrapper/helper family.
- ABI/call/aggregate-return shapes: generic CFG owns simple direct-call branch
  rows such as `expanded_cfg_memory_aggregates.expanded_branch_call*` and
  `control_flow_calls.call_chain`. Structural examples remain for wrapper
  validation and non-i32 return/argument families such as
  `runtime_mix_c_add_zig_main.main`, `runtime_inherit_want_safety_i64_main.main`,
  and `runtime_umul_fix_sat_i64_main.main`.
- scalar FP and packed-bit families: single-block scalar FP rows such as
  `float_compare.*`, `floats_math.*`, `fp_extended_ops.*`,
  `fp_constants.*`, and `expanded_float_calls.*` now route through generic CFG.
  Numeric conversion rows in `expanded_numeric_casts.*`, packed-bit rows in
  `packed_bits.*`, and FP wrapper-main check rows still use structural backend
  helpers until generic CFG covers those value/register and call/check shapes.
- ReleaseSafe checked/panic-edge shapes: selected checked guard shapes are
  generic CFG, but mixed C/Zig panic-edge rows such as
  `runtime_mix_c_add_may_panic_main.*` remain structural until the generic CFG
  path preserves the full runtime-call boundary and global-load/add_safe shape.
- other scalar classifier rows: `error_switch.error_switch`,
  `error_switch.classify`, `switch_control.branch_mix`,
  `switch_control.dense_switch`, `aggregates.maybeError`, and
  `integers.cmp_select` remain structural because their backend lowering still
  uses narrow scalar classifier helpers even though typed-v2 lowering is closed.

Next typed-contract target:

- lower directly from typed `structured_air-v2` records instead of legacy AIR
  text
- convert control-flow, optional/error-union, pointer/slice/array, aggregate,
  lowering from recognizer families to generic typed AIR
  lowering
- keep `legacy_air_text_lowering_functions=0` and
  `shape_recognizer_functions=0` as broad coverage expands
