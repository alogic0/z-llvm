# x86_64 Source-Owned Descriptor Template Inventory

Current gate: `zig build distribution-x86_64-release-source-owned`

Measured state after promoting the release wrapper discovery bucket:

```text
release_source_rows=100
air_extracted_descriptor_rows=100
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
zig_compile_context_descriptor_rows=100
env_source_tag_selector_rows=0
wrapper_body_selector_rows=0
source_tag_body_selector_rows=0
fixture_metadata_selector_rows=0
source_tag_env_present_rows=0
descriptor_supported_wrappers=82
out_of_scope_wrappers=0
fact_derived_classification_rows=32
source_fact_program_rows=32
root_source_classification_fallback_rows=68
body_enum_fallback_rows=68
```

All rows still serialize DescriptorV2 records. All 100 rows now use the
separate extracted-record writer path with compile-context descriptor
provenance. The gate rejects `template_descriptor_rows`,
`wrapper_body_map_rows`, `source_tag_body_map_rows`,
`env_source_tag_selector_rows`, `wrapper_body_selector_rows`,
`source_tag_body_selector_rows`, `fixture_metadata_selector_rows`, and
`source_tag_env_present_rows` greater than zero. This is distinct from full
Zig Sema/AIR extraction, which remains
the target.

## Source Fact Program Split

The frozen `zllvm-source-facts-v1` contract is now parsed into a typed model
inside z_llvm. The release source-owned gate requires at least 30
fact-derived rows and currently measures 32. Those 32 rows enter the
`SourceFactProgram` bridge before DescriptorV2 lowering. The remaining 68 rows
still use z_llvm-side root-source classification fallback and are counted
separately as `body_enum_fallback_rows=68`.

This is the current v1 fact exhaustion point. The remaining rows should not
trigger row-specific Zig patches. If they cannot be derived from the frozen
facts, the next Zig-side change should be one deliberate
`zllvm-source-facts-v2` contract bump with generic records.

| Fallback family | Rows | Missing generic fact needed |
| --- | ---: | --- |
| Full and reduced base64 plus table-indexed load | 26 | Per-block terminators, loop latch/backedge shape, table/global initializer shape, byte-load/store opcodes, pointer index advancement, mask/shift/or opcodes, and residual/padding branch predicates |
| `strFromFloatHelp` | 1 | Concrete call target records, stack-slot/lifetime records, memcpy/memset records, i128 arithmetic/truncation opcodes, table-load records, and indirect/vtable call boundary records |
| Aggregate, pointer, slice, packed, optional, and error-union rows | 14 | Aggregate layout summaries, field/index access records, payload tag/data shape, GEP index records, load/store value types and alignments, and checked aggregate panic-edge terminators |
| Literal and constant-result rows | 4 | Global/string initializer shape, scalar literal kind/value records, comptime constant expression summaries, and returned aggregate/slice layout |
| Inline asm, volatile, start, address-space, and unreachable boundaries | 10 | Inline-asm boundary records, address-space/inttoptr records, volatile memory operation records, noreturn/unreachable terminators, and raw `_start` loop terminator summaries |
| Hidden globals, mixed C/Zig, i64 helper, getauxval, f128 ABI, and vtable rows | 13 | Linkage/visibility records, C/Zig ABI/callconv summaries, TLS input records, i64 saturating helper signatures, pointer-walk terminators, f128 sret/byval ABI shape, and indirect call target summaries |

## Descriptor Body Inventory

