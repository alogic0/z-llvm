# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `4d40c89a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `zero-defined llvm.ctlz.i32 intrinsic flag`
result: `pass`

```text
zig build test: status=0 tests=807/807
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
zero-defined ctlz executable results: ctlz(0)=32 ctlz(16)=27 status=0
__udivmodsi4 frontier: composed-block-icmp-form
```

Tier 3 was not required because the integer helper advanced without closing,
no strict ratchet moved, and no ABI boundary changed.
