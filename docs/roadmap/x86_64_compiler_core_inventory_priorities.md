# x86_64 Compiler-Core Inventory Priorities

This report ranks implementation priorities from the body-aware
`compiler-core-module` inventory. It is count-only evidence from:

```sh
zig build distribution-zig-air-inventory -- --slice=compiler-core-module
```

That all-mode command is milestone-cost. Normal worker cycles should refresh a
single mode, for example:

```sh
zig build distribution-zig-air-inventory -- --slice=compiler-core-module --mode=ReleaseFast
```

The selected-mode summary lines use the same format as the all-mode output.
Inventory logs must contain a complete summary for the selected mode; empty or
incomplete logs are not evidence.

It does not claim lowering, object emission, native linking, or executable
proof. The slice uses the real `../ziglang/build.zig` compiler executable
module graph with generated imports available, no stubs, and
`instruction_payload_scan=1`.

## Body-Aware Totals

| Mode | Functions | Instructions | Calls | Branches | Loops | Switches | Loads | Stores | Stack slots | Unsupported functions | Unsupported opcodes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 61341 | 6291825 | 330045 | 1037603 | 25436 | 15599 | 589168 | 315333 | 372519 | 56231 | 367030 |
| ReleaseSafe | 61951 | 6842493 | 414768 | 1243546 | 25710 | 15618 | 598366 | 317492 | 385116 | 57216 | 407240 |
| ReleaseSmall | 59837 | 4178468 | 324995 | 981856 | 24996 | 15463 | 577888 | 310553 | 366867 | 54849 | 333877 |

## Top Unsupported Categories

These rows are sorted by count in the inventory output. `first_source` and
`first_function` are emitted by the inventory scanner for each unsupported
category.

| Category | ReleaseFast | ReleaseSafe | ReleaseSmall | First source | First function | Current status | Likely layer |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| aggregate-abi | 2256445 | 2338212 | 2206792 | `../ziglang/src/main.zig` | `global` | partially supported | semantic lowering, ABI planner, backend |
| unknown-opcode | 367030 | 407240 | 333877 | `../ziglang/src/main.zig` | `start.posixCallMainAndExit` | partially supported | AIR parser, CFG lowering |
| vector | 15820 | 16024 | 15808 | `../ziglang/src/main.zig` | `global` | unsupported boundary | ABI planner, backend |
| x87 | 6194 | 6220 | 6550 | `../ziglang/src/main.zig` | `global` | unsupported boundary | ABI planner, backend |
| packed-aggregate | 5039 | 5548 | 4863 | `../ziglang/src/main.zig` | `global` | unsupported boundary | ABI planner, backend |
| varargs | 738 | 745 | 827 | `../ziglang/src/main.zig` | `global` | unsupported boundary | ABI planner, call lowering |
| inline-asm | 21 | 22 | 20 | `../ziglang/src/main.zig` | `start._start` | partially supported boundary | CFG lowering, backend |

## Aggregate Surface Split

The inventory scanner now emits `aggregate_surface` lines and matching summary
fields:

- `aggregate_opcode_shapes`: aggregate-producing AIR opcodes.
- `aggregate_metadata_type_surfaces`: aggregate type text seen in globals,
  data kinds, operands, details, and other non-ABI metadata surfaces.
- `aggregate_abi_type_surfaces`: aggregate type text seen in function
  signatures and call/return/argument instruction contexts.

This preserves the existing `aggregate_types` and
`unsupported category=aggregate-abi` totals for compatibility while giving the
next implementation slice a cleaner signal. The old compiler-core-module
baseline above predates these split counters; the latest focused validation of
the output contract is:

| Slice | Mode | aggregate_opcode_shapes | aggregate_metadata_type_surfaces | aggregate_abi_type_surfaces | Log |
| --- | --- | ---: | ---: | ---: | --- |
| runtime-libs | ReleaseFast | 10118 | 43101 | 19497 | `tmp/runtime_libs_aggregate_surface_inventory.log` |
| runtime-libs | ReleaseSafe | 10179 | 47078 | 20214 | `tmp/runtime_libs_aggregate_surface_inventory.log` |
| runtime-libs | ReleaseSmall | 4964 | 23801 | 10554 | `tmp/runtime_libs_aggregate_surface_inventory.log` |
| compiler-core-module | ReleaseFast | 410592 | 1325299 | 931146 | `tmp/compiler_core_module_releasefast_inventory.log` |
| compiler-core-standalone-probe | ReleaseFast | 0 | 85 | 2 | `tmp/compiler_core_standalone_aggregate_surface_inventory.log` |
| compiler-core-standalone-probe | ReleaseSafe | 0 | 85 | 2 | `tmp/compiler_core_standalone_aggregate_surface_inventory.log` |
| compiler-core-standalone-probe | ReleaseSmall | 0 | 0 | 0 | `tmp/compiler_core_standalone_aggregate_surface_inventory.log` |

