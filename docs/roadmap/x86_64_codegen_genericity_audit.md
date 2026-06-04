# x86_64 Selected Codegen Genericity Audit

The selected external IR-writer gate now separates structured IR construction
ownership from x86_64 lowering ownership.

Current measured gate:

```text
gate=zig build distribution-zig-ir-writer
total=136
structured_direct_rows=104
generic_codegen_rows=93
case_specific_codegen_rows=11
textual_boundary_rows=32
```

The 32 textual boundary rows are out of scope for this codegen genericity
counter. They remain explicit boundary rows with `textual_boundary_reason`.

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

The repeated selected FP call/fcmp/select mains now dispatch through one
table-driven `lowerSelectedRuntimeFloatCallCompareMainReturn` path rather than
six named wrapper lowerers.

## Remaining Case-Specific Structured Rows

The current 11 structured-direct rows still intentionally count as
`case_specific_codegen_rows`:

- `aggregate-pair-abi=2`: selected aggregate ABI pair packing and accessors
- `void-noop-call=1`: selected fastcc void call boundary
- `hidden-global-access=2`: ReleaseSmall hidden extern/global access shape
- `mixed-c-zig-add=2`: ReleaseSmall mixed C/Zig localexec TLS input shape
- `umul-fix-sat-i64=2`: selected i64 saturating multiply helper boundary
- `inherit-i64-return=2`: selected inherit-want-safety i64 return shape

These rows are still valid selected evidence, but they are no longer hidden in
the structured-direct count. The compact selected gate requires
`generic_codegen_rows >= 75` for the 104 structured-direct rows.
