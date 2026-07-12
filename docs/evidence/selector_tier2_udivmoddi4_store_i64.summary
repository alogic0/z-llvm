# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `d7dc3e33`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed i64 store through register or spilled pointer`
result: `pass`

```text
zig build test: status=0 tests=820/820
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
__udivmoddi4 frontier: composed-block-icmp-form
```

Tier 3 was not repeated for this non-closing selector form. The immediately
preceding INBOX-15 architecture cycle passed all 17 Tier 3 subgates at the
same selector structure before this isolated memory-lowering change.
