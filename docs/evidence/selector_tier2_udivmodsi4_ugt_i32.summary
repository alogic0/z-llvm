# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `37118b93`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `i32 unsigned-greater comparison against an immediate`
result: `pass`

```text
zig build test: status=0 tests=808/808
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
i32 ugt executable results: ugt(31,31)=false ugt(32,31)=true status=0
__udivmodsi4 frontier: composed-block-icmp-rhs
```

Tier 3 was not required because the integer helper advanced without closing,
no strict ratchet moved, and no ABI boundary changed.
