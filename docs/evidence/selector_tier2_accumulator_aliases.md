# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `7f810983`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `two-address RHS ordering and accumulator alias preservation`
result: `pass`

```text
focused RHS-order test: status=0 tests=10/10
focused live-alias test: status=0 tests=10/10
zig build test: status=0 tests=757/757
zig build structural-smoke: status=0
ReleaseFast captured object rows: status=0 rows=38
ReleaseSafe object rows: status=0 rows=9
permanent executable canaries: status=0 rows=5
boundary gates: status=0
```

Tier 3 was not required because `__udivei5` advanced to a later frontier but
did not close.
