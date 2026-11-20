# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `debcd0e5`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `named i32 equality comparison`
result: `pass`

```text
zig build test: status=0 tests=809/809
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
named i32 equality executable results: equal=1 unequal=0 status=0
__udivmodsi4 frontier: composed-block-call-form
```

Tier 3 was not required because the integer helper advanced without closing,
no strict ratchet moved, and no ABI boundary changed.
