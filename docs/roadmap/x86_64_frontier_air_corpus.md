# x86_64 Frontier AIR Corpus

The frontier corpus is separate from the cumulative broad, expanded, and scale
gates. It exists to admit new real Zig source rows under
`test/zig/frontier/*.zig` without weakening any closed baseline.

Current corpus coverage:

- `distribution-zig-air-uncurated-release` covers `test/zig/inputs/*.zig`.
- Broad covers `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`.
- Expanded covers broad plus `test/zig/expanded/*.zig`.
- Scale covers expanded plus `test/zig/scale/*.zig`.
- Frontier covers only `test/zig/frontier/*.zig`.

Still excluded from real-AIR release gates:

- `.ll` fixtures under `test/zig/captured` and `test/zig/expected`.
- Debug, AArch64, LTO, libc-heavy programs, and non-release modes.
- Broader upstream Zig test directories until they are added through an
  explicit audited bucket.

Current frontier seed:

- `test/zig/frontier/frontier_branch_memory.zig`
- `test/zig/frontier/frontier_comptime_constants.zig`
- `test/zig/frontier/frontier_globals_tls.zig`
- `test/zig/frontier/frontier_helper_graph.zig`
- `test/zig/frontier/frontier_mixed_numeric.zig`
- `test/zig/frontier/frontier_nested_loops.zig`
- `test/zig/frontier/frontier_nested_records.zig`
- `test/zig/frontier/frontier_optionals_errors.zig`
- `test/zig/frontier/frontier_safety_edges.zig`
- `test/zig/frontier/frontier_slice_pointer_arith.zig`
- `test/zig/frontier/frontier_sysv_abi.zig`

Current ReleaseFast, ReleaseSafe, and ReleaseSmall counters:

```text
source_rows=11
discovered_functions=32
structured_functions=32
generic_codegen_functions=32
generic_cfg_functions=32
structural_matcher_functions=0
structured_air_v2_functions=32
typed_air_operand_functions=32
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=32
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=32
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection is green for all three modes:

```text
inspected=11
elf64_rel=11
relocation_rows=3
tls_rows=1
undefined_import_rows=0
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress is green for all three modes:

```text
native_link_accepted_rows=11
executable_ok_rows=0
link_only_rows=11
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Executable ABI proof is green for all three modes:

```text
native_link_accepted_rows=11
executable_ok_rows=11
link_only_rows=0
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Closed in the current memory/aggregate frontier slice:

- nested counted loop-memory CFG through
  `frontier_nested_memory_sum`
- selected nested extern-struct field GEP paths through
  `frontier_nested_field_left_b` and `frontier_nested_field_right_a`
- selected dynamic pointer addition and pointer-element GEP loads through
  `frontier_dynamic_ptr_add` and `frontier_dynamic_ptr_pair_sum`
- branch-local global/TLS add/sub updates through
  `frontier_global_branch` and `frontier_tls_branch`
- first SysV ABI closure-wave rows in `frontier_sysv_abi.zig`: small
  INTEGER/INTEGER aggregate return in `%rax`/`%rdx`, small aggregate field
  argument reads from the SysV integer register pair, and a two-live-i32
  direct-call frame that spills and reloads `%rdi`/`%rsi` around the call

Remaining measured frontier blockers kept out of accepted rows:

- mixed int-to-float plus multiply/add pipelines beyond the current selected
  FP binary subset
- private helper call graphs with more than two live integer values across
  calls or live values across multiple calls
- branch safety guards that return from the failure side rather than the
  current checked-runtime boundary shape
- broader unknown aggregate field, pointer arithmetic, and global/TLS address
  forms outside the selected scalar layouts
- full SysV aggregate classification, MEMORY/SSE/X87/packed aggregate ABI
  classes, arbitrary sret/byval copies, varargs, vectors, and high-register
  pressure spill/reload-heavy call frames

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
