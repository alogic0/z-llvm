# Selector Tier 2 Evidence

schema_version: 1
z_llvm_base_commit: `76475388`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
__ashlsi3 frontier: unsupported_value / stage2-phi-src-unknown
```

The executable case truncates i32 ABI inputs to i16, shifts left and right by
four, and verifies the cross-bit roundtrip. Logs:
`tmp/selector_tier2_ashlsi3_variable_i16_shifts_object.log` and
`tmp/selector_tier2_ashlsi3_variable_i16_shifts_exe.log`.