The full `compiler-core-module` all-mode refresh remains milestone-cost. The
ReleaseFast per-mode refresh completed in
`tmp/compiler_core_module_releasefast_inventory.log`; ReleaseSafe and
ReleaseSmall should be refreshed separately with `--mode` when their counters
need the same split.

## Unknown Opcode Split

The inventory also emits `unknown_opcode` and ranked `top_unknown_opcode`
records. These keep the old `unknown-opcode` total intact while splitting the
work queue into stable implementation families. It also emits
`top_unknown_opcode_pair` records keyed by `subcategory:opcode:data_kind` so
implementation slices can target concrete AIR shapes.

| Subcategory | ReleaseFast | ReleaseSafe | ReleaseSmall | First source | First function | Current status | Likely layer |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| error-union-try | 236821 | 238174 | 231997 | `../ziglang/src/main.zig` | `start.posixCallMainAndExit` | partially supported | semantic lowering, CFG lowering |
| pointer-address | 50417 | 59226 | 49313 | `../ziglang/src/main.zig` | `start.posixCallMainAndExit` | partially supported | typed AIR parser, address-form lowering |
| aggregate-shape | 30599 | 64537 | 29881 | `../ziglang/src/main.zig` | `start.posixCallMainAndExit` | partially supported | aggregate semantic lowering, ABI planner |
| vector | 26132 | not refreshed | not refreshed | `../ziglang/src/main.zig` | `Io.Writer.print__anon_39654` | unsupported boundary | ABI planner, backend |
| union-tag-shape | 14507 | not refreshed | not refreshed | `../ziglang/src/main.zig` | `print_targets.cmdTargets` | partially supported | semantic lowering, CFG lowering |
| optional-shape | 6454 | not refreshed | not refreshed | `../ziglang/src/main.zig` | `SemanticVersion.parse` | partially supported | semantic lowering, CFG lowering |
| other | 1956 | 33949 | 22545 | `../ziglang/src/main.zig` | `main.buildOutputType` / `debug.FullPanic((function 'panicImpl')).reachedUnreachable` | needs next split | AIR parser, capability registry |
| safety-runtime | 144 | 11354 | 141 | `../ziglang/src/main.zig` | `math.sub__anon_41274` / `os.linux.tls.initStatic` | partially supported | safety-edge CFG, runtime boundary |
| call-shape | 0 | 0 | 0 | - | - | no measured unknown rows | ABI planner |
| debug-metadata | 0 | 0 | 0 | - | - | handled outside unknown-opcode | metadata skip policy |
| memory-shape | 0 | 0 | 0 | - | - | no measured unknown rows | memory lowering |
| switch-dispatch | 0 | 0 | 0 | - | - | no measured unknown rows | switch CFG lowering |

### Top Concrete Unknown Opcode/Data-Kind Pairs

