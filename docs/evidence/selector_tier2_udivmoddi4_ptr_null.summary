# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `cfd884c4`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `pointer equality with null`
result: `pass`

```text
zig build test: status=0 tests=819/819
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
pointer null executable: null=1 nonnull=0 status=0
__udivmoddi4 frontier: composed-block-store-width
```

Tier 3 was not required because no helper row or strict ratchet closed and no
ABI, allocator, or frame behavior changed.
