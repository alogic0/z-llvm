# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `8e3d6774`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `narrow scalar select lowering through the EAX value path`
result: `pass`

```text
zig build test: status=0 tests=806/806
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
boolean select executable outcomes: true=1 false=0 status=0
__udivmodsi4 frontier: composed-block-ctlz-args
```

Tier 3 was not required because the integer helper advanced without closing,
no strict ratchet moved, and no ABI boundary changed.
