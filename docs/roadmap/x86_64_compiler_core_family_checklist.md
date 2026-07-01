# x86_64 Compiler-Core Family Checklist

This checklist tracks recurring AIR/backend families for the x86_64 Zig
compiler-core replacement path. It is not a per-function or per-instruction
task list. Each item should be closed by a reusable semantic/lowering/backend
abstraction, source-backed frontier rows, object/native-link/executable proof
where applicable, and refreshed inventory evidence.

Use [`docs/working-cycle.md`](../working-cycle.md) for the worker loop. Use
[`docs/roadmap/x86_64_compiler_core_inventory_priorities.md`](x86_64_compiler_core_inventory_priorities.md) for the latest
counts and first-source evidence.

## Completion Rule

A family is complete only when all applicable release modes have evidence for:

- typed/model-owned facts, with no AIR-text scraping or source-name sidecars;
- reusable lowering or backend support, not selected case-id handling;
- fail-closed diagnostics for unsupported subforms;
- x86_64 object emission without LLVM TargetMachine;
- Zig native linker handoff without LLD;
- executable proof for stable callable rows, or explicit boundary proof where
  execution is not meaningful;
- refreshed inventory showing the targeted unsupported bucket reduced or
  reclassified.

## Implementation Checklist

Families are sorted by current priority. Each checkbox is a recurring
implementation slice that should be closed with the completion rule above. Add
new subitems when refreshed inventory exposes a new concrete pair inside the
same family.

### 1. Aggregate ABI At Scale

Layer: semantic layout, ABI planner, backend.

- [x] Own aggregate layout facts from typed/model data for compiler-core rows.

  ReleaseFast compiler-core-module refresh evidence:
  `tmp/compiler_core_module_releasefast_aggregate_layout_facts_enabled.log`
  reports `aggregate_layout_facts=5824` with real module context, generated
  imports available, no stubs, and `instruction_payload_scan=1`.
- [x] Lower struct arguments passed in registers.

  Existing frontier proof covers register-passed INTEGER, SSE/SSE,
  INTEGER/SSE, SSE/INTEGER, nested, shifted, direct-call, and indirect-call
  struct arguments through `frontier_sysv_aggregate_classes.zig` and
  `frontier_sysv_abi.zig`. Saved gate evidence:
  `tmp/frontier_error_union_cleanup_rewrap.log` reports all three release modes
  at `generic_cfg_functions=716`, `object_emitted_functions=716`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower struct arguments passed through memory.

  Existing frontier proof covers stack-passed INTEGER aggregates, SSE/SSE
  aggregates, mixed INTEGER/SSE and SSE/INTEGER aggregates, nested mixed
  aggregates, direct and pointer-callee forwarding, and deep-stack aggregate
  forwarding after register exhaustion. Representative rows include
  `frontier_stack_array_pair_call_sum_after_six`,
  `frontier_deep_stack_array_pair_call_sum_after_six`,
  `frontier_stack_array_double_forward_after_pressure`,
  `frontier_stack_reverse_mixed_forward_after_pressure`, and
  `frontier_stack_nested_mixed_forward_after_pressure` in
  `frontier_sysv_aggregate_classes.zig`, with C ABI executable checks in
  `frontier_frontier_sysv_aggregate_classes.c`. Saved gate evidence:
  `tmp/frontier_error_union_cleanup_rewrap.log` reports all three release modes
  at `generic_cfg_functions=716`, `object_emitted_functions=716`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower struct returns in registers.

  Existing frontier proof covers register aggregate returns for INTEGER/INTEGER,
  INTEGER/SSE, SSE/INTEGER, SSE/SSE, nested, array-backed, direct helper, and
  pointer-callee helper paths. Representative rows include
  `frontier_mixed_make`, `frontier_double_pair_make`,
  `frontier_float_array_make`, `frontier_reverse_mixed_make`,
  `frontier_nested_pair_make`, `frontier_array_pair_make`,
  `frontier_array_double_make`, `frontier_nested_mixed_make`,
  `frontier_indirect_array_double_make`, and
  `frontier_indirect_nested_mixed_make` in
  `frontier_sysv_aggregate_classes.zig`, with C ABI executable checks in
  `frontier_frontier_sysv_aggregate_classes.c`. Saved gate evidence:
  `tmp/frontier_error_union_cleanup_rewrap.log` reports all three release modes
  at `generic_cfg_functions=716`, `object_emitted_functions=716`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower struct returns through sret memory.

  Existing frontier proof covers normal supported-leaf MEMORY aggregate returns
  through hidden sret pointers for flat integer aggregates, nested aggregates,
  array-backed aggregates, float/double aggregates, pointer/float/integer mixed
  aggregates, and direct plus pointer-callee copy/forwarding paths.
  Representative rows include `frontier_big3_make`,
  `frontier_big20_copy`, `frontier_direct_big32_copy`,
  `frontier_indirect_big80_copy`, `frontier_stack_source_big81_copy`,
  `frontier_big_nested_copy`, `frontier_big_array_copy`,
  `frontier_big_double_copy`, `frontier_big_float_copy`,
  `frontier_big_ptr_double_copy`, and `frontier_big_deep_mixed_copy` in
  `frontier_sysv_sret_byval.zig`, with C ABI executable checks in
  `frontier_frontier_sysv_sret_byval.c`. Saved gate evidence:
  `tmp/frontier_error_union_cleanup_rewrap.log` reports all three release modes
  at `generic_cfg_functions=716`, `object_emitted_functions=716`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower array arguments and returns.

  Existing frontier proof covers array-backed aggregate arguments and returns in
  both register and MEMORY classes. Representative register rows include
  `frontier_array_pair_sum`, `frontier_array_pair_make`,
  `frontier_stack_array_pair_call_sum_after_six`,
  `frontier_array_double_make`,
  `frontier_register_array_double_call_sum_after_eight`,
  `frontier_deep_stack_array_double_call_sum`, `frontier_float_array_make`,
  and `frontier_indirect_array_double_make` in
  `frontier_sysv_aggregate_classes.zig`. Representative MEMORY rows include
  `frontier_big_array_copy`, `frontier_big_double_array_copy`,
  `frontier_big_float_array_copy`, `frontier_big_array_mixed_copy`,
  `frontier_big_nested_array_mixed_copy`,
  `frontier_big_struct_array_mixed_copy`, and
  `frontier_big_deep_mixed_copy` in `frontier_sysv_sret_byval.zig`. The C ABI
  harnesses validate these array arguments and returned arrays through native
  executable checks. Saved gate evidence:
  `tmp/frontier_error_union_cleanup_rewrap.log` reports all three release modes
  at `generic_cfg_functions=716`, `object_emitted_functions=716`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower slice arguments and returns as `{ ptr, len }` aggregates.

  `frontier_slice_pointer_arith.zig` now includes a C-compatible exported
  wrapper that constructs `[]const i32`, calls an internal Zig `fastcc` helper
  returning a slice as `{ ptr, len }`, and passes that returned slice to another
  internal Zig `fastcc` helper that consumes pointer and length to produce a
  scalar checksum. The C harness validates the scalar wrapper result, so the
  accepted proof exercises Zig internal slice aggregate argument and return
  lowering while keeping exported ABI C-compatible. Saved evidence:
  `tmp/frontier_slice_internal_abi_focused.log` reports ReleaseFast at
  `generic_cfg_functions=719`, `structural_matcher_functions=0`,
  `object_emitted_functions=719`, and `local_fail=0`; the strict
  all-release-mode frontier evidence is `tmp/frontier_counter_update.log`.
