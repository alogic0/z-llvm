# x86_64 Source-Owned Descriptor Template Inventory

Current gate: `zig build distribution-x86_64-release-source-owned`

Measured state after the first extracted-record slice:

```text
release_source_rows=90
air_extracted_descriptor_rows=24
template_descriptor_rows=66
wrapper_body_map_rows=32
source_tag_body_map_rows=58
```

All rows still serialize DescriptorV2 records. The first 24 rows now use a
separate extracted-record writer path for simple compiler-owned facts, while
the remaining 66 rows are still emitted from
`zllvmWriteAirDescriptorRecords(...)` body templates selected by
`zllvmSourceOwnedDescriptorBody(...)` or
`zllvmSourceOwnedTaggedDescriptorBody(...)`. This is distinct from full Zig
Sema/AIR extraction, which remains the target.

## Descriptor Body Inventory

| Descriptor body | Rows | Current selector |
| --- | ---: | --- |
| `scalar-add-ret` | 1 | source tag |
| `integer-arithmetic` | 2 | source tag |
| `error-switch-select` | 2 | source tag |
| `table-indexed-load` | 1 | source tag |
| `checked-add-runtime-boundary` | 1 | source tag |
| `runtime-condbr` | 1 | source tag |
| `runtime-loop-sum` | 1 | source tag |
| `runtime-switch` | 1 | source tag |
| `checked-branch-mix-boundary` | 1 | source tag |
| `global-update` | 1 | source tag |
| `pointer-load-store` | 1 | source tag |
| `optional-pointer` | 1 | source tag |
| `packed-read-flag` | 1 | source tag |
| `packed-replace-low` | 1 | source tag |
| `struct-field-sum` | 1 | source tag |
| `array-scalar-sum` | 1 | source tag |
| `optional-scalar-payload` | 1 | source tag |
| `error-union-payload` | 1 | source tag |
| `slice-loop-sum` | 1 | source tag |
| `fp-literal-return` | 1 | source tag |
| `comptime-const-mul` | 1 | source tag |
| `add-imm-return` | 1 | source tag |
| `checked-add-imm-boundary` | 1 | source tag |
| `checked-global-update-boundary` | 1 | source tag |
| `checked-pointer-load-store-boundary` | 1 | source tag |
| `checked-call-chain-boundary` | 1 | source tag |
| `checked-array-sum-boundary` | 1 | source tag |
| `checked-struct-sum-boundary` | 1 | source tag |
| `checked-slice-loop-sum-boundary` | 1 | source tag |
| `abi-arg-call` | 1 | source tag |
| `tls-read` | 2 | source tag |
| `tls-bump` | 1 | source tag |
| `checked-tls-bump-boundary` | 1 | source tag |
| `atomic-add` | 1 | source tag |
| `inline-asm-barrier` | 1 | source tag |
| `aggregate-pair-abi` | 1 | source tag |
| `float-less` | 1 | source tag |
| `float-add` | 1 | source tag |
| `float-sub` | 1 | source tag |
| `hidden-global-access` | 2 | source tag and wrapper basename |
| `mixed-c-zig-add` | 2 | source tag and wrapper basename |
| `mixed-c-zig-panic-add` | 2 | source tag and wrapper basename |
| `umul-fix-sat-i64` | 2 | source tag and wrapper basename |
| `inherit-i64-return` | 2 | source tag and wrapper basename |
| `compile-asm-unreachable` | 2 | source tag and wrapper basename |
| `start-trampoline` | 1 | source tag |
| `getauxval-pointer-walk` | 1 | source tag |
| `f128-sret-byval` | 1 | source tag |
| `noreturn-unreachable-stub` | 2 | source tag |
| `address-space-volatile-store` | 1 | source tag |
| `raw-start-loop` | 1 | source tag |
| `i1-const-return` | 1 | source tag |
| `constant-string-slice-return` | 1 | source tag |
| `libfuzzer-vtable-run` | 1 | source tag |
| `str-from-float-help` | 1 | wrapper basename |
| `base64-decode-base64-full` | 1 | wrapper basename |
| `base64-decode-step` | 1 | wrapper basename |
| `base64-store-step` | 1 | wrapper basename |
| `base64-residual-byte-step` | 1 | wrapper basename |
| `base64-padding-tail-step` | 1 | wrapper basename |
| `base64-padding-loop-step` | 1 | wrapper basename |
| `base64-padding-length-step` | 1 | wrapper basename |
| `base64-chunk-guard-step` | 1 | wrapper basename |
| `base64-source-stride-step` | 1 | wrapper basename |
| `base64-source-bundle-step` | 1 | wrapper basename |
| `base64-next-source-bundle-step` | 1 | wrapper basename |
| `base64-third-source-bundle-step` | 1 | wrapper basename |
| `base64-bit-buffer-store-step` | 1 | wrapper basename |
| `base64-loop-advance-step` | 1 | wrapper basename |
| `base64-residual-guard-step` | 1 | wrapper basename |
| `base64-residual-bundle-step` | 1 | wrapper basename |
| `base64-residual-store-step` | 1 | wrapper basename |
| `base64-residual-length-step` | 1 | wrapper basename |
| `base64-residual-table-check-step` | 1 | wrapper basename |
| `base64-residual-accumulator-step` | 1 | wrapper basename |
| `base64-residual-loop-advance-step` | 1 | wrapper basename |
| `base64-residual-padding-check-step` | 1 | wrapper basename |
| `base64-residual-final-mask-step` | 1 | wrapper basename |
| `base64-residual-padding-loop-step` | 1 | wrapper basename |
| `base64-decode-exit-step` | 1 | wrapper basename |

## Extracted-Record Rows

The first extracted-record milestone covers these simple families and no
longer routes them through the broad body-template dispatcher:

- `scalar-add-ret`
- `integer-arithmetic`
- `runtime-loop-sum`
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

## Next Extraction Target

Next slices should keep moving repeated families to
`air_extracted_descriptor_rows` without broadening the 90-row inventory:

- packed bits
- optional and error-union payloads
- aggregate and slice rows
- FP compare/binary rows
- atomics and inline-asm boundary rows
- ReleaseSmall mixed C/Zig and i64 helper rows
- base64 full/reduced/table rows
- `strFromFloatHelp`

The end-state target remains:

```text
air_extracted_descriptor_rows=90
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
```