| Rank | ReleaseFast | Count | ReleaseSafe | Count | ReleaseSmall | Count |
| ---: | --- | ---: | --- | ---: | --- | ---: |
| 1 | `error-union-try:unwrap_errunion_err:ty_op` | 84377 | `error-union-try:unwrap_errunion_err:ty_op` | 84913 | `error-union-try:unwrap_errunion_err:ty_op` | 82350 |
| 2 | `error-union-try:wrap_errunion_err:ty_op` | 76608 | `error-union-try:wrap_errunion_err:ty_op` | 77020 | `error-union-try:wrap_errunion_err:ty_op` | 75165 |
| 3 | `error-union-try:try:pl_op` | 73606 | `error-union-try:try:pl_op` | 73993 | `error-union-try:try:pl_op` | 72265 |
| 4 | `vector:shuffle_one:opaque` | 26122 | `aggregate-shape:slice_len:ty_op` | 47605 | `pointer-address:ptr_slice_len_ptr:ty_op` | 17069 |
| 5 | `pointer-address:ptr_slice_len_ptr:ty_op` | 17458 | `pointer-address:ptr_add:bin_ty_pl` | 19156 | `pointer-address:ptr_add:bin_ty_pl` | 13966 |
| 6 | `aggregate-shape:slice_len:ty_op` | 13768 | `pointer-address:ptr_slice_len_ptr:ty_op` | 17506 | `aggregate-shape:slice_len:ty_op` | 13459 |
| 7 | `pointer-address:slice_ptr:ty_op` | 11920 | `pointer-address:slice_ptr:ty_op` | 14429 | `pointer-address:slice_ptr:ty_op` | 11615 |
| 8 | `aggregate-shape:slice:bin_ty_pl` | 10895 | `safety-runtime:intcast_safe:ty_op` | 11185 | `aggregate-shape:slice:bin_ty_pl` | 10603 |
| 9 | `optional-shape:wrap_optional:ty_op` | 6454 | `aggregate-shape:slice:bin_ty_pl` | 10942 | `other:wrap_optional:ty_op` | 6359 |
| 10 | `pointer-address:ptr_slice_ptr_ptr:ty_op` | 6343 | `other:get_union_tag:opaque` | 10923 | `pointer-address:ptr_slice_ptr_ptr:ty_op` | 6250 |
| 11 | `union-tag-shape:get_union_tag:opaque` | 6057 | - | - | - | - |
| 12 | `union-tag-shape:union_init:opaque` | 4624 | - | - | - | - |

## Top Opcode Categories

The inventory now emits `top_opcode` lines for each mode. These are the highest
body opcode counts, not necessarily the highest implementation gaps.

| Rank | ReleaseFast | Count | ReleaseSafe | Count | ReleaseSmall | Count |
| ---: | --- | ---: | --- | ---: | --- | ---: |
| 1 | `dbg_stmt` | 1583492 | `dbg_stmt` | 1608158 | `load` | 577785 |
| 2 | `load` | 589064 | `load` | 598263 | `block` | 461641 |
| 3 | `block` | 483000 | `block` | 552975 | `br` | 412562 |
| 4 | `br` | 444826 | `br` | 514565 | `alloc` | 366867 |
| 5 | `alloc` | 372519 | `call` | 414768 | `call` | 324995 |
| 6 | `call` | 330045 | `alloc` | 385116 | `store` | 310553 |
| 7 | `store` | 315333 | `bitcast` | 296563 | `bitcast` | 286673 |
| 8 | `bitcast` | 291356 | `store_safe` | 268309 | `ret` | 167333 |
| 9 | `dbg_var_val` | 180148 | `dbg_var_val` | 181555 | `arg` | 122648 |
| 10 | `ret` | 170547 | `ret_safe` | 171372 | `struct_field_ptr_index_0` | 95363 |
| 11 | `dbg_empty_stmt` | 157346 | `dbg_empty_stmt` | 159305 | `cond_br` | 88955 |
| 12 | `arg` | 126700 | `cond_br` | 157143 | `unwrap_errunion_err` | 82350 |
| 13 | `struct_field_ptr_index_0` | 97671 | `arg` | 127909 | `struct_field_ptr_index_1` | 75810 |
| 14 | `cond_br` | 90901 | `struct_field_ptr_index_0` | 98304 | `wrap_errunion_err` | 75165 |
| 15 | `unwrap_errunion_err` | 84331 | `unwrap_errunion_err` | 84913 | `try` | 72265 |
| 16 | `struct_field_ptr_index_1` | 76728 | `unreach` | 83385 | `struct_field_ptr` | 56798 |
| 17 | `wrap_errunion_err` | 76578 | `struct_field_ptr_index_1` | 77145 | `intcast` | 35112 |
| 18 | `try` | 73577 | `wrap_errunion_err` | 77020 | `ptr_elem_ptr` | 32764 |
| 19 | `struct_field_ptr` | 57065 | `try` | 73993 | `struct_field_ptr_index_2` | 32055 |
| 20 | `dbg_var_ptr` | 40506 | `struct_field_ptr` | 57316 | `add` | 31985 |

## Top Data-Kind Categories

The inventory also emits `top_data_kind` lines. These are useful for deciding
whether the next work belongs in typed AIR parsing, semantic lowering, CFG
lowering, or backend codegen.