- [x] Lower aggregate field/payload reads used after calls.

  `frontier_sysv_aggregate_classes.zig` now includes C ABI wrappers that call a
  noinline helper returning `{ i64, double }`, store that returned aggregate, and
  read either the integer or SSE field. The generic aggregate ABI lowerer
  validates the call-result -> aggregate slot -> field-load -> return dataflow
  and emits the selected SysV aggregate return register field without
  source-name admission. Saved evidence:
  `tmp/frontier_aggregate_call_read_fields_releasefast.log` reports ReleaseFast
  at `generic_cfg_functions=721`, `structural_matcher_functions=0`,
  `object_emitted_functions=721`, and `local_fail=0`; the strict all-release
  frontier evidence is `tmp/frontier_counter_update.log`.
- [x] Lower aggregate field/payload writes before calls.

  `frontier_sysv_aggregate_classes.zig` now includes a C ABI wrapper that
  initializes a local `{ i64, double }` aggregate through field stores, loads the
  aggregate value, and calls a noinline helper that consumes the aggregate. The
  typed-v2 aggregate lowerer validates the alloc -> field_ptr -> store -> load
  -> call -> return dataflow, normalizes `add_safe` to the hot-path arithmetic
  value for ReleaseSafe, and the generic CFG aggregate ABI path emits the
  constructed register aggregate call argument without source-name admission.
  Saved evidence: `tmp/frontier_aggregate_field_write_before_call_releasefast.log`
  and `tmp/frontier_aggregate_field_write_before_call_releasefast_exec.log`
  prove the focused ReleaseFast row/object/executable path; the strict
  all-release-mode frontier evidence in `tmp/frontier_counter_update.log`
  reports `generic_cfg_functions=722`, `object_emitted_functions=722`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Prove at least one direct-call aggregate row.

  Direct aggregate call proof is now covered by source-backed rows in
  `frontier_sysv_aggregate_classes.zig`, including
  `frontier_mixed_field_write_before_call` -> `helperMixedInt(Mixed)` and the
  existing `frontier_float_pair_call_sum` -> `helperFloatPairSum(FloatPair)`.
  Both are C-harness executable-proven as part of the module harness, while the
  accepted lowering uses typed-v2/model-owned aggregate facts and generic CFG
  call lowering rather than source-name admission. Saved evidence:
  `tmp/frontier_counter_update.log` reports all three release modes at
  `generic_cfg_functions=722`, `object_emitted_functions=722`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Prove at least one returned-aggregate row.

  Returned aggregate proof is covered by `frontier_mixed_call_make`,
  `frontier_float_array_call_make`, and `frontier_nested_mixed_call_make`, which
  directly return helper-produced aggregates through the x86_64 SysV register
  aggregate path. The C harness verifies returned field contents for INTEGER/SSE
  mixed and SSE aggregate forms. Saved evidence:
  `tmp/frontier_counter_update.log` reports all three release modes at
  `generic_cfg_functions=722`, `object_emitted_functions=722`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Prove at least one aggregate field/payload executable row.

  Field/payload executable proof is covered by the C harness checks for
  `frontier_mixed_call_make_read_int`,
  `frontier_mixed_call_make_read_float`, and
  `frontier_mixed_field_write_before_call`. These rows prove aggregate
  call-result field reads and field-store-before-call payload construction
  through stable native-link executable checks. Saved evidence:
  `tmp/frontier_counter_update.log` reports all three release modes at
  `native_link_accepted_rows=14`, `executable_ok_rows=14`, and `local_fail=0`.
