# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `9879923a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `frame-backed i128 phi destinations and overlap-safe pair copies`
result: `pass`

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
executable semantics: i128 phi left and right predecessor values preserved
```

Logs: `tmp/selector_tier2_lshrti3_i128_phi_object.log` and
`tmp/selector_tier2_lshrti3_i128_phi_exe.log`.

Tier 3 was not repeated for this focused selector capability. The current
strict ratchet, ABI, frame layout, and allocation policy are unchanged.