| Rank | ReleaseFast | Count | ReleaseSafe | Count | ReleaseSmall | Count |
| ---: | --- | ---: | --- | ---: | --- | ---: |
| 1 | `opaque` | 2940665 | `opaque` | 3136464 | `ty_op` | 1157348 |
| 2 | `ty_op` | 1179404 | `ty_op` | 1231897 | `opaque` | 917410 |
| 3 | `br` | 444826 | `br` | 514565 | `br` | 412562 |
| 4 | `call` | 330045 | `call` | 414768 | `call` | 324995 |
| 5 | `store` | 315333 | `store` | 317492 | `store` | 310553 |
| 6 | `field_ptr` | 292995 | `field_ptr` | 294691 | `field_ptr` | 288670 |
| 7 | `un_op` | 196616 | `un_op` | 202603 | `un_op` | 192404 |
| 8 | `bin_op` | 132239 | `bin_op` | 196878 | `bin_op` | 127867 |
| 9 | `arg` | 126700 | `cond_br` | 157143 | `arg` | 122648 |
| 10 | `cond_br` | 90901 | `arg` | 127909 | `cond_br` | 88955 |
| 11 | `bin_ty_pl` | 88910 | `bin_ty_pl` | 94154 | `bin_ty_pl` | 83902 |
| 12 | `pl_op` | 74418 | `pl_op` | 74849 | `pl_op` | 73103 |
| 13 | `elem` | 33961 | `elem` | 34077 | `elem` | 33914 |
| 14 | `aggregate_init` | 19892 | `aggregate_init` | 20161 | `aggregate_init` | 19817 |
| 15 | `repeat` | 12706 | `repeat` | 12846 | `repeat` | 12490 |
| 16 | `ret_load` | 5879 | `ret_load` | 5910 | `ret_load` | 5826 |
| 17 | `ret_ptr` | 5879 | `ret_ptr` | 5910 | `ret_ptr` | 5826 |
| 18 | `atomic_load` | 104 | `atomic_load` | 103 | `atomic_load` | 103 |
| 19 | `ty_nav` | 41 | `ty_nav` | 40 | `ty_nav` | 41 |
| 20 | `ty_pl` | 35 | `ty_pl` | 33 | `ty_pl` | 34 |

## Generic CFG Comparison

The current strict selected release gates prove typed AIR v2 and generic CFG
ownership for much smaller accepted corpora: broad has 152 functions, expanded
has 199, scale has 216, and the isolated frontier has 599. Those gates prove
the path works for selected source rows, while this inventory shows the
compiler module graph has roughly 60k functions and 4.1M-6.8M instructions per
release mode.

Comparison by category:

| Category | Current generic CFG support | Compiler-core implication |
| --- | --- | --- |
| blocks, branches, returns | supported for selected frontier forms | needs scale hardening across 0.98M-1.24M branch-like occurrences |
| calls | partially supported through the x86_64 SysV planner | compiler graph has 325k-415k calls and will stress indirect, attrs, runtime, and live-across-call forms |
| loads/stores/stack slots | partially supported | compiler graph has about 0.58M loads and 0.31M stores per mode, plus about 0.37M stack slots |
| struct fields and aggregates | partially supported | largest unsupported category; needs type-aware aggregate filtering plus broader ABI/layout lowering |
| error unions and `try` | partially supported | `try`, `unwrap_errunion_err`, and wrap operations are high-volume compiler idioms |
| pointers/slices/optionals | partially supported | high aggregate counts show many forms beyond the selected frontier |
| debug opcodes | metadata skip/boundary | ReleaseFast and ReleaseSafe still carry very high `dbg_*` opcode volume in typed AIR exports |
| vectors, X87/f128, packed aggregates, varargs | explicit fail-closed boundaries | keep as boundaries unless deliberately scoped subsets are implemented |
| inline asm | partially supported boundary | compiler startup has explicit inline-asm examples such as `start._start` |

## Ranked Top 20 Implementation Blockers

This ranking combines raw inventory counts with current replacement status. It
is not a promise that every row should be implemented in order; it is the
body-backed work queue for the next x86_64 compiler-core replacement frontier.
Rows with `-` in the first-example column are high-volume supported opcode
families where the inventory does not yet record per-opcode first examples.

