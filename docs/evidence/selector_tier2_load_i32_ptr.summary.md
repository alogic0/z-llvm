# Tier 2 Selector Validation

schema_version: 1
z_llvm_commit: `5aa4535e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed i32 load through argument or scratch pointer`
result: `pass`

## Gates

```text
zig build test
status=0 tests=730/730

zig build structural-smoke
status=0

zig build distribution-object > tmp/distribution_object_after_load_i32_ptr.log 2>&1
status=0 releasefast_captured_object_rows=38

zig build distribution-releasesafe-object > tmp/distribution_releasesafe_object_after_load_i32_ptr.log 2>&1
status=0 releasesafe_object_rows=9

zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_load_i32_ptr.log 2>&1
status=0 executable_canary_rows=5

zig build distribution-boundary > tmp/distribution_boundary_after_load_i32_ptr.log 2>&1
status=0
```

Focused frontier evidence:
`docs/evidence/std_debug_hello_udivei5_load_i32_ptr.summary.md`.

Executable semantic evidence:
`docs/evidence/zig_integrated_exe_i128_arithmetic_load_i32_ptr.summary.md`.

Tier 3 `distribution-all` was not required for this focused selector
capability under `docs/validation_tiers.md`.
