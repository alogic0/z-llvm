# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `1c3e6cc8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `pressure-exempt llvm.usub.with.overflow.i32 aggregate tuples`
result: `pass`

```text
zig build test: status=0 tests=817/817
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
__udivmoddi4 frontier: stage2-phi-restore-loc
```

Tier 3 was not required because no helper row or strict ratchet closed and no
ABI or frame behavior changed.