- [x] Keep unsupported packed/unaligned/oversized forms fail-closed.

  Packed/unaligned aggregate ABI remains an explicit source-backed boundary:
  `test/zig/frontier_boundaries/frontier_packed_aggregate_boundary.zig`
  reports `UnsupportedPackedAggregateAbi` for packed aggregate argument and
  return forms. The current strict boundary log,
  `tmp/frontier_boundary_counter_update.log`, reports
  `packed_aggregate_boundary_rows=2`, `unexpected_accept_rows=0`,
  `wrong_diagnostic_rows=0`, and `local_fail=0` in all three release modes.
  Normal supported-leaf large MEMORY aggregates are not boundary-owned anymore;
  the accepted frontier covers generated BigN sret/byval rows through `Big256`.
  Larger or unsupported leaf/layout forms remain fail-closed by the x86_64 SysV
  planner rather than silently falling back.
- [x] Refresh inventory and show the aggregate ABI bucket reduced or
  reclassified.

  Focused ReleaseFast compiler-core-module refresh
  `tmp/compiler_core_module_releasefast_after_aggregate722.log` completed with
  real module context, generated imports available, no stubs, and
  `instruction_payload_scan=1`. The aggregate ABI bucket remains the largest
  measured family at `aggregate-abi=2324786`, but it is now split into
  `aggregate_opcode_shapes=410781`, `aggregate_metadata_type_surfaces=1392400`,
  `aggregate_abi_type_surfaces=932386`, and `aggregate_layout_facts=5824`.
  This reclassifies the remaining work as broad aggregate ABI/type-layout
  ownership rather than an unknown selected-row blocker; ReleaseSafe and
  ReleaseSmall inventory refresh remain milestone-cost and were not rerun.

### 2. Error-Union Try/Wrap/Unwrap

Layer: typed AIR facts, semantic lowering, CFG lowering.

- [x] Lower `unwrap_errunion_err` from typed operands.
- [x] Lower `wrap_errunion_err` from typed operands.
- [x] Lower `wrap_errunion_payload` for compiler-core-shaped payload flows.
- [x] Lower `try` with payload continuation.
- [x] Lower `try` with error return.
- [x] Lower discarded-payload chained `try` in `Error!void` helpers.
- [x] Lower catch/error cleanup before rewrapped error return.
- [x] Lower `try` with catch-side branch/merge.
- [x] Lower `try_cold`.
- [x] Lower `try_ptr`.
- [x] Lower `unwrap_errunion_err_ptr`.
- [x] Prove direct helper-call error-union returns without compatibility
  emitters.
- [x] Prove branch-only wrapped error-union returns.
- [x] Prove loop or switch continuation after `try`.
- [x] Keep pointer/cold/error-name subforms covered by typed facts or
  fail-closed until facts exist.
- [x] Refresh inventory and show the error-union try bucket reduced.

  ReleaseFast refresh evidence:
  `tmp/compiler_core_module_releasefast_after_error_union_capabilities.log`
  reports `unknown_opcode category=error-union-try count=0` after the
  capability registry stopped counting typed-v2 lowerable error-union opcodes as
  unknown inventory opcodes.

### 3. Pointer/Slice/Address Forms

Layer: typed AIR parser and address-form lowering.

- [x] Lower `ptr_slice_len_ptr`.

  Existing source-backed proof is `frontier_slice_len_from_ptr` in
  `frontier_slice_pointer_arith.zig`, where a `values[0..len]` slice is built
  from pointer + length and `.len` is returned through the executable C harness.
  The latest focused compiler-core ReleaseFast inventory,
  `tmp/compiler_core_module_releasefast_after_aggregate722.log`, still counts
  raw `ptr_slice_len_ptr` opcodes (`count=17471`) but reports
  `unknown_opcode category=pointer-address count=0`, so this form is now
  classified as known/lowerable rather than an unsupported inventory bucket.
  Strict executable evidence remains `tmp/frontier_counter_update.log` with
  `executable_ok_rows=14` and `local_fail=0`.
- [x] Lower `ptr_slice_ptr_ptr`.

  Existing source-backed proof is in `frontier_slice_ptr_load`,
  `frontier_slice_ptr_const_runtime_load`, and
  `frontier_slice_ptr_const_runtime_store`, where `slice.ptr` is extracted from
  a pointer/length slice and then used for derived load/store addressing. The
  focused compiler-core ReleaseFast inventory log still counts raw
  `ptr_slice_ptr_ptr` opcodes (`count=6343`) but keeps
  `unknown_opcode category=pointer-address count=0`, so this opcode is now
  known/lowerable rather than an unsupported pointer-address bucket. Strict
  executable evidence remains `tmp/frontier_counter_update.log`.