| Rank | Category/opcode | ReleaseFast | ReleaseSafe | ReleaseSmall | First source/function | Status | Likely implementation layer |
| ---: | --- | ---: | ---: | ---: | --- | --- | --- |
| 1 | aggregate-abi | 2256445 | 2338212 | 2206792 | `../ziglang/src/main.zig` / `global` | partially supported | semantic lowering, ABI planner, backend |
| 2 | unknown-opcode: error-union-try | 236821 | 238174 | 231997 | `../ziglang/src/main.zig` / `start.posixCallMainAndExit` | partially supported | semantic lowering, CFG lowering |
| 3 | `dbg_stmt` / debug metadata | 1582916 | 1608158 | 0 | - | runtime/metadata boundary | AIR parser, verifier policy |
| 4 | `load` | 588943 | 598263 | 577785 | - | supported subset | CFG lowering, backend |
| 5 | `block` | 482697 | 552975 | 461641 | - | supported subset | CFG lowering |
| 6 | `br` | 444541 | 514565 | 412562 | - | supported subset | CFG lowering |
| 7 | `call` | 330045 | 414768 | 324995 | - | partially supported | ABI planner, backend, runtime boundary |
| 8 | `alloc` / stack slots | 372427 | 385116 | 366867 | - | partially supported | CFG lowering, stack frame layout |
| 9 | `store` / `store_safe` | 315284 | 317492 | 310553 | - | partially supported | CFG lowering, ReleaseSafe safety edges |
| 10 | `bitcast` | 291270 | 296563 | 286673 | - | partially supported | semantic lowering, backend |
| 11 | field pointer data kind | 292995 | 294691 | 288670 | - | partially supported | semantic lowering, address-form lowering |
| 12 | `cond_br` | 90901 | 157143 | 88955 | - | supported subset | CFG lowering, safety-edge lowering |
| 13 | `arg` | 126700 | 127909 | 122648 | - | supported subset | AIR parser, ABI planner |
| 14 | unknown-opcode: pointer-address | 50417 | 59226 | 49313 | `../ziglang/src/main.zig` / `start.posixCallMainAndExit` | partially supported | typed AIR parser, address-form lowering |
| 15 | `struct_field_ptr_index_0` | 97671 | 98304 | 95363 | - | partially supported | aggregate layout, address-form lowering |
| 16 | vector | 15820 | 16024 | 15808 | `../ziglang/src/main.zig` / `global` | unsupported boundary | ABI planner, backend |
| 17 | X87/f80/f128 | 6194 | 6220 | 6550 | `../ziglang/src/main.zig` / `global` | unsupported boundary | ABI planner, backend |
| 18 | packed-aggregate | 5039 | 5548 | 4863 | `../ziglang/src/main.zig` / `global` | unsupported boundary | ABI planner, object emission |
| 19 | varargs | 738 | 745 | 827 | `../ziglang/src/main.zig` / `global` | unsupported boundary | ABI planner, call lowering |
| 20 | inline-asm | 21 | 22 | 20 | `../ziglang/src/main.zig` / `start._start` | partially supported boundary | CFG lowering, backend |

## Recommended Next Work

1. Refresh `compiler-core-module` inventory with the new `aggregate_surface`
   split one mode at a time using `--mode=ReleaseFast`,
   `--mode=ReleaseSafe`, and `--mode=ReleaseSmall`; then prioritize the
   measured `abi-type-surface` aggregate rows before metadata-only type
   surfaces. Until those complete summaries exist, keep using the saved
   compiler-core-module totals above for broad priority ordering.
2. Continue converting concrete `unknown-opcode` pairs into source-backed
   compiler-core frontier rows. The first error-union slice is now accepted:
   `frontier_optionals_errors.zig` covers `wrap_errunion_payload`,
   `wrap_errunion_err`, `is_non_err`, `unwrap_errunion_payload`, and
   `unwrap_errunion_err` with executable proof, and the follow-up slice adds
   selected direct `try:pl_op` propagation for an error-union helper call with
   payload continuation and error return. Follow-up frontier rows now cover a
   direct two-`try` chain where the wrapper calls once, preserves the
   error-union result for payload extraction, and the nested callee preserves
   live arguments/results across the second helper call, plus a `try`
   continuation whose payload feeds a second branch before both terminal arms
   rewrap payload-derived values. Broader arbitrary nested/multi-block
   compiler-core `try` forms remain measured error-union work; pointer/slice
   length forms and `ptr_add:bin_ty_pl` remain the next non-error-union targets.
3. Harden generic CFG for high-volume compiler patterns: nested blocks,
   branch-heavy loops, error-union continuation blocks, and switch dispatch.
4. Expand call ownership around live-across-call values, indirect/default C
   calls, call attributes, and runtime boundary classification.
5. Keep vector, X87/f128, packed/unaligned aggregate, and varargs rows as
   explicit fail-closed boundaries until a scoped implementation slice is
   chosen.
