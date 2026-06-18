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

Current ReleaseFast, ReleaseSafe, and ReleaseSmall counters:

```text
source_rows=10
discovered_functions=22
structured_functions=22
generic_codegen_functions=22
generic_cfg_functions=22
structural_matcher_functions=0
structured_air_v2_functions=22
typed_air_operand_functions=22
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=22
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=22
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection is green for all three modes:

```text
inspected=10
elf64_rel=10
relocation_rows=2
tls_rows=1
undefined_import_rows=0
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress is green for all three modes:

```text
native_link_accepted_rows=10
executable_ok_rows=0
link_only_rows=10
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Executable ABI proof is green for all three modes:

```text
native_link_accepted_rows=10
executable_ok_rows=10
link_only_rows=0
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

First measured frontier blockers kept out of accepted rows:

- nested counted loops with inner memory dependencies:
  `block/control_flow_shape`
- nested extern-struct field paths: `struct_field_ptr_index_0` lowering
  validation
- dynamic pointer addition and pointer-element GEP: `ptr_add` and
  `ptr_elem_ptr` lowering validation
- branch-local global/TLS updates with both add and subtract arms:
  x86_64 CFG control-flow eligibility
- mixed int-to-float plus multiply/add pipelines beyond the current selected
  FP binary subset
- private helper call graphs with live values across multiple calls
- branch safety guards that return from the failure side rather than the
  current checked-runtime boundary shape

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