- [x] Lower `slice_ptr`.

  `slice_ptr` is covered by the same source-backed slice pointer rows:
  `frontier_slice_ptr_load`,
  `frontier_slice_ptr_const_runtime_load`, and
  `frontier_slice_ptr_const_runtime_store`. These rows extract `slice.ptr`,
  apply constant plus runtime offsets, and prove load/store behavior through the
  C executable harness. The focused compiler-core ReleaseFast inventory log
  counts raw `slice_ptr` opcodes (`count=11926`) while reporting
  `unknown_opcode category=pointer-address count=0`, so the form is known and
  no longer an unsupported pointer-address bucket.
- [x] Lower `ptr_add`.

  `ptr_add` is covered by `frontier_dynamic_ptr_add`,
  `frontier_comptime_ptr_add`, `frontier_chained_ptr_add`, the scalar-width
  `frontier_ptr_add_load_*` rows, and the `frontier_ptr_add_store_*` rows in
  `frontier_slice_pointer_arith.zig`. The C harness proves runtime index,
  comptime offset, chained offset, load, and store forms across i8/i16/i32/i64
  element widths. The focused compiler-core ReleaseFast inventory log still
  counts raw `ptr_add` opcodes (`count=14279`) while reporting
  `unknown_opcode category=pointer-address count=0`.
- [x] Lower `ptr_sub`.

  `ptr_sub` is covered by `frontier_ptr_sub_const_load`,
  `frontier_ptr_sub_runtime_load`, and
  `frontier_ptr_sub_runtime_rcx_load` in `frontier_slice_pointer_arith.zig`.
  The executable harness proves constant-backstep, runtime-backstep, and
  non-primary-register runtime index forms. The focused compiler-core
  ReleaseFast inventory log counts raw `ptr_sub` opcodes (`count=119`) while
  keeping the pointer-address unsupported bucket at zero.
- [x] Record first-source selectors for known pointer opcodes.

  The inventory now retains `first_source` and `first_function` on raw
  `opcode` and `top_opcode` rows, not only on unsupported categories. Focused
  ReleaseFast compiler-core-module evidence in
  `tmp/compiler_core_module_releasefast_opcode_first_sources.log` reports
  `is_non_null_ptr count=263 first_source=../ziglang/src/main.zig
  first_function=main.serveUpdateResults` and `runtime_nav_ptr count=41
  first_source=../ziglang/src/main.zig
  first_function=Io.Threaded.Thread.checkCancel`. This makes the next
  pointer/slice items source-selectable without guessing source shapes.
