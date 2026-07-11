# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `0ea55b50`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `direct local stack-array load`
result: `pass`

```text
zig build test: status=0 tests=763/763
zig build structural-smoke: status=0 tests=6/6
ReleaseFast captured object rows: status=0 rows=38
ReleaseSafe captured object rows: status=0 rows=9
permanent executable canaries: status=0 rows=5
distribution boundary gates: status=0
focused __umodei4 retry: advanced to no_spill_envelope/composed-block-two-address-rhs-accumulator
```

Tier 3 is not required because the boundary row advanced but did not close.
