# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `2f4ed6f0`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed unsigned-greater comparison between named i64 values`
result: `pass`

```text
zig test src/tests.zig --test-filter 'unsigned greater i64 values'
status=0 tests=10/10
zig build test
status=0 tests=734/734
zig build structural-smoke
status=0
zig build distribution-object > tmp/distribution_object_after_icmp_ugt_values.log 2>&1
status=0 releasefast_captured_object_rows=38
zig build distribution-releasesafe-object > tmp/distribution_releasesafe_object_after_icmp_ugt_values.log 2>&1
status=0 releasesafe_object_rows=9
zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_icmp_ugt_values.log 2>&1
status=0 executable_canary_rows=5
zig build distribution-boundary > tmp/distribution_boundary_after_icmp_ugt_values.log 2>&1
status=0
```

Tier 3 was not required for this focused selector form under
`docs/validation_tiers.md`.