- [x] Lower `is_non_null_ptr` from a real source shape.

  Focused ReleaseFast compiler-core-module selector evidence in
  `tmp/compiler_core_module_releasefast_opcode_first_sources.log` reported
  `is_non_null_ptr count=263 first_source=../ziglang/src/main.zig
  first_function=main.serveUpdateResults`. The reduced frontier proof is
  `frontier_optional_ptr_field_non_null` in
  `frontier_optionals_errors.zig`, which mirrors the compiler-core optional
  pointer field shape: a pointer field is loaded from a struct pointer, checked
  for non-null, then the payload is loaded on the hot path. The typed-v2 field
  pointer lowerer now accepts unknown aggregate layout only for proven
  offset-zero plain pointer fields, and the x86_64 generic CFG optional-row
  backend validates the field-load -> null-guard -> hot load/add return/null
  return dataflow without source-name admission. Saved strict frontier evidence
  `tmp/frontier_is_non_null_ptr.log` reports all three release modes at
  `source_rows=14`, `generic_cfg_functions=723`,
  `object_emitted_functions=723`, `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower `runtime_nav_ptr` or classify it as a runtime boundary.

  This form is already lowerable from typed-v2 `ty_nav` facts rather than a
  runtime boundary: the Zig exporter records `nav_fqn`, and z_llvm lowers it to
  an IR symbol value without AIR-text recovery. Existing source-backed proof is
  `frontier_globals_tls.frontier_tls_branch`, whose saved AIR descriptor
  `tmp/uncurated_zig_air_releasefast_3056277/frontier_globals_tls.air` contains
  `runtime_nav_ptr(*i32, 'frontier_globals_tls.frontier_tls')` and typed-v2
  `nav_fqn` records. The x86_64 generic CFG address path classifies that symbol
  as local-exec TLS and emits load/store TLS instructions. Strict executable
  evidence in `tmp/frontier_is_non_null_ptr.log` reports
  `frontier_globals_tls.zig` executable-ok in ReleaseFast, ReleaseSafe, and
  ReleaseSmall, with all modes at `generic_cfg_functions=723`,
  `object_emitted_functions=723`, and `local_fail=0`.
- [x] Prove pointer arithmetic with load/store.

  `frontier_slice_pointer_arith.zig` contains source-backed pointer arithmetic
  rows for runtime `ptr_add`, comptime `ptr_add`, chained pointer addition,
  `ptr_sub`, constant+runtime offsets, and scalar load/store through derived
  pointers for i8/i16/i32/i64 element widths. The C harness
  `frontier_frontier_slice_pointer_arith.c` checks both load and store results,
  including `frontier_ptr_add_load_const_runtime_u8/u16/u32/u64`,
  `frontier_ptr_add_store_u8/u16/u64`,
  `frontier_ptr_add_store_const_runtime_i32`, and the `ptr_sub` load rows.
  Strict executable evidence in `tmp/frontier_is_non_null_ptr.log` reports
  `frontier_slice_pointer_arith.zig` executable-ok in ReleaseFast, ReleaseSafe,
  and ReleaseSmall with all modes at `generic_cfg_functions=723`,
  `object_emitted_functions=723`, and `local_fail=0`.
- [x] Prove slice pointer extraction.

  `frontier_slice_pointer_arith.zig` proves `slice.ptr` extraction through
  `frontier_slice_ptr_load`,
  `frontier_slice_ptr_const_runtime_load`, and
  `frontier_slice_ptr_const_runtime_store`. These rows construct slices from
  pointer+length inputs, extract the pointer, apply runtime or constant+runtime
  offsets, and then load or store through the derived pointer. The C harness
  validates all three rows, and `tmp/frontier_is_non_null_ptr.log` reports
  `frontier_slice_pointer_arith.zig` executable-ok in ReleaseFast, ReleaseSafe,
  and ReleaseSmall with `local_fail=0`.
- [x] Prove slice length extraction.

  `frontier_slice_len_from_ptr` constructs a `[]const i32` from pointer+length
  inputs and returns `slice.len`; the C harness checks
  `z_frontier_slice_len_from_ptr(values, 5) == 5`. This proves typed-v2 slice
  construction plus `slice_len` lowering through generic CFG and x86_64 return
  codegen. The same strict frontier log,
  `tmp/frontier_is_non_null_ptr.log`, reports
  `frontier_slice_pointer_arith.zig` executable-ok in all three release modes
  with `local_fail=0`.
- [x] Prove pointer/slice values across a branch merge.

  `frontier_pointer_branch_merge_load` in
  `frontier_slice_pointer_arith.zig` now proves a real source-backed branch
  selection of pointer values: Zig lowers the `if` expression to a typed-v2
  pointer `select`, the existing generic CFG single-block pointer-select load
  path owns the load, and the C harness checks both true and false pointer
  selections. Strict executable evidence in
  `tmp/frontier_pointer_branch_merge.log` reports all three release modes at
  `source_rows=14`, `generic_cfg_functions=724`,
  `object_emitted_functions=724`, `executable_ok_rows=14`, and `local_fail=0`.
- [x] Keep unsupported address spaces and volatile/atomic pointer forms
  fail-closed.

  `frontier_pointer_slice_boundary.zig` now covers volatile and atomic
  derived-pointer forms: a volatile pointer load through pointer arithmetic and
  an `@atomicLoad` through a derived pointer. The boundary registry classifies
  both as `pointer-slice` with `UnsupportedPointerSliceAbi`, and
  `tmp/frontier_pointer_slice_boundary.log` reports all three release modes at
  `source_rows=7`, `discovered_functions=12`,
  `pointer_slice_boundary_rows=2`, `wrong_diagnostic_rows=0`, and
  `local_fail=0`. Address-space-specific pointer rows remain future work until
  a source-backed x86_64 release shape is selected.
- [x] Refresh inventory and show the pointer-address bucket reduced.

  Focused ReleaseFast compiler-core-module inventory was refreshed after the
  pointer/slice frontier reached 724 functions:
  `tmp/compiler_core_module_releasefast_after_pointer_slice724.log`. The
  summary reports `functions=61375`, `instructions_total=6298207`,
  `unsupported_functions=55852`, and `unsupported_opcodes=47087`, while the
  pointer-address bucket remains closed:
  `unknown_opcode category=pointer-address count=0 first_source=-
  first_function=-`. Raw pointer-address opcodes still appear as known opcode
  counts, for example `ptr_sub count=119`, but they are no longer classified as
  unsupported inventory blockers in ReleaseFast. ReleaseSafe and ReleaseSmall
  were not refreshed for this checklist item.

### 4. Aggregate-Shape Ops

Layer: aggregate semantic lowering.

- [x] Lower `slice_len`.

  `slice_len` is already lowerable through the typed pointer/slice path. The
  source-backed proof is `frontier_slice_len_from_ptr` in
  `frontier_slice_pointer_arith.zig`, where a pointer/length slice is
  constructed and `.len` is returned through the C executable harness. Strict
  frontier evidence in `tmp/frontier_array_to_slice.log` reports all three
  release modes at `generic_cfg_functions=726`,
  `object_emitted_functions=726`, `executable_ok_rows=14`, and `local_fail=0`.
  The refreshed ReleaseFast compiler-core-module inventory,
  `tmp/compiler_core_module_releasefast_after_pointer_slice724.log`, still
  reports raw `slice_len count=13774`, but the only current
  `aggregate-shape` unknown bucket is `array_to_slice:ty_op`.
- [x] Lower `slice`.

  Typed-v2 `slice` construction is covered by the existing
  `frontier_slice_pointer_arith.zig` rows that build `values[0..len]` slices
  and consume them through `.len`, `.ptr`, element load/store, checked element
  access, and internal Zig slice-ABI helper calls. The refreshed ReleaseFast
  compiler-core-module inventory reports raw `slice count=10901`, while the
  previous `aggregate-shape` unknown bucket was `array_to_slice:ty_op`.
- [x] Lower `array_to_slice`.

  `array_to_slice` is now a model-owned pointer aggregate semantic op and
  lowers typed-v2 pointer-to-array operands into the shared `{ ptr, i64 }`
  slice aggregate. `frontier_array_to_slice_len` proves the derived length and
  `frontier_array_to_slice_runtime_load` proves runtime-index load through the
  resulting slice. The strict frontier gate
  `tmp/frontier_array_to_slice.log` reports all three release modes at
  `source_rows=14`, `discovered_functions=726`,
  `generic_cfg_functions=726`, `object_emitted_functions=726`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Lower aggregate construction from typed operands.

  `aggregate_init` is now a model-owned aggregate semantic op and lowers
  typed-v2 operands into an aggregate value through layout-checked
  `insertvalue` construction. `frontier_aggregate_init_tuple_sum` proves a
  source-backed internal helper returning a constructed `{ usize, usize }`
  tuple, with the exported wrapper consuming the fields through scalar C ABI
  executable proof. The backend also handles the resulting register-aggregate
  helper call/spill/field-load/add shape without source-name admission. Strict
  frontier evidence in `tmp/frontier_aggregate_init.log` reports all three
  release modes at `source_rows=14`, `discovered_functions=728`,
  `generic_cfg_functions=728`, `object_emitted_functions=728`,
  `executable_ok_rows=14`, and `local_fail=0`. That cycle only added the
  minimal typed field-value consumer needed by the construction proof.
- [x] Lower aggregate projection from typed operands.

  `struct_field_val` over aggregate operands now lowers through the aggregate
  semantic domain with layout-checked field indexes and result types.
  `frontier_aggregate_projection_tuple_second` proves an internal aggregate
  parameter projection and scalar C ABI wrapper without function-name
  admission. Strict frontier evidence in
  `tmp/frontier_aggregate_projection.log` reports all three release modes at
  `source_rows=14`, `discovered_functions=730`,
  `generic_cfg_functions=730`, `object_emitted_functions=730`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Prove source-backed slice construction.

  Source-backed slice construction is proven by `frontier_slice_len_from_ptr`,
  `frontier_slice_internal_abi_checksum`, `frontier_slice_ptr_load`, and the
  checked/unchecked slice element rows in `frontier_slice_pointer_arith.zig`.
  These rows build `values[0..len]` slices from real Zig source, consume the
  resulting `{ ptr, len }` value through length extraction, pointer extraction,
  internal Zig slice ABI calls, load/store, and bounds-checked element access.
  Latest strict frontier evidence in `tmp/frontier_aggregate_projection.log`
  keeps all three release modes green at `source_rows=14`,
  `discovered_functions=730`, `generic_cfg_functions=730`,
  `object_emitted_functions=730`, `executable_ok_rows=14`, and
  `local_fail=0`.
- [x] Prove source-backed array-to-slice conversion.

  Source-backed array-to-slice conversion is proven by
  `frontier_array_to_slice_len` and `frontier_array_to_slice_runtime_load` in
  `frontier_slice_pointer_arith.zig`. Both rows use real Zig coercion from
  `*const [4]i32` to `[]const i32`; the first proves the derived slice length
  and the second proves a runtime-index load through the converted slice. The
  rows remain covered by the latest strict frontier evidence in
  `tmp/frontier_aggregate_projection.log` at `source_rows=14`,
  `discovered_functions=730`, `generic_cfg_functions=730`,
  `object_emitted_functions=730`, `executable_ok_rows=14`, and
  `local_fail=0`.
- [x] Prove source-backed aggregate projection after construction.

  `frontier_aggregate_projection_tuple_second` constructs a `{ usize, usize }`
  tuple from source operands, passes it to an internal Zig helper, projects
  field `1` through typed `struct_field_val`, and verifies the projected value
  through the C executable harness. This proves aggregate construction and
  projection as a connected source-backed flow. Strict frontier evidence in
  `tmp/frontier_aggregate_projection.log` reports all three release modes at
  `source_rows=14`, `discovered_functions=730`,
  `generic_cfg_functions=730`, `object_emitted_functions=730`,
  `executable_ok_rows=14`, and `local_fail=0`.
- [x] Keep unsupported aggregate element/layout forms fail-closed.

  Unsupported packed/unaligned aggregate ABI forms remain boundary-owned by
  `frontier_packed_aggregate_boundary.zig`. The boundary gate keeps them out
  of accepted frontier proof with targeted `UnsupportedPackedAggregateAbi`
  diagnostics. Latest saved boundary evidence in
  `tmp/frontier_aggregate_projection_boundaries.log` reports
  `packed_aggregate_boundary_rows=2`, `wrong_diagnostic_rows=0`, and
  `local_fail=0` across ReleaseFast, ReleaseSafe, and ReleaseSmall.
- [x] Refresh inventory and show the aggregate-shape bucket reduced.

  ReleaseFast compiler-core-module inventory was refreshed in
  `tmp/compiler_core_module_releasefast_after_aggregate730.log`. The measured
  `aggregate-shape` unknown bucket is now `count=0`; the prior
  `array_to_slice:ty_op count=5940` bucket is no longer an unknown blocker.
  Raw aggregate-family opcodes remain visible for prioritization, including
  `aggregate_init count=19914`, `slice_len count=13774`,
  `struct_field_val count=9933`, and `array_to_slice count=5940`, but these are
  classified as known/supported surfaces rather than unknown aggregate-shape
  blockers. The next measured unknown implementation family is union-tag shape:
  `get_union_tag:ty_op count=6057`, `union_init:opaque count=4624`,
  `set_union_tag:bin_op count=3020`, and `tag_name:opaque count=807`.

### 5. Union-Tag Shape

Layer: semantic lowering and CFG lowering.

- [x] Lower `get_union_tag`.

  `get_union_tag` is now a union-tag semantic opcode in the capability
  registry. The Zig typed-v2 exporter emits the narrow
  `zllvm-union-tag-facts-v1` `bit_width` fact for the tag result, and
  z_llvm consumes it through `TypedUnionTagGetSummary` in the split union-tag
  model. The typed lowerer accepts scalar tag values with supported integer
  widths and fails closed for raw aggregate union operands until the follow-up
  `set_union_tag` and `union_init` items own construction/layout. This cycle
  does not refresh compiler-core inventory; the measured pre-cycle bucket
  remains `get_union_tag:ty_op count=6057` in
  `tmp/compiler_core_module_releasefast_after_aggregate730.log` until the
  family refresh item runs. Validation:
  `tmp/get_union_tag_build_test.log` and `tmp/frontier_get_union_tag.log`.
  The stage4 emitter check was attempted in
  `tmp/check_stage4_get_union_tag_after_commit_direct.log` but is blocked by
  the pre-existing stage4 binary/`../ziglang` HEAD mismatch after hook commit
  `b45a663b8`.
- [x] Lower `set_union_tag`.

  `set_union_tag` now uses the same `zllvm-union-tag-facts-v1` typed-v2
  contract as `get_union_tag`: the Zig exporter emits `tag_index` and
  `bit_width`, and z_llvm records the selected scalar tag in a synthetic
  union-tag slot. Loads from that slot can feed `get_union_tag` for tag-only
  ownership while payload-bearing union layouts remain fail-closed for the
  later payload-read and `union_init` checklist items. Validation:
  `tmp/set_union_tag_build_test.log` and `tmp/frontier_set_union_tag.log`.
- [ ] Lower `union_init`.
- [ ] Lower `tag_name` or classify it as a runtime/string boundary.
- [ ] Lower payload reads guarded by tag checks.
- [ ] Lower switch over a union tag.
- [ ] Lower branch over a union tag.
- [ ] Prove one tag-only executable row.
- [ ] Prove one tag-plus-payload executable row.
- [ ] Keep unsupported payload layouts and inactive-payload reads fail-closed.
- [ ] Refresh inventory and show the union-tag bucket reduced.

### 6. Optional Shape

Layer: semantic lowering and CFG lowering.

- [ ] Lower generic `wrap_optional`.
- [ ] Lower optional payload extraction.
- [ ] Lower optional pointer checks.
- [ ] Lower optional pointer payload extraction.
- [ ] Lower optional branch/merge flows.
- [ ] Lower optional return/catch-style flows that appear in compiler-core
  inventory.
- [ ] Prove one optional scalar executable row.
- [ ] Prove one optional pointer executable row.
- [ ] Keep unsupported nested optional/error-union mixes fail-closed until
  modeled.
- [ ] Refresh inventory and show the optional-shape bucket reduced.

### 7. Safety Runtime Paths

Layer: safety-edge CFG and runtime boundary.

- [ ] Lower or classify `add_with_overflow`.
- [ ] Lower or classify `sub_with_overflow`.
- [ ] Lower or classify `mul_with_overflow`.
- [ ] Lower or classify `shl_with_overflow`.
- [ ] Lower checked integer cast paths used by ReleaseSafe.
- [ ] Lower checked shift/exact arithmetic paths used by ReleaseSafe.
- [ ] Prove one non-trapping executable row.
- [ ] Prove one trapping row with child-process death checks when practical.
- [ ] Keep cold panic/runtime helper ownership explicit.
- [ ] Refresh ReleaseSafe inventory and show the safety-runtime bucket reduced
  or reclassified.

### 8. Scalar Transforms

Layer: semantic lowering and backend.

- [ ] Broaden `byte_swap` beyond selected widths if inventory still shows it.
- [ ] Broaden `max` beyond selected signed `i32`.
- [ ] Broaden `min` beyond selected signed `i32`.
- [ ] Broaden `abs` beyond selected signed `i32`, with non-integer facts
  fail-closed.
- [ ] Lower `clz`.
- [ ] Lower `ctz`.
- [ ] Lower `popcount`.
- [ ] Lower `bit_reverse`.
- [ ] Lower `shl_exact`.
- [ ] Lower `shr_exact`.
- [ ] Lower integer `neg`.
- [ ] Prove signed and unsigned width variants where compiler-core inventory
  shows both.
- [ ] Refresh inventory and show scalar-transform buckets reduced.

### 9. Vector Forms

Layer: ABI planner and backend.

- [ ] Decide the supported first vector element types and widths.
- [ ] Lower a narrow `shuffle_one` subset.
- [ ] Lower `splat` for the selected vector subset.
- [ ] Lower `reduce` for the selected vector subset.
- [ ] Add fail-closed diagnostics for unsupported vector widths.
- [ ] Add fail-closed diagnostics for unsupported element types.
- [ ] Prove one source-backed vector executable row if ABI-stable.
- [ ] Otherwise prove object/native-link boundary diagnostics.
- [ ] Refresh inventory and show the vector bucket reduced or reclassified.

### 10. Packed Aggregates

Layer: ABI planner and backend.

- [ ] Separate aligned packed aggregates from unaligned/bitfield-like forms.
- [ ] Implement common aligned packed aggregate loads.
- [ ] Implement common aligned packed aggregate stores.
- [ ] Implement common aligned packed aggregate call arguments.
- [ ] Keep unaligned or target-sensitive forms fail-closed.
- [ ] Prove one aligned packed aggregate executable row.
- [ ] Refresh inventory and show the packed-aggregate bucket reduced or
  reclassified.

### 11. Float Math

Layer: backend and runtime boundary.

- [ ] Classify each float builtin as local lowering, runtime call, or explicit
  boundary.
- [ ] Lower or call-boundary `sqrt`.
- [ ] Lower or call-boundary `floor`.
- [ ] Lower or call-boundary `ceil`.
- [ ] Lower or call-boundary `round`.
- [ ] Lower or call-boundary `trunc_float`.
- [ ] Classify `exp`, `exp2`, `log`, `log2`, and `log10`.
- [ ] Classify `sin`, `cos`, and `tan`.
- [ ] Prove one local-lowered executable row or one explicit runtime-call
  boundary row.
- [ ] Refresh inventory and show float-math buckets reduced or reclassified.

### 12. Select Shape

Layer: semantic lowering and CFG lowering.

- [ ] Lower scalar integer `select`.
- [ ] Lower pointer `select`.
- [ ] Lower boolean/select condition normalization.
- [ ] Keep vector `select` with the vector family.
- [ ] Prove one source-backed scalar executable row.
- [ ] Refresh inventory and show the select-shape bucket reduced.

### 13. x87 Surfaces

Layer: ABI planner and backend boundary.

- [ ] Identify concrete x87 source/type surfaces from refreshed inventory.
- [ ] Decide explicit boundary vs limited lowering for distribution-relevant
  uses.
- [ ] Add fail-closed diagnostics for unsupported x87 forms.
- [ ] If limited support is chosen, prove one object/native-link row.
- [ ] Refresh inventory and show the x87 bucket reduced or reclassified.

### 14. Varargs

Layer: ABI planner and call lowering.

- [ ] Identify concrete varargs source surfaces from refreshed inventory.
- [ ] Decide whether z_llvm owns varargs lowering or keeps a C ABI handoff
  boundary.
- [ ] Add fail-closed diagnostics for unsupported varargs forms.
- [ ] Prove one boundary row or one supported varargs object/native-link row.
- [ ] Refresh inventory and show the varargs bucket reduced or reclassified.

### 15. Inline Asm

Layer: CFG lowering and backend boundary.

- [ ] Identify concrete inline asm surfaces from refreshed inventory.
- [ ] Preserve strict fail-closed diagnostics by default.
- [ ] Implement only if a real x86_64 distribution row requires support.
- [ ] If implemented, start with a minimal no-output/no-clobber form.
- [ ] Refresh inventory and show the inline-asm bucket reduced or reclassified.

### 16. Debug Metadata

Layer: metadata policy.

- [ ] Keep debug metadata outside codegen replacement counters.
- [ ] Keep transform skip/salvage policy explicit.
- [ ] Ensure debug metadata does not hide executable/codegen failures.
- [ ] Add diagnostics if debug metadata suppresses a transform pass.

## Per-Family Worker Template

For each unchecked family:

1. Refresh or read the latest focused inventory evidence for one mode first.
2. Pick the highest-count concrete pair with a real source-backed shape.
3. Add narrow typed-v2 hook facts in `../ziglang` only if z_llvm cannot derive
   the semantic operands safely.
4. Implement reusable z_llvm model/lowering/backend support.
5. Add 2-3 representative frontier rows, including one negative or boundary row
   when the family has unsupported subforms.
6. Prove the row with the focused frontier gate and object/native-link/executable
   checks.
7. Update counters and this checklist only after the relevant inventory bucket
   drops or is explicitly reclassified.

## Suggested Order

1. Error-union try/wrap/unwrap.
2. Pointer/slice/address forms.
3. Aggregate ABI at scale.
4. Aggregate-shape ops.
5. Union-tag shape.
6. Optional shape.
7. Safety runtime paths.
8. Scalar transforms.
9. Vector forms.
10. Packed aggregates.
11. Float math.
12. x87, varargs, inline asm, and debug metadata policy closure.
