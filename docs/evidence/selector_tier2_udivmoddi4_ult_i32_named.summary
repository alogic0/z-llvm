# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `5b74ec31`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed named i32 unsigned less-than`
result: `pass`

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
setcc executable semantics: ult_u32(3,7)=1 ult_u32(7,3)=0 ult_u32(7,0x80000000)=1 ult_u32(0x80000000,7)=0
__udivmoddi4 frontier: composed-block-binary-op
```

Logs: `tmp/selector_tier2_udivmoddi4_ult_i32_named_object.log`,
`tmp/selector_tier2_udivmoddi4_ult_i32_named_exe.log`, and
`tmp/std_debug_hello_udivmoddi4_ult_i32_named.log`.

Tier 3 was not repeated for this isolated scalar-selector form. The immediately
preceding INBOX-15 closure at commit `5b74ec31` passed all 17 Tier 3 subgates.
