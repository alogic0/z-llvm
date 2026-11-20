# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_candidates_releasefast_v1.log`
command: `zig build distribution-zig-air-inventory -- --slice=compiler-core-module --mode=ReleaseFast --real-candidates-tsv=docs/evidence/real_candidates_releasefast_v1.tsv`
z_llvm_commit: `4e6fec679480b2311a5c23e005d685f5a01a90f8`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
selector_version: `real-candidate-selector-v1`
mode: `ReleaseFast`
limit: `all`
ratchet_migration_note: `Refreshes the pre-pin ReleaseFast compiler-core-module unsupported_functions baseline from 55852 to 55479 using selector v1 and tracked Zig pin 141bfce0883017ff7ebe03e3af3db07fff0c5dc3; real-row ratchet counters remain unopened.`

## Summary Lines

```text
summary distribution-zig-air-inventory slice=compiler-core-module mode=ReleaseFast target=x86_64-linux-gnu sources=1 inventory_ok_sources=1 boundary_sources=0 standalone_source_probe=0 real_module_context=1 generated_imports_available=1 stubbed_imports=0 instruction_payload_scan=1 modules=1 functions=61386 functions_with_body=61386 declarations_without_body=0 instructions_total=6301418 exported_functions=93 generic_functions=38098 comptime_functions=38098 globals=59726 constant_globals=59570 tls_globals=16 extern_imports=0 runtime_symbols=4495 calls=330718 callconv_default=61375 callconv_c=7 callconv_other=4 varargs_uses=747 vector_uses=16322 x87_uses=6478 packed_unaligned_aggregate_uses=5392 atomics=620 inline_asm=87 loads=589710 stores=315532 allocas=372987 switches=15613 loops=25452 branches=1039770 aggregate_types=2739643 aggregate_opcode_shapes=410929 aggregate_metadata_type_surfaces=1395490 aggregate_abi_type_surfaces=933224 aggregate_layout_facts=5824 pointer_uses=3885612 slice_uses=905609 optional_uses=500125 error_union_uses=1007179 unsupported_functions=55479 unsupported_opcodes=911 local_fail=0
summary distribution-real-candidates selector_version=real-candidate-selector-v1 slice=compiler-core-module mode=ReleaseFast target=x86_64-linux-gnu path=docs/evidence/real_candidates_releasefast_v1.tsv rows=61386 harnessable_rows=2161 not_yet_analyzed_rows=2134 proven_unharnessable_rows=57091 local_fail=0
```
