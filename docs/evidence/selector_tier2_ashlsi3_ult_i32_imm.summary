# Selector Tier 2 Evidence

schema_version: 1
z_llvm_base_commit: `ec18226d`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
__ashlsi3 frontier: composed-block-binary-op
```

Executable checks cover values below, equal to, and above the immediate,
including the unsigned high-bit boundary. Logs:
`tmp/selector_tier2_ashlsi3_ult_i32_imm_object.log` and
`tmp/selector_tier2_ashlsi3_ult_i32_imm_exe.log`.
