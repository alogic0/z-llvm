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
- [ ] Lower struct returns through sret memory.
- [ ] Lower array arguments and returns.
- [ ] Lower slice arguments and returns as `{ ptr, len }` aggregates.
- [ ] Lower aggregate field/payload reads used after calls.
- [ ] Lower aggregate field/payload writes before calls.
- [ ] Prove at least one direct-call aggregate row.
- [ ] Prove at least one returned-aggregate row.
- [ ] Prove at least one aggregate field/payload executable row.
- [ ] Keep unsupported packed/unaligned/oversized forms fail-closed.
- [ ] Refresh inventory and show the aggregate ABI bucket reduced or
  reclassified.

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

- [ ] Lower `ptr_slice_len_ptr`.
- [ ] Lower `ptr_slice_ptr_ptr`.
- [ ] Lower `slice_ptr`.
- [ ] Lower `ptr_add`.
- [ ] Lower `ptr_sub`.
- [ ] Lower `is_non_null_ptr` from a real source shape.
- [ ] Lower `runtime_nav_ptr` or classify it as a runtime boundary.
- [ ] Prove pointer arithmetic with load/store.
- [ ] Prove slice pointer extraction.
- [ ] Prove slice length extraction.
- [ ] Prove pointer/slice values across a branch merge.
- [ ] Keep unsupported address spaces and volatile/atomic pointer forms
  fail-closed.
- [ ] Refresh inventory and show the pointer-address bucket reduced.

### 4. Aggregate-Shape Ops

Layer: aggregate semantic lowering.

- [ ] Lower `slice_len`.
- [ ] Lower `slice`.
- [ ] Lower `array_to_slice`.
- [ ] Lower aggregate construction from typed operands.
- [ ] Lower aggregate projection from typed operands.
- [ ] Prove source-backed slice construction.
- [ ] Prove source-backed array-to-slice conversion.
- [ ] Prove source-backed aggregate projection after construction.
- [ ] Keep unsupported aggregate element/layout forms fail-closed.
- [ ] Refresh inventory and show the aggregate-shape bucket reduced.

### 5. Union-Tag Shape

Layer: semantic lowering and CFG lowering.

- [ ] Lower `get_union_tag`.
- [ ] Lower `set_union_tag`.
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
