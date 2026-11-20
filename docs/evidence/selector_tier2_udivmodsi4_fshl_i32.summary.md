# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `791f368a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `i32 funnel shift machine operation and intrinsic lowering`
result: `pass`

```text
zig build test: status=0 tests=811/811
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
funnel shift executable result: fshl(0x40000000,0x80000000,1)=0x80000001 status=0
__udivmodsi4 frontier: stage2-phi-src-spill64
```

Tier 3 was not required because the integer helper advanced without closing,
no strict ratchet moved, and no ABI boundary changed.
