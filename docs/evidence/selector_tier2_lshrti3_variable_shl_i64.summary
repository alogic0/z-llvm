# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `79118987`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `variable i64 left shift`
result: `pass`

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
```

Logs: `tmp/selector_tier2_lshrti3_variable_shl_i64_object.log` and
`tmp/selector_tier2_lshrti3_variable_shl_i64_exe.log`.

Tier 3 was not repeated because no ABI, frame, allocator, ratchet, or
milestone boundary changed.