| Descriptor body | Rows | Current provenance |
| --- | ---: | --- |
| `scalar-add-ret` | 1 | compile context |
| `integer-arithmetic` | 2 | compile context |
| `error-switch-select` | 2 | compile context |
| `table-indexed-load` | 1 | compile context |
| `checked-add-runtime-boundary` | 1 | compile context |
| `runtime-condbr` | 1 | compile context |
| `runtime-phi-merge` | 1 | compile context |
| `runtime-loop-sum` | 1 | compile context |
| `runtime-switch` | 1 | compile context |
| `checked-branch-mix-boundary` | 1 | compile context |
| `global-update` | 1 | compile context |
| `pointer-load-store` | 1 | compile context |
| `optional-pointer` | 1 | compile context |
| `packed-read-flag` | 1 | compile context |
| `packed-replace-low` | 1 | compile context |
| `struct-field-sum` | 1 | compile context |
| `array-scalar-sum` | 1 | compile context |
| `optional-scalar-payload` | 1 | compile context |
| `error-union-payload` | 1 | compile context |
| `slice-loop-sum` | 1 | compile context |
| `fp-literal-return` | 1 | compile context |
| `comptime-const-mul` | 1 | compile context |
| `add-imm-return` | 1 | compile context |
| `checked-add-imm-boundary` | 1 | compile context |
| `checked-global-update-boundary` | 1 | compile context |
| `checked-pointer-load-store-boundary` | 1 | compile context |
| `checked-call-chain-boundary` | 1 | compile context |
| `checked-array-sum-boundary` | 1 | compile context |
| `checked-struct-sum-boundary` | 1 | compile context |
| `checked-slice-loop-sum-boundary` | 1 | compile context |
| `abi-arg-call` | 1 | compile context |
| `tls-read` | 2 | compile context |
| `tls-bump` | 1 | compile context |
| `checked-tls-bump-boundary` | 1 | compile context |
| `atomic-add` | 1 | compile context |
| `inline-asm-barrier` | 1 | compile context |
| `aggregate-pair-abi` | 1 | compile context |
| `float-less` | 1 | compile context |
| `float-mul` | 1 | compile context |
| `float-add` | 1 | compile context |
| `float-select` | 1 | compile context |
| `float-sub` | 1 | compile context |
| `double-div` | 1 | compile context |
| `float-rem` | 1 | compile context |
| `void-noop-call` | 1 | compile context |
| `volatile-roundtrip` | 1 | compile context |
| `i64-arithmetic` | 1 | compile context |
| `hidden-global-access` | 2 | compile context |
| `mixed-c-zig-add` | 2 | compile context |
| `mixed-c-zig-panic-add` | 2 | compile context |
| `umul-fix-sat-i64` | 2 | compile context |
| `inherit-i64-return` | 2 | compile context |
| `compile-asm-unreachable` | 2 | compile context |
| `start-trampoline` | 1 | compile context |
| `getauxval-pointer-walk` | 1 | compile context |
| `f128-sret-byval` | 1 | compile context |
| `noreturn-unreachable-stub` | 2 | compile context |
| `address-space-volatile-store` | 1 | compile context |
| `raw-start-loop` | 1 | compile context |
| `i1-const-return` | 1 | compile context |
| `constant-string-slice-return` | 1 | compile context |
| `libfuzzer-vtable-run` | 1 | compile context |
| `str-from-float-help` | 1 | compile context |
| `base64-decode-base64-full` | 1 | compile context |
| `base64-decode-step` | 1 | compile context |
| `base64-store-step` | 1 | compile context |
| `base64-residual-byte-step` | 1 | compile context |
| `base64-padding-tail-step` | 1 | compile context |
| `base64-padding-loop-step` | 1 | compile context |
| `base64-padding-length-step` | 1 | compile context |
| `base64-chunk-guard-step` | 1 | compile context |
| `base64-source-stride-step` | 1 | compile context |
| `base64-source-bundle-step` | 1 | compile context |
| `base64-next-source-bundle-step` | 1 | compile context |
| `base64-third-source-bundle-step` | 1 | compile context |
| `base64-bit-buffer-store-step` | 1 | compile context |
| `base64-loop-advance-step` | 1 | compile context |
| `base64-residual-guard-step` | 1 | compile context |
| `base64-residual-bundle-step` | 1 | compile context |
| `base64-residual-store-step` | 1 | compile context |
| `base64-residual-length-step` | 1 | compile context |
| `base64-residual-table-check-step` | 1 | compile context |
| `base64-residual-accumulator-step` | 1 | compile context |
| `base64-residual-loop-advance-step` | 1 | compile context |
| `base64-residual-padding-check-step` | 1 | compile context |
| `base64-residual-final-mask-step` | 1 | compile context |
| `base64-residual-padding-loop-step` | 1 | compile context |
| `base64-decode-exit-step` | 1 | compile context |

## Extracted-Record Rows

The extracted-record milestone now covers these families and no longer routes
them through the broad body-template dispatcher:

- `scalar-add-ret`
- `integer-arithmetic`
- `runtime-loop-sum`
- `runtime-phi-merge`
- `abi-arg-call`
- `error-switch-select`
- `runtime-condbr`
- `runtime-switch`
- `pointer-load-store`
- `optional-pointer`
- `comptime-const-mul`
- `global-update`
- `add-imm-return`
- `tls-read`
- `tls-bump`
- `checked-add-imm-boundary`
- `checked-add-runtime-boundary`
- `checked-global-update-boundary`
- `checked-pointer-load-store-boundary`
- `checked-branch-mix-boundary`
- `checked-call-chain-boundary`
- `checked-tls-bump-boundary`
- `packed-read-flag`
- `packed-replace-low`
- `struct-field-sum`
- `array-scalar-sum`
- `optional-scalar-payload`
- `error-union-payload`
- `slice-loop-sum`
- `fp-literal-return`
- `atomic-add`
- `inline-asm-barrier`
- `aggregate-pair-abi`
- `float-less`
- `float-mul`
- `float-add`
- `float-select`
- `float-sub`
- `double-div`
- `float-rem`
- `void-noop-call`
- `volatile-roundtrip`
- `i64-arithmetic`
- `hidden-global-access`
- `mixed-c-zig-add`
- `mixed-c-zig-panic-add`
- `umul-fix-sat-i64`
- `inherit-i64-return`
- `compile-asm-unreachable`
- `start-trampoline`
- `getauxval-pointer-walk`
- `f128-sret-byval`
- `noreturn-unreachable-stub`
- `address-space-volatile-store`
- `raw-start-loop`
- `i1-const-return`
- `constant-string-slice-return`
- `libfuzzer-vtable-run`
- `table-indexed-load`
- `base64-decode-base64-full`
- `base64-decode-step`
- `base64-store-step`
- `base64-residual-byte-step`
- `base64-padding-tail-step`
- `base64-padding-loop-step`
- `base64-padding-length-step`
- `base64-chunk-guard-step`
- `base64-source-stride-step`
- `base64-source-bundle-step`
- `base64-next-source-bundle-step`
- `base64-third-source-bundle-step`
- `base64-bit-buffer-store-step`
- `base64-loop-advance-step`
- `base64-residual-guard-step`
- `base64-residual-bundle-step`
- `base64-residual-store-step`
- `base64-residual-length-step`
- `base64-residual-table-check-step`
- `base64-residual-accumulator-step`
- `base64-residual-loop-advance-step`
- `base64-residual-padding-check-step`
- `base64-residual-final-mask-step`
- `base64-residual-padding-loop-step`
- `base64-decode-exit-step`
- `str-from-float-help`

## Closed Counter Target

```text
air_extracted_descriptor_rows=100
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
zig_compile_context_descriptor_rows=100
env_source_tag_selector_rows=0
wrapper_body_selector_rows=0
source_tag_body_selector_rows=0
fixture_metadata_selector_rows=0
source_tag_env_present_rows=0
```
