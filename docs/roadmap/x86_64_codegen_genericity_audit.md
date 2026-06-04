# x86_64 Selected Codegen Genericity Audit

The selected external IR-writer gate now separates structured IR construction
ownership from x86_64 lowering ownership.

Current measured gate:

```text
gate=zig build distribution-zig-ir-writer
total=146
structured_direct_rows=146
generic_codegen_rows=146
case_specific_codegen_rows=0
textual_boundary_rows=0
```

No selected textual boundary rows remain; every selected row is now in scope
for the codegen genericity counter.

## Generic Structured-Direct Rows

Rows counted as `generic_codegen_rows` are structured-direct rows whose backend
path is covered by reusable x86_64 lowering families:

- integer binary and return-value lowering
- icmp/fcmp/select main checks
- branch/phi/loop shapes
- GEP/load/store and table-indexed loads
- direct calls and call-chain return handling
- TLS/global access
- basic FP binary/compare/select/div/rem checks
- ReleaseSafe checked overflow and panic-edge layouts
- aggregate pair ABI packing/accessor helpers
- simple void-call boundaries
- ReleaseSmall hidden/global access
- mixed C/Zig localexec TLS input
- i64 saturating helper shapes
- i64 return/pass-through shapes

The repeated selected FP call/fcmp/select mains now dispatch through one
table-driven `lowerSelectedRuntimeFloatCallCompareMainReturn` path rather than
six named wrapper lowerers.

The former case-specific families now dispatch through reusable family entry
points:

- `lowerAggregatePairAbiFamilyReturn`
- `lowerSimpleVoidCallBoundaryFamilyReturn`
- `lowerHiddenGlobalAccessFamilyReturn`
- `lowerMixedCZigTlsInputFamilyReturn`
- `lowerI64SaturatingHelperFamilyReturn`
- `lowerI64SaturatingHelperFunctionFamily`
- `lowerI64PassThroughFunctionFamily`

## Remaining Case-Specific Structured Rows

There are no remaining case-specific structured-direct rows. The compact
selected gate requires `generic_codegen_rows == structured_direct_rows` and
`case_specific_codegen_rows == 0`; at the current 146-row size this is
`generic_codegen_rows=146` and `case_specific_codegen_rows=0`.
